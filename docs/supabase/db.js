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
  const DEFAULT_TIMEOUT_MS = 15000;
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
    const { data } = await sb.auth.getSession();
    LC.session = data.session;
    return data.session;
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
    if (!LC.me) return;
    const { data, error } = await sb.from('users').update(patch).eq('id', LC.userId()).select().single();
    if (error) throw error;
    LC.me = data;
    return data;
  };

  // ---------- VENUES ----------
  LC.listVenues = async function () {
    const { data } = await sb.from('venues').select('*').order('name');
    return data || [];
  };

  LC.createVenue = async function (name, address) {
    const { data, error } = await sb.from('venues').insert({ name, address }).select().single();
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
    const { data } = await sb.from('sessions')
      .select('*')
      .eq('user_id', LC.userId())
      .is('end_time', null)
      .order('start_time', { ascending: false })
      .limit(1);
    return (data && data[0]) || null;
  };

  LC.listMySessions = async function (limit = 50) {
    const { data } = await sb.from('sessions')
      .select('*')
      .eq('user_id', LC.userId())
      .not('end_time', 'is', null)
      .order('start_time', { ascending: false })
      .limit(limit);
    return data || [];
  };

  LC.listFriendsActiveSessions = async function () {
    // Friends from your circles (bidirectional — see listMyFriends)
    const friends = await LC.listMyFriends();
    if (friends.length === 0) return [];
    const ids = friends.map(f => f.friend_id);
    const { data, error } = await LC.withTimeout(
      sb.from('sessions')
        .select('*, users!sessions_user_id_fkey(display_name, emoji)')
        .in('user_id', ids)
        .is('end_time', null),
      DEFAULT_TIMEOUT_MS,
      'listFriendsActiveSessions'
    );
    if (error) { console.error('[lc] listFriendsActiveSessions error', error); throw error; }
    return data || [];
  };

  LC.listFeedSessions = async function (limit = 30) {
    // Recent completed sessions from friends + me
    const friends = await LC.listMyFriends();
    const ids = [LC.userId(), ...friends.map(f => f.friend_id)];
    const { data } = await sb.from('sessions')
      .select('*, users!sessions_user_id_fkey(display_name, emoji), drinks(*), likes(user_id), comments(*)')
      .in('user_id', ids)
      .not('end_time', 'is', null)
      .order('start_time', { ascending: false })
      .limit(limit);
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
    const { data } = await sb.from('drinks')
      .select('*')
      .eq('session_id', sessionId)
      .order('logged_at');
    return data || [];
  };

  LC.rateDrink = async function (drinkId, rating) {
    const { error } = await sb.from('drinks').update({ rating }).eq('id', drinkId);
    if (error) throw error;
  };

  // ---------- PHOTOS ----------
  LC.uploadPhoto = async function (blob, ext = 'jpg') {
    const path = `${LC.userId()}/${Date.now()}.${ext}`;
    const { error } = await sb.storage.from('cheers-photos').upload(path, blob, {
      contentType: blob.type || 'image/jpeg',
      upsert: false,
    });
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
      sb.from('friendships')
        .select('*, friend:users!friendships_friend_id_fkey(id, display_name, emoji, email)')
        .eq('user_id', uid)
        .eq('status', 'accepted'),
      sb.from('friendships')
        .select('*, friend:users!friendships_user_id_fkey(id, display_name, emoji, email)')
        .eq('friend_id', uid)
        .eq('status', 'accepted'),
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
    const { data } = await sb.from('users').select('*').eq('email', email.toLowerCase().trim()).limit(1);
    return (data && data[0]) || null;
  };

  LC.addFriend = async function (friendId, tier = 'friends') {
    const { data, error } = await sb.from('friendships').upsert({
      user_id: LC.userId(), friend_id: friendId, tier, status: 'pending'
    }, { onConflict: 'user_id,friend_id' }).select().single();
    if (error) throw error;
    return data;
  };

  LC.acceptInvite = async function (inviterId) {
    const { error } = await sb.rpc('accept_invite', { inviter_id: inviterId });
    if (error) throw error;
  };

  LC.listPendingRequests = async function () {
    const { data } = await sb.from('friendships')
      .select('*, requester:users!friendships_user_id_fkey(id, display_name, emoji, email)')
      .eq('friend_id', LC.userId())
      .eq('status', 'pending');
    return data || [];
  };

  LC.acceptFriendRequest = async function (requesterId) {
    const { error } = await sb.rpc('accept_friend_request', { requester_id: requesterId });
    if (error) throw error;
  };

  LC.declineFriendRequest = async function (requesterId) {
    const { error } = await sb.from('friendships').update({ status: 'declined' })
      .match({ user_id: requesterId, friend_id: LC.userId() });
    if (error) throw error;
  };

  LC.moveFriendTier = async function (friendId, tier) {
    if (tier === null) {
      const { error } = await sb.from('friendships').delete().match({ user_id: LC.userId(), friend_id: friendId });
      if (error) throw error;
      return;
    }
    const { error } = await sb.from('friendships').update({ tier }).match({ user_id: LC.userId(), friend_id: friendId });
    if (error) throw error;
  };

  // ---------- LIKES (🔥) ----------
  LC.toggleLike = async function (sessionId) {
    const { data: existing } = await sb.from('likes')
      .select('*').match({ session_id: sessionId, user_id: LC.userId() });
    if (existing && existing.length > 0) {
      await sb.from('likes').delete().match({ session_id: sessionId, user_id: LC.userId() });
      return false;
    } else {
      await sb.from('likes').insert({ session_id: sessionId, user_id: LC.userId() });
      return true;
    }
  };

  LC.countLikes = async function (sessionId) {
    const { count } = await sb.from('likes').select('*', { count: 'exact', head: true }).eq('session_id', sessionId);
    return count || 0;
  };

  // ---------- COMMENTS ----------
  LC.addComment = async function (sessionId, text, emoji = '💬') {
    const { data, error } = await sb.from('comments').insert({
      session_id: sessionId, user_id: LC.userId(), text, emoji
    }).select().single();
    if (error) throw error;
    return data;
  };

  LC.listComments = async function (sessionId) {
    const { data } = await sb.from('comments')
      .select('*, users!comments_user_id_fkey(display_name, emoji)')
      .eq('session_id', sessionId)
      .order('created_at');
    return data || [];
  };

  // ---------- DRINK GIFTS ----------
  LC.sendDrinkGift = async function (toUserId, drinkName, occasion) {
    const { data, error } = await sb.from('drink_gifts').insert({
      from_user: LC.userId(), to_user: toUserId, drink_name: drinkName, occasion
    }).select().single();
    if (error) throw error;
    return data;
  };

  LC.listMyGifts = async function () {
    const { data } = await sb.from('drink_gifts')
      .select('*, from_user:users!drink_gifts_from_user_fkey(display_name, emoji)')
      .eq('to_user', LC.userId())
      .eq('status', 'pending');
    return data || [];
  };

  LC.respondToGift = async function (giftId, status) {
    const { error } = await sb.from('drink_gifts').update({ status }).eq('id', giftId);
    if (error) throw error;
  };

  // ---------- SOS ----------
  LC.sendSOS = async function (venueName, lat, lng) {
    const { data, error } = await sb.from('sos_alerts').insert({
      user_id: LC.userId(), venue_name: venueName, lat, lng
    }).select().single();
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
    await LC.getSession();
    const now = new Date();
    const dayOfWeek = now.getDay();
    const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const monday = new Date(now);
    monday.setDate(now.getDate() + mondayOffset);
    monday.setHours(0, 0, 0, 0);

    const uid = LC.userId();
    if (!uid) throw new Error('Not signed in');
    const insertObj = {
      name: name,
      description: description || '',
      emoji: emoji || '📍',
      week_start: _localDateStr(monday),
      created_by: uid,
      invited_ids: invitedIds || []
    };
    const { data, error } = await sb.from('weekend_plans').insert(insertObj).select().single();
    if (error) {
      console.error('[lc] suggestPlan error:', error);
      throw error;
    }
    return data;
  };

  LC.toggleVote = async function (planId) {
    await LC.getSession();
    const uid = LC.userId();
    if (!uid) throw new Error('Not signed in');
    try {
      const { data: existing, error: selErr } = await sb.from('weekend_votes')
        .select('*').match({ plan_id: planId, user_id: uid });
      if (selErr) throw selErr;
      if (existing && existing.length > 0) {
        const { error: delErr } = await sb.from('weekend_votes').delete().match({ plan_id: planId, user_id: uid });
        if (delErr) throw delErr;
        return false;
      } else {
        const { error: insErr } = await sb.from('weekend_votes').insert({ plan_id: planId, user_id: uid });
        if (insErr) throw insErr;
        return true;
      }
    } catch (e) {
      console.warn('toggleVote error:', e);
      throw e;
    }
  };

  LC.deletePlan = async function (planId) {
    await LC.getSession();
    const { error } = await sb.from('weekend_plans').delete().eq('id', planId);
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
