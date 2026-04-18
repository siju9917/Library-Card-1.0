// ============================================================
// LIBRARY CARD — Cloud Data Layer (Supabase)
// ============================================================
// This file is loaded after config.js. If LC_CLOUD_ENABLED is false
// (config not filled in), this file does nothing and the app falls
// back to localStorage demo mode.
// ============================================================

(function () {
  if (!window.LC_CLOUD_ENABLED) {
    window.LC = window.LC || { cloud: false };
    return;
  }

  if (!window.supabase || !window.supabase.createClient) {
    console.error('Supabase SDK not loaded');
    window.LC = { cloud: false };
    return;
  }

  // Init Supabase client (loaded from CDN <script> tag in index.html)
  const sb = window.supabase.createClient(
    window.LC_CONFIG.SUPABASE_URL,
    window.LC_CONFIG.SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
        // Implicit flow puts tokens directly in the URL hash — simpler,
        // works cross-device, and doesn't require a code_verifier in
        // localStorage (which would break if the user clicks the magic
        // link on a different device than they requested it from).
        flowType: 'implicit',
      },
    }
  );

  const LC = {
    cloud: true,
    sb,
    me: null,           // current user row from public.users
    session: null,      // auth session
    realtimeChannels: [],
  };

  // Helper: get current user ID from session (always available) or profile
  LC.userId = function () {
    if (LC.me) return LC.me.id;
    if (LC.session) return LC.session.user.id;
    return null;
  };

  // ---------- TIMEOUT WRAPPER ----------
  // Every network call is deadline-capped. A Supabase query that hangs
  // (server overloaded, WebSocket stalled, flaky cell) used to block the
  // entire app silently; now it rejects at 15s and the caller can surface
  // a real error to the user.
  // Aggressive default timeout. Every user-facing cloud call should give up
  // and show an error in under 8s — previously 15s, which stacked into
  // 60s+ boot times when multiple calls failed sequentially.
  const DEFAULT_TIMEOUT_MS = 8000;
  LC.withTimeout = function (promiseOrBuilder, ms, label) {
    ms = ms || DEFAULT_TIMEOUT_MS;
    label = label || 'supabase call';
    return new Promise(function (resolve, reject) {
      let settled = false;
      const t = setTimeout(function () {
        if (settled) return;
        settled = true;
        const err = new Error(label + ' timed out after ' + ms + 'ms');
        err.code = 'LC_TIMEOUT';
        reject(err);
      }, ms);
      const p = (typeof promiseOrBuilder === 'function') ? promiseOrBuilder() : promiseOrBuilder;
      Promise.resolve(p).then(function (v) {
        if (settled) return;
        settled = true; clearTimeout(t); resolve(v);
      }, function (e) {
        if (settled) return;
        settled = true; clearTimeout(t); reject(e);
      });
    });
  };

  // Client-generated idempotency key. Every write attaches one; the DB has
  // a unique index so a retry that accidentally succeeded twice never
  // creates a duplicate row.
  LC.newOpId = function () {
    if (window.crypto && window.crypto.randomUUID) return window.crypto.randomUUID();
    // RFC4122-ish fallback for ancient browsers
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  };

  // ---------- AUTH ----------
  LC.signInWithEmail = async function (email) {
    const { error } = await sb.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: window.location.origin + window.location.pathname }
    });
    if (error) throw error;
    return true;
  };

  LC.signOut = async function () {
    LC.me = null;
    LC.session = null;
    await sb.auth.signOut();
  };

  LC.getSession = async function () {
    // Wrapped in a 10s timeout because sb.auth.getSession() has been
    // observed to hang indefinitely when refresh-token state is weird.
    // A hanging auth call used to block weekend-plans loading forever.
    try {
      const { data } = await LC.withTimeout(sb.auth.getSession(), 10000, 'auth.getSession');
      LC.session = data.session;
      return data.session;
    } catch (e) {
      console.error('[lc] getSession timed out / failed', e);
      return LC.session;// fall back to whatever we have cached
    }
  };

  LC.loadMe = async function () {
    // Get session if we don't have one cached
    if (!LC.session) {
      const { data } = await LC.withTimeout(sb.auth.getSession(), 10000, 'auth.getSession');
      LC.session = data.session;
    }
    if (!LC.session) { console.warn('[lc] loadMe: no session'); return null; }
    // Use maybeSingle(): .single() throws on 0 rows which would cascade
    // through afterSignedIn and hide the rest of the app. 0 rows is a
    // real state (user trigger failed) that should fall through to the
    // upsert recovery path in afterSignedIn.
    const { data, error } = await LC.withTimeout(
      sb.from('users').select('*').eq('id', LC.session.user.id).maybeSingle(),
      DEFAULT_TIMEOUT_MS,
      'loadMe'
    );
    if (error) { console.error('[lc] loadMe error', error); return null; }
    LC.me = data || null;
    return LC.me;
  };

  LC.updateProfile = async function (patch) {
    if (!LC.me) throw new Error('updateProfile: not loaded');
    if (!patch || typeof patch !== 'object') throw new Error('updateProfile: patch required');
    const { data, error } = await LC.withTimeout(
      sb.from('users').update(patch).eq('id', LC.userId()).select().single(),
      DEFAULT_TIMEOUT_MS, 'updateProfile'
    );
    if (error) throw error;
    LC.me = data;
    return data;
  };

  // ---------- VENUES ----------
  LC.listVenues = async function () {
    const { data, error } = await LC.withTimeout(
      sb.from('venues').select('*').order('name'),
      DEFAULT_TIMEOUT_MS, 'listVenues'
    );
    if (error) { console.error('[lc] listVenues', error); return []; }
    return data || [];
  };

  LC.createVenue = async function (name, address) {
    if (!name || typeof name !== 'string') throw new Error('createVenue: name required');
    const { data, error } = await LC.withTimeout(
      sb.from('venues').insert({ name, address }).select().single(),
      DEFAULT_TIMEOUT_MS, 'createVenue'
    );
    if (error) throw error;
    return data;
  };

  // ---------- SESSIONS ----------
  LC.startSession = async function (venueName, venueId, clientOpId) {
    if (!LC.userId()) throw new Error('startSession: not signed in');
    const payload = {
      user_id: LC.userId(),
      venue_id: venueId || null,
      venue_name: venueName || null,
    };
    // client_op_id is optional (column may not exist yet on older schemas).
    // If the column is missing, the INSERT will error and we retry without it.
    if (clientOpId) payload.client_op_id = clientOpId;
    const run = async function (obj) {
      return await sb.from('sessions').insert(obj).select().single();
    };
    let res = await LC.withTimeout(run(payload), DEFAULT_TIMEOUT_MS, 'startSession');
    if (res.error && /client_op_id/.test(String(res.error.message || ''))) {
      // Schema doesn't have the column yet — retry without it. Idempotency
      // fallback is the client-side _running guard.
      console.warn('[lc] client_op_id column missing — retrying without');
      delete payload.client_op_id;
      res = await LC.withTimeout(run(payload), DEFAULT_TIMEOUT_MS, 'startSession');
    }
    if (res.error) throw res.error;
    return res.data;
  };

  LC.endSession = async function (sessionId, totals) {
    if (!sessionId) throw new Error('endSession: sessionId required');
    const { data, error } = await LC.withTimeout(
      sb.from('sessions').update({
        end_time: new Date().toISOString(),
        total_drinks: totals.totalDrinks,
        total_cheers: totals.totalCheers,
      }).eq('id', sessionId).select().single(),
      DEFAULT_TIMEOUT_MS,
      'endSession'
    );
    if (error) throw error;
    return data;
  };

  LC.getMyActiveSession = async function () {
    if (!LC.userId()) return null;
    const { data, error } = await LC.withTimeout(
      sb.from('sessions').select('*').eq('user_id', LC.userId())
        .is('end_time', null).order('start_time', { ascending: false }).limit(1),
      DEFAULT_TIMEOUT_MS, 'getMyActiveSession'
    );
    if (error) { console.error('[lc] getMyActiveSession', error); return null; }
    return (data && data[0]) || null;
  };

  LC.listMySessions = async function (limit = 50) {
    if (!LC.userId()) return [];
    const { data, error } = await LC.withTimeout(
      sb.from('sessions').select('*').eq('user_id', LC.userId())
        .not('end_time', 'is', null).order('start_time', { ascending: false }).limit(limit),
      DEFAULT_TIMEOUT_MS, 'listMySessions'
    );
    if (error) { console.error('[lc] listMySessions', error); return []; }
    return data || [];
  };

  LC.listFriendsActiveSessions = async function () {
    // Friends from your circles (bidirectional — see listMyFriends)
    const friends = await LC.listMyFriends();
    if (friends.length === 0) return [];
    const ids = friends.map(f => f.friend_id);
    // We join drinks(id, has_photo, photo_url) so we can count live drinks
    // AND cheers photos. sessions.total_drinks / total_cheers are only
    // populated at end-of-session, so during a live session those columns
    // are 0 — which is why every live friend showed "0 drinks" on everyone's
    // phone. The join + client-side count fixes it without a schema change.
    const { data, error } = await LC.withTimeout(
      sb.from('sessions')
        .select('*, users!sessions_user_id_fkey(display_name, emoji), drinks(id, has_photo, photo_url)')
        .in('user_id', ids)
        .is('end_time', null),
      DEFAULT_TIMEOUT_MS,
      'listFriendsActiveSessions'
    );
    if (error) { console.error('[lc] listFriendsActiveSessions error', error); throw error; }
    // Attach unified counts so callers don't have to understand the join.
    (data || []).forEach(function (row) {
      var rd = row.drinks || [];
      row.live_drink_count = rd.length;
      row.live_cheers_count = rd.filter(function (d) { return d.has_photo || d.photo_url; }).length;
    });
    return data || [];
  };

  LC.listFeedSessions = async function (limit = 30) {
    if (!LC.userId()) return [];
    let friends = [];
    try { friends = await LC.listMyFriends(); } catch (e) { console.error('[lc] listFeedSessions friends', e); }
    const ids = [LC.userId(), ...friends.map(f => f.friend_id)];
    const { data, error } = await LC.withTimeout(
      sb.from('sessions')
        .select('*, users!sessions_user_id_fkey(display_name, emoji), drinks(*), likes(user_id), comments(*)')
        .in('user_id', ids).not('end_time', 'is', null).order('start_time', { ascending: false }).limit(limit),
      DEFAULT_TIMEOUT_MS, 'listFeedSessions'
    );
    if (error) { console.error('[lc] listFeedSessions', error); return []; }
    return data || [];
  };

  // ---------- DRINKS ----------
  LC.logDrink = async function (sessionId, payload) {
    if (!sessionId) throw new Error('logDrink: sessionId required');
    if (!payload || typeof payload.name !== 'string' || !payload.name.trim()) {
      throw new Error('logDrink: payload.name required');
    }
    if (!LC.userId()) throw new Error('logDrink: not signed in');
    const obj = {
      session_id: sessionId,
      user_id: LC.userId(),
      name: payload.name,
      drink_type: payload.type || 'Other',
      is_na: !!payload.isNA,
      rating: payload.rating || null,
      has_photo: !!payload.hasPhoto,
      photo_url: payload.photoUrl || null,
      caption: payload.caption || null,
    };
    if (payload.clientOpId) obj.client_op_id = payload.clientOpId;
    const run = async function (o) { return await sb.from('drinks').insert(o).select().single(); };
    let res = await LC.withTimeout(run(obj), DEFAULT_TIMEOUT_MS, 'logDrink');
    if (res.error && /client_op_id/.test(String(res.error.message || ''))) {
      console.warn('[lc] drinks.client_op_id column missing — retrying without');
      delete obj.client_op_id;
      res = await LC.withTimeout(run(obj), DEFAULT_TIMEOUT_MS, 'logDrink');
    }
    if (res.error) throw res.error;
    return res.data;
  };

  LC.listSessionDrinks = async function (sessionId) {
    if (!sessionId) return [];
    const { data, error } = await LC.withTimeout(
      sb.from('drinks').select('*').eq('session_id', sessionId).order('logged_at'),
      DEFAULT_TIMEOUT_MS, 'listSessionDrinks'
    );
    if (error) { console.error('[lc] listSessionDrinks', error); return []; }
    return data || [];
  };

  LC.rateDrink = async function (drinkId, rating) {
    if (!drinkId) throw new Error('rateDrink: drinkId required');
    if (typeof rating !== 'number' || rating < 1 || rating > 5) throw new Error('rateDrink: rating must be 1–5');
    const { error } = await LC.withTimeout(
      sb.from('drinks').update({ rating }).eq('id', drinkId),
      DEFAULT_TIMEOUT_MS, 'rateDrink'
    );
    if (error) throw error;
  };

  // ---------- PHOTOS ----------
  // Longer timeout because photo uploads can legitimately take a few seconds
  // on cellular. Still bounded so it can't hang forever.
  LC.uploadPhoto = async function (blob, ext = 'jpg') {
    if (!blob) throw new Error('uploadPhoto: blob required');
    if (!LC.userId()) throw new Error('uploadPhoto: not signed in');
    const path = `${LC.userId()}/${Date.now()}.${ext}`;
    const { error } = await LC.withTimeout(
      sb.storage.from('cheers-photos').upload(path, blob, {
        contentType: blob.type || 'image/jpeg',
        upsert: false,
      }),
      30000, 'uploadPhoto'
    );
    if (error) throw error;
    const { data } = sb.storage.from('cheers-photos').getPublicUrl(path);
    return data.publicUrl;
  };

  // ---------- FRIENDS / CIRCLES ----------
  // Bug 7: friendships are stored in two rows (one per direction). When a
  // peer accepted, both rows should exist — but any mismatch (accept flow
  // interrupted, old data, manual edits) would leave us blind to them.
  // We now accept EITHER direction as a valid accepted friendship and
  // normalize the "other party" into the `friend` field. Deduped by peer id.
  LC.listMyFriends = async function () {
    const uid = LC.userId();
    if (!uid) return [];
    const [fwdRes, revRes] = await Promise.all([
      LC.withTimeout(
        sb.from('friendships')
          .select('*, friend:users!friendships_friend_id_fkey(id, display_name, emoji, email)')
          .eq('user_id', uid).eq('status', 'accepted'),
        DEFAULT_TIMEOUT_MS, 'listMyFriends fwd'
      ).catch(e => ({ error: e, data: [] })),
      LC.withTimeout(
        sb.from('friendships')
          .select('*, friend:users!friendships_user_id_fkey(id, display_name, emoji, email)')
          .eq('friend_id', uid).eq('status', 'accepted'),
        DEFAULT_TIMEOUT_MS, 'listMyFriends rev'
      ).catch(e => ({ error: e, data: [] })),
    ]);
    if (fwdRes.error) console.error('[lc] listMyFriends forward', fwdRes.error);
    if (revRes.error) console.error('[lc] listMyFriends reverse', revRes.error);
    const byPeer = {};
    (fwdRes.data || []).forEach(row => {
      byPeer[row.friend_id] = row;
    });
    // Only add reverse-direction rows where we don't already have a forward row.
    // Normalize the reverse row so downstream code sees the same shape.
    (revRes.data || []).forEach(row => {
      const peerId = row.user_id;
      if (byPeer[peerId]) return;
      byPeer[peerId] = {
        user_id: uid,
        friend_id: peerId,
        tier: row.tier,
        status: row.status,
        friend: row.friend,
      };
    });
    return Object.values(byPeer);
  };

  LC.findUserByEmail = async function (email) {
    if (!email || typeof email !== 'string') return null;
    const { data, error } = await LC.withTimeout(
      sb.from('users').select('*').eq('email', email.toLowerCase().trim()).limit(1),
      DEFAULT_TIMEOUT_MS, 'findUserByEmail'
    );
    if (error) { console.error('[lc] findUserByEmail', error); return null; }
    return (data && data[0]) || null;
  };

  LC.addFriend = async function (friendId, tier = 'friends') {
    if (!friendId) throw new Error('addFriend: friendId required');
    if (friendId === LC.userId()) throw new Error('addFriend: cannot add yourself');
    if (!['friends','besties','diehards'].includes(tier)) tier = 'friends';
    const { data, error } = await LC.withTimeout(
      sb.from('friendships').upsert({
        user_id: LC.userId(), friend_id: friendId, tier, status: 'pending'
      }, { onConflict: 'user_id,friend_id' }).select().single(),
      DEFAULT_TIMEOUT_MS, 'addFriend'
    );
    if (error) throw error;
    return data;
  };

  LC.acceptInvite = async function (inviterId) {
    if (!inviterId) throw new Error('acceptInvite: inviterId required');
    if (inviterId === LC.userId()) return; // can't invite self
    const { error } = await LC.withTimeout(
      sb.rpc('accept_invite', { inviter_id: inviterId }),
      DEFAULT_TIMEOUT_MS, 'acceptInvite'
    );
    if (error) throw error;
  };

  LC.listPendingRequests = async function () {
    if (!LC.userId()) return [];
    const { data, error } = await LC.withTimeout(
      sb.from('friendships')
        .select('*, requester:users!friendships_user_id_fkey(id, display_name, emoji, email)')
        .eq('friend_id', LC.userId()).eq('status', 'pending'),
      DEFAULT_TIMEOUT_MS, 'listPendingRequests'
    );
    if (error) { console.error('[lc] listPendingRequests', error); return []; }
    return data || [];
  };

  LC.acceptFriendRequest = async function (requesterId) {
    if (!requesterId) throw new Error('acceptFriendRequest: requesterId required');
    const { error } = await LC.withTimeout(
      sb.rpc('accept_friend_request', { requester_id: requesterId }),
      DEFAULT_TIMEOUT_MS, 'acceptFriendRequest'
    );
    if (error) throw error;
  };

  LC.declineFriendRequest = async function (requesterId) {
    if (!requesterId) throw new Error('declineFriendRequest: requesterId required');
    const { error } = await LC.withTimeout(
      sb.from('friendships').update({ status: 'declined' })
        .match({ user_id: requesterId, friend_id: LC.userId() }),
      DEFAULT_TIMEOUT_MS, 'declineFriendRequest'
    );
    if (error) throw error;
  };

  LC.moveFriendTier = async function (friendId, tier) {
    if (!friendId) throw new Error('moveFriendTier: friendId required');
    if (tier === null) {
      const { error } = await LC.withTimeout(
        sb.from('friendships').delete().match({ user_id: LC.userId(), friend_id: friendId }),
        DEFAULT_TIMEOUT_MS, 'moveFriendTier(delete)'
      );
      if (error) throw error;
      return;
    }
    if (!['friends','besties','diehards'].includes(tier)) throw new Error('moveFriendTier: invalid tier');
    const { error } = await LC.withTimeout(
      sb.from('friendships').update({ tier }).match({ user_id: LC.userId(), friend_id: friendId }),
      DEFAULT_TIMEOUT_MS, 'moveFriendTier'
    );
    if (error) throw error;
  };

  // ---------- LIKES (🔥) ----------
  LC.toggleLike = async function (sessionId) {
    if (!sessionId) throw new Error('toggleLike: sessionId required');
    if (!LC.userId()) throw new Error('toggleLike: not signed in');
    const { data: existing, error: selErr } = await LC.withTimeout(
      sb.from('likes').select('*').match({ session_id: sessionId, user_id: LC.userId() }),
      DEFAULT_TIMEOUT_MS, 'toggleLike.select'
    );
    if (selErr) throw selErr;
    if (existing && existing.length > 0) {
      const { error } = await LC.withTimeout(
        sb.from('likes').delete().match({ session_id: sessionId, user_id: LC.userId() }),
        DEFAULT_TIMEOUT_MS, 'toggleLike.delete'
      );
      if (error) throw error;
      return false;
    }
    const { error } = await LC.withTimeout(
      sb.from('likes').insert({ session_id: sessionId, user_id: LC.userId() }),
      DEFAULT_TIMEOUT_MS, 'toggleLike.insert'
    );
    if (error) throw error;
    return true;
  };

  LC.countLikes = async function (sessionId) {
    if (!sessionId) return 0;
    const { count, error } = await LC.withTimeout(
      sb.from('likes').select('*', { count: 'exact', head: true }).eq('session_id', sessionId),
      DEFAULT_TIMEOUT_MS, 'countLikes'
    );
    if (error) { console.error('[lc] countLikes', error); return 0; }
    return count || 0;
  };

  // ---------- COMMENTS ----------
  LC.addComment = async function (sessionId, text, emoji = '💬') {
    if (!sessionId) throw new Error('addComment: sessionId required');
    if (typeof text !== 'string' || !text.trim()) throw new Error('addComment: text required');
    if (text.length > 500) throw new Error('addComment: text too long (max 500)');
    if (!LC.userId()) throw new Error('addComment: not signed in');
    const { data, error } = await LC.withTimeout(
      sb.from('comments').insert({
        session_id: sessionId, user_id: LC.userId(), text: text.trim(), emoji
      }).select().single(),
      DEFAULT_TIMEOUT_MS, 'addComment'
    );
    if (error) throw error;
    return data;
  };

  LC.listComments = async function (sessionId) {
    if (!sessionId) return [];
    const { data, error } = await LC.withTimeout(
      sb.from('comments')
        .select('*, users!comments_user_id_fkey(display_name, emoji)')
        .eq('session_id', sessionId).order('created_at'),
      DEFAULT_TIMEOUT_MS, 'listComments'
    );
    if (error) { console.error('[lc] listComments', error); return []; }
    return data || [];
  };

  // ---------- DRINK GIFTS ----------
  LC.sendDrinkGift = async function (toUserId, drinkName, occasion) {
    if (!toUserId) throw new Error('sendDrinkGift: toUserId required');
    if (!drinkName) throw new Error('sendDrinkGift: drinkName required');
    if (toUserId === LC.userId()) throw new Error('sendDrinkGift: cannot gift yourself');
    const { data, error } = await LC.withTimeout(
      sb.from('drink_gifts').insert({
        from_user: LC.userId(), to_user: toUserId, drink_name: drinkName, occasion
      }).select().single(),
      DEFAULT_TIMEOUT_MS, 'sendDrinkGift'
    );
    if (error) throw error;
    return data;
  };

  LC.listMyGifts = async function () {
    if (!LC.userId()) return [];
    const { data, error } = await LC.withTimeout(
      sb.from('drink_gifts')
        .select('*, from_user:users!drink_gifts_from_user_fkey(display_name, emoji)')
        .eq('to_user', LC.userId()).eq('status', 'pending'),
      DEFAULT_TIMEOUT_MS, 'listMyGifts'
    );
    if (error) { console.error('[lc] listMyGifts', error); return []; }
    return data || [];
  };

  LC.respondToGift = async function (giftId, status) {
    if (!giftId) throw new Error('respondToGift: giftId required');
    if (!['accepted','declined','redeemed'].includes(status)) throw new Error('respondToGift: invalid status');
    const { error } = await LC.withTimeout(
      sb.from('drink_gifts').update({ status }).eq('id', giftId),
      DEFAULT_TIMEOUT_MS, 'respondToGift'
    );
    if (error) throw error;
  };

  // ---------- SOS ----------
  LC.sendSOS = async function (venueName, lat, lng) {
    if (!LC.userId()) throw new Error('sendSOS: not signed in');
    const { data, error } = await LC.withTimeout(
      sb.from('sos_alerts').insert({
        user_id: LC.userId(), venue_name: venueName || null, lat: lat || null, lng: lng || null
      }).select().single(),
      DEFAULT_TIMEOUT_MS, 'sendSOS'
    );
    if (error) throw error;
    return data;
  };

  // ---------- WEEKEND PLANS ----------
  // Build a YYYY-MM-DD string from local-date parts (NOT toISOString, which
  // silently shifts the day for users whose timezone offset straddles UTC
  // midnight — that caused plans to appear/disappear at the boundary).
  function _localDateStr(d) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return y + '-' + m + '-' + day;
  }

  LC.listWeekendPlans = async function () {
    await LC.getSession();
    const now = new Date();
    const dayOfWeek = now.getDay(); // 0=Sun
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const monday = new Date(now);
    monday.setDate(now.getDate() + mondayOffset);
    monday.setHours(0, 0, 0, 0);
    const weekStart = _localDateStr(monday);

    try {
      const { data, error } = await LC.withTimeout(
        sb.from('weekend_plans').select('*').gte('week_start', weekStart).order('created_at'),
        DEFAULT_TIMEOUT_MS,
        'listWeekendPlans'
      );
      if (error) { console.error('[lc] listWeekendPlans error:', error); throw error; }
      const plans = data || [];
      // Fetch votes for all plans in one query
      const planIds = plans.map(function(p){ return p.id; });
      if (planIds.length > 0) {
        const { data: allVotes, error: vErr } = await LC.withTimeout(
          sb.from('weekend_votes').select('plan_id,user_id').in('plan_id', planIds),
          DEFAULT_TIMEOUT_MS,
          'listWeekendVotes'
        );
        if (!vErr) {
          var votesByPlan = {};
          (allVotes || []).forEach(function(v){ if (!votesByPlan[v.plan_id]) votesByPlan[v.plan_id] = []; votesByPlan[v.plan_id].push(v); });
          plans.forEach(function(p){ p.weekend_votes = votesByPlan[p.id] || []; });
        } else {
          console.error('[lc] listWeekendVotes error', vErr);
        }
      }
      return plans;
    } catch (e) {
      console.error('[lc] listWeekendPlans exception:', e);
      throw e;
    }
  };

  LC.suggestPlan = async function (name, description, emoji, invitedIds) {
    if (typeof name !== 'string' || !name.trim()) throw new Error('suggestPlan: name required');
    if (name.length > 140) throw new Error('suggestPlan: name too long');
    if (description && description.length > 500) throw new Error('suggestPlan: description too long');
    await LC.getSession();
    const uid = LC.userId();
    if (!uid) throw new Error('suggestPlan: not signed in');
    const now = new Date();
    const dayOfWeek = now.getDay();
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const monday = new Date(now);
    monday.setDate(now.getDate() + mondayOffset);
    monday.setHours(0, 0, 0, 0);
    const insertObj = {
      name: name.trim(),
      description: (description || '').trim(),
      emoji: emoji || '📍',
      week_start: _localDateStr(monday),
      created_by: uid,
      invited_ids: Array.isArray(invitedIds) ? invitedIds : []
    };
    const { data, error } = await LC.withTimeout(
      sb.from('weekend_plans').insert(insertObj).select().single(),
      DEFAULT_TIMEOUT_MS, 'suggestPlan'
    );
    if (error) { console.error('[lc] suggestPlan error:', error); throw error; }
    return data;
  };

  LC.toggleVote = async function (planId) {
    if (!planId) throw new Error('toggleVote: planId required');
    await LC.getSession();
    const uid = LC.userId();
    if (!uid) throw new Error('toggleVote: not signed in');
    const { data: existing, error: selErr } = await LC.withTimeout(
      sb.from('weekend_votes').select('*').match({ plan_id: planId, user_id: uid }),
      DEFAULT_TIMEOUT_MS, 'toggleVote.select'
    );
    if (selErr) throw selErr;
    if (existing && existing.length > 0) {
      const { error: delErr } = await LC.withTimeout(
        sb.from('weekend_votes').delete().match({ plan_id: planId, user_id: uid }),
        DEFAULT_TIMEOUT_MS, 'toggleVote.delete'
      );
      if (delErr) throw delErr;
      return false;
    }
    const { error: insErr } = await LC.withTimeout(
      sb.from('weekend_votes').insert({ plan_id: planId, user_id: uid }),
      DEFAULT_TIMEOUT_MS, 'toggleVote.insert'
    );
    if (insErr) throw insErr;
    return true;
  };

  LC.deletePlan = async function (planId) {
    if (!planId) throw new Error('deletePlan: planId required');
    await LC.getSession();
    const { error } = await LC.withTimeout(
      sb.from('weekend_plans').delete().eq('id', planId),
      DEFAULT_TIMEOUT_MS, 'deletePlan'
    );
    if (error) throw error;
  };

  // ---------- REALTIME ----------
  LC.subscribeFriendActivity = function (onChange) {
    const channel = sb.channel('lc_friend_activity')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sessions' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drinks' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'likes' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'comments' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sos_alerts' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'drink_gifts' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'friendships' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'weekend_plans' }, onChange)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'weekend_votes' }, onChange)
      .subscribe();
    LC.realtimeChannels.push(channel);
    return channel;
  };

  LC.unsubscribeAll = function () {
    LC.realtimeChannels.forEach(c => sb.removeChannel(c));
    LC.realtimeChannels = [];
  };

  window.LC = LC;
})();
