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
    if (!LC.session) return null;
    const { data, error } = await sb.from('users').select('*').eq('id', LC.session.user.id).single();
    if (error) {
      console.warn('loadMe error', error);
      return null;
    }
    LC.me = data;
    return data;
  };

  LC.updateProfile = async function (patch) {
    if (!LC.me) return;
    const { data, error } = await sb.from('users').update(patch).eq('id', LC.me.id).select().single();
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
  LC.startSession = async function (venueName, venueId) {
    const { data, error } = await sb.from('sessions').insert({
      user_id: LC.me.id,
      venue_id: venueId || null,
      venue_name: venueName || null,
    }).select().single();
    if (error) throw error;
    return data;
  };

  LC.endSession = async function (sessionId, totals) {
    const { data, error } = await sb.from('sessions').update({
      end_time: new Date().toISOString(),
      total_drinks: totals.totalDrinks,
      total_cheers: totals.totalCheers,
    }).eq('id', sessionId).select().single();
    if (error) throw error;
    return data;
  };

  LC.getMyActiveSession = async function () {
    const { data } = await sb.from('sessions')
      .select('*')
      .eq('user_id', LC.me.id)
      .is('end_time', null)
      .order('start_time', { ascending: false })
      .limit(1);
    return (data && data[0]) || null;
  };

  LC.listMySessions = async function (limit = 50) {
    const { data } = await sb.from('sessions')
      .select('*')
      .eq('user_id', LC.me.id)
      .not('end_time', 'is', null)
      .order('start_time', { ascending: false })
      .limit(limit);
    return data || [];
  };

  LC.listFriendsActiveSessions = async function () {
    // Friends from your circles
    const friends = await LC.listMyFriends();
    if (friends.length === 0) return [];
    const ids = friends.map(f => f.friend_id);
    const { data } = await sb.from('sessions')
      .select('*, users!sessions_user_id_fkey(display_name, emoji)')
      .in('user_id', ids)
      .is('end_time', null);
    return data || [];
  };

  LC.listFeedSessions = async function (limit = 30) {
    // Recent completed sessions from friends + me
    const friends = await LC.listMyFriends();
    const ids = [LC.me.id, ...friends.map(f => f.friend_id)];
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
    const { data, error } = await sb.from('drinks').insert({
      session_id: sessionId,
      user_id: LC.me.id,
      name: payload.name,
      drink_type: payload.type,
      is_na: !!payload.isNA,
      rating: payload.rating || null,
      has_photo: !!payload.hasPhoto,
      photo_url: payload.photoUrl || null,
      caption: payload.caption || null,
    }).select().single();
    if (error) throw error;
    return data;
  };

  LC.listSessionDrinks = async function (sessionId) {
    const { data } = await sb.from('drinks')
      .select('*')
      .eq('session_id', sessionId)
      .order('logged_at');
    return data || [];
  };

  LC.rateDrink = async function (drinkId, rating) {
    await sb.from('drinks').update({ rating }).eq('id', drinkId);
  };

  // ---------- PHOTOS ----------
  LC.uploadPhoto = async function (blob, ext = 'jpg') {
    const path = `${LC.me.id}/${Date.now()}.${ext}`;
    const { error } = await sb.storage.from('cheers-photos').upload(path, blob, {
      contentType: blob.type || 'image/jpeg',
      upsert: false,
    });
    if (error) throw error;
    const { data } = sb.storage.from('cheers-photos').getPublicUrl(path);
    return data.publicUrl;
  };

  // ---------- FRIENDS / CIRCLES ----------
  LC.listMyFriends = async function () {
    const { data } = await sb.from('friendships')
      .select('*, friend:users!friendships_friend_id_fkey(id, display_name, emoji, email)')
      .eq('user_id', LC.me.id)
      .eq('status', 'accepted');
    return data || [];
  };

  LC.findUserByEmail = async function (email) {
    const { data } = await sb.from('users').select('*').eq('email', email.toLowerCase().trim()).limit(1);
    return (data && data[0]) || null;
  };

  LC.addFriend = async function (friendId, tier = 'friends') {
    const { data, error } = await sb.from('friendships').upsert({
      user_id: LC.me.id, friend_id: friendId, tier, status: 'pending'
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
      .eq('friend_id', LC.me.id)
      .eq('status', 'pending');
    return data || [];
  };

  LC.acceptFriendRequest = async function (requesterId) {
    const { error } = await sb.rpc('accept_friend_request', { requester_id: requesterId });
    if (error) throw error;
  };

  LC.declineFriendRequest = async function (requesterId) {
    await sb.from('friendships').update({ status: 'declined' })
      .match({ user_id: requesterId, friend_id: LC.me.id });
  };

  LC.moveFriendTier = async function (friendId, tier) {
    if (tier === null) {
      await sb.from('friendships').delete().match({ user_id: LC.me.id, friend_id: friendId });
      return;
    }
    await sb.from('friendships').update({ tier }).match({ user_id: LC.me.id, friend_id: friendId });
  };

  // ---------- LIKES (🔥) ----------
  LC.toggleLike = async function (sessionId) {
    const { data: existing } = await sb.from('likes')
      .select('*').match({ session_id: sessionId, user_id: LC.me.id });
    if (existing && existing.length > 0) {
      await sb.from('likes').delete().match({ session_id: sessionId, user_id: LC.me.id });
      return false;
    } else {
      await sb.from('likes').insert({ session_id: sessionId, user_id: LC.me.id });
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
      session_id: sessionId, user_id: LC.me.id, text, emoji
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
      from_user: LC.me.id, to_user: toUserId, drink_name: drinkName, occasion
    }).select().single();
    if (error) throw error;
    return data;
  };

  LC.listMyGifts = async function () {
    const { data } = await sb.from('drink_gifts')
      .select('*, from_user:users!drink_gifts_from_user_fkey(display_name, emoji)')
      .eq('to_user', LC.me.id)
      .eq('status', 'pending');
    return data || [];
  };

  LC.respondToGift = async function (giftId, status) {
    await sb.from('drink_gifts').update({ status }).eq('id', giftId);
  };

  // ---------- SOS ----------
  LC.sendSOS = async function (venueName, lat, lng) {
    const { data, error } = await sb.from('sos_alerts').insert({
      user_id: LC.me.id, venue_name: venueName, lat, lng
    }).select().single();
    if (error) throw error;
    return data;
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
