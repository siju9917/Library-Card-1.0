# Library Card → Real App Setup

This file walks you through turning the demo into a working app for you and your ~10 friends. **Total cost: $0.** No App Store, no Apple Developer account, no Twilio.

You only have to do **6 steps**. Everything else is already wired up.

---

## What You'll Have at the End
- A real signed-in app at `https://siju9917.github.io/Library-Card-1.0/`
- Each friend signs in with their email (one-tap magic link)
- Sessions, drinks, friends, likes, and comments persist across devices
- Friends see each other's live sessions in the Live Bar Map
- Installable on iPhone via "Add to Home Screen" — looks like a native app
- Free forever (Supabase free tier covers ~5,000 users; you'll use 0.2% of that)

---

## STEP 1 — Create a free Supabase project (5 min)

1. Go to **https://supabase.com** and click **Start your project**
2. Sign in with GitHub (easiest)
3. Click **New project**
4. Fill in:
   - **Name**: `library-card`
   - **Database password**: click "Generate a password" and save it somewhere (you won't need it often, but don't lose it)
   - **Region**: pick the one closest to your friends (e.g. East US, West EU)
   - **Pricing plan**: **Free**
5. Click **Create new project**. It takes ~1 minute to provision.

---

## STEP 2 — Run the schema (2 min)

1. In your new Supabase project, click **SQL Editor** in the left sidebar
2. Click **New query**
3. Open the file `docs/supabase/schema.sql` from this repo, copy the **entire contents**, and paste it into the SQL editor
4. Click **Run** (or hit Cmd+Enter / Ctrl+Enter)
5. You should see a green "Success. No rows returned" — that means all your tables, policies, and the storage bucket were created

> If you see a red error: read the message, fix what it complains about, and re-run. The schema is safe to re-run multiple times.

---

## STEP 3 — Copy your API keys into the app (1 min)

1. In Supabase, click the **gear icon (Settings)** in the bottom-left → **API**
2. You'll see two things you need:
   - **Project URL** — looks like `https://abcdefghij.supabase.co`
   - **`anon` `public` key** — a long string starting with `eyJhbGc...`
3. Open the file `docs/supabase/config.js` in this repo and paste them in:

```js
window.LC_CONFIG = {
  SUPABASE_URL: 'https://abcdefghij.supabase.co',           // ← your URL here
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXV...', // ← your anon key here
};
```

> ⚠️ **Only paste the `anon public` key.** Never paste the `service_role` key — that one is admin-level and will be public on GitHub.

---

## STEP 4 — Push the changes to GitHub (1 min)

In your terminal, from the repo folder:

```bash
git add docs/supabase/config.js
git commit -m "Add Supabase config"
git push
```

GitHub Pages will redeploy in about 30 seconds. The app is now live in cloud mode.

---

## STEP 5 — Sign in for the first time + add some bars (3 min)

1. Open `https://siju9917.github.io/Library-Card-1.0/` on your phone
2. You'll see a sign-in screen — enter your email and tap **Send Magic Link**
3. Check your inbox. Tap the link in the email — it opens the app already signed in.
4. Go to **Profile → Settings → Display Name**, set what you want friends to see
5. **Add your local bars** (so check-ins have real venue names). In the Supabase dashboard:
   - Click **Table Editor → venues**
   - Click **Insert → Insert row** and add a row for each bar:
     - `name`: e.g. "The Pub"
     - `address`: optional
     - `emoji`: optional, e.g. 🍺
   - Add ~10 of your usual spots. (You can always add more later.)

---

## STEP 6 — Invite your friends (2 min per friend)

For each friend:

1. Send them this link over iMessage:
   ```
   https://siju9917.github.io/Library-Card-1.0/
   ```
2. Tell them to:
   - Open the link in **Safari** (not in iMessage's preview — tap the link, then tap the address bar to make sure it's in Safari)
   - Sign in with their email (magic link to inbox)
   - Tap the **Share button → Add to Home Screen** so it lives on their home screen like an app
   - Set their display name in Profile → Settings
3. Once they've signed in once, you can add them as a friend:
   - In your app, go to **Safety → Circles**
   - Tap **+ Add** under any tier
   - Type in their email — they'll appear with the name they set

That's it. Now when they start a session, you'll see them in your Live Bar Map. When you start one, they'll see you. Likes, comments, and feed activity all flow live between you.

---

## What works right now
- ✅ Email magic-link sign-in (no passwords)
- ✅ Sessions persist across devices for the same user
- ✅ Drinks within a session save to the cloud
- ✅ Friends list (Circles) is real, with 3 trust tiers
- ✅ Likes (🔥) and comments persist
- ✅ Live Bar Map shows real friends with active sessions
- ✅ Realtime updates — when a friend logs a drink, your screen refreshes automatically
- ✅ Installable as a PWA on iPhone (works offline, looks native)
- ✅ Display name editable, sign-out button in Settings

## What's still local-only (for now — next iteration)
- Photos: the camera UI is still simulated. When I add real `getUserMedia` capture, photos will upload to Supabase Storage automatically (the upload code already exists in `db.js`).
- Push notifications for SOS / friend departures / drink gifts. Web Push works on iOS 16.4+ but requires a small one-time setup.
- Stats charts still draw from your own session history, not aggregated friend data.
- "Future features" demos (Bar Raids, Swipe at Bar, etc.) stay as previews — they need many more users to be useful.

## Demo mode is still there
If you ever clear `config.js` (set the strings back to empty), the app falls back to local-only demo mode — perfect if you want to show someone the prototype without giving them an account.

## When something breaks
- Check the **Supabase Dashboard → Logs → API logs** for errors — they're usually clearer than the browser console.
- Check the browser console (Safari → Develop menu → device name) for `console.warn` messages from `db.js`.
- The most common issue is **Row Level Security blocking a query** — every error from Supabase will say which policy fired. Most can be fixed by re-running the schema.

## What costs money (it shouldn't, for 10 friends)
- Supabase free tier limits: 500 MB database, 1 GB file storage, 5 GB bandwidth/month, 50K monthly active users. You'll use **<1%** of every limit with 10 friends.
- GitHub Pages: free forever for public repos.
- Domain: optional. `siju9917.github.io/Library-Card-1.0/` is free. A custom domain ($10/yr) would be the only thing you'd ever pay for.

---

## What I (Claude) did vs. what you have to do

### Done already (committed to the repo):
- ✅ Schema SQL with all tables, RLS policies, indexes, storage bucket
- ✅ Supabase data layer (`db.js`) — auth, sessions, drinks, friends, likes, comments, photos, gifts, SOS, realtime subscriptions
- ✅ Auth gate UI (sign-in screen with email magic link)
- ✅ Service worker + manifest + icons (PWA install)
- ✅ Cloud session lifecycle wired into start/end/log-drink flows
- ✅ Circles → real friendships, with email lookup for adding friends
- ✅ Live Bar Map pulls real active sessions
- ✅ Like (🔥) button persists to cloud
- ✅ Display name editing + sign-out
- ✅ Hydration on sign-in (your sessions and friends load fresh from cloud)
- ✅ Realtime subscription that auto-refreshes the visible tab when friends do anything

### You have to do (the 6 steps above):
1. Create Supabase project
2. Paste schema.sql into SQL editor and run
3. Copy URL + anon key into config.js
4. `git push`
5. Sign in once and add your local bars
6. Send the link to your friends
