-- ============================================================
-- LIBRARY CARD — Supabase Schema
-- Run this entire file in: Supabase Dashboard → SQL Editor → New Query
-- Safe to re-run; uses IF NOT EXISTS / CREATE OR REPLACE everywhere.
-- ============================================================

-- ---------- USERS ----------
-- Mirrors auth.users; we add app-specific profile fields here.
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  display_name text not null default 'Friend',
  emoji text default '🍺',
  weight_kg numeric,
  biological_sex text,
  weekly_goal int,
  drink_cap int default 0,
  created_at timestamptz default now()
);
alter table public.users enable row level security;

-- Anyone signed in can see any user's basic profile (small private group)
drop policy if exists "users_select_all_signed_in" on public.users;
create policy "users_select_all_signed_in" on public.users
  for select using (auth.uid() is not null);

-- A user can only insert/update their own row
drop policy if exists "users_insert_self" on public.users;
create policy "users_insert_self" on public.users
  for insert with check (auth.uid() = id);

drop policy if exists "users_update_self" on public.users;
create policy "users_update_self" on public.users
  for update using (auth.uid() = id);

-- Auto-create a public.users row when someone signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, email, display_name)
  values (new.id, new.email, coalesce(split_part(new.email, '@', 1), 'Friend'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- VENUES ----------
-- Pre-seeded by you with your local bars. No external API needed.
create table if not exists public.venues (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  lat numeric,
  lng numeric,
  emoji text default '📍',
  created_at timestamptz default now()
);
alter table public.venues enable row level security;
drop policy if exists "venues_select_all" on public.venues;
create policy "venues_select_all" on public.venues
  for select using (auth.uid() is not null);

-- ---------- SESSIONS ----------
create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  venue_id uuid references public.venues(id),
  venue_name text,
  start_time timestamptz not null default now(),
  end_time timestamptz,
  total_drinks int default 0,
  total_cheers int default 0,
  created_at timestamptz default now()
);
alter table public.sessions enable row level security;

-- Anyone signed in can see sessions (private group). Tighten later if needed.
drop policy if exists "sessions_select_all" on public.sessions;
create policy "sessions_select_all" on public.sessions
  for select using (auth.uid() is not null);

drop policy if exists "sessions_insert_own" on public.sessions;
create policy "sessions_insert_own" on public.sessions
  for insert with check (auth.uid() = user_id);

drop policy if exists "sessions_update_own" on public.sessions;
create policy "sessions_update_own" on public.sessions
  for update using (auth.uid() = user_id);

drop policy if exists "sessions_delete_own" on public.sessions;
create policy "sessions_delete_own" on public.sessions
  for delete using (auth.uid() = user_id);

create index if not exists sessions_user_idx on public.sessions(user_id, start_time desc);
create index if not exists sessions_active_idx on public.sessions(end_time) where end_time is null;

-- ---------- DRINKS ----------
create table if not exists public.drinks (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  name text not null,
  drink_type text not null,
  is_na boolean default false,
  rating int,
  has_photo boolean default false,
  photo_url text,
  caption text,
  logged_at timestamptz default now()
);
alter table public.drinks enable row level security;

drop policy if exists "drinks_select_all" on public.drinks;
create policy "drinks_select_all" on public.drinks
  for select using (auth.uid() is not null);

drop policy if exists "drinks_insert_own" on public.drinks;
create policy "drinks_insert_own" on public.drinks
  for insert with check (auth.uid() = user_id);

drop policy if exists "drinks_update_own" on public.drinks;
create policy "drinks_update_own" on public.drinks
  for update using (auth.uid() = user_id);

drop policy if exists "drinks_delete_own" on public.drinks;
create policy "drinks_delete_own" on public.drinks
  for delete using (auth.uid() = user_id);

create index if not exists drinks_session_idx on public.drinks(session_id);

-- ---------- FRIENDSHIPS / CIRCLES ----------
-- One row per directed relationship: user_id places friend_id into a tier.
create table if not exists public.friendships (
  user_id uuid not null references public.users(id) on delete cascade,
  friend_id uuid not null references public.users(id) on delete cascade,
  tier text not null default 'friends', -- diehards | besties | friends
  created_at timestamptz default now(),
  primary key (user_id, friend_id),
  check (tier in ('diehards','besties','friends'))
);
alter table public.friendships enable row level security;

drop policy if exists "friendships_select_own" on public.friendships;
create policy "friendships_select_own" on public.friendships
  for select using (auth.uid() = user_id or auth.uid() = friend_id);

drop policy if exists "friendships_insert_own" on public.friendships;
create policy "friendships_insert_own" on public.friendships
  for insert with check (auth.uid() = user_id);

drop policy if exists "friendships_update_own" on public.friendships;
create policy "friendships_update_own" on public.friendships
  for update using (auth.uid() = user_id);

drop policy if exists "friendships_delete_own" on public.friendships;
create policy "friendships_delete_own" on public.friendships
  for delete using (auth.uid() = user_id);

-- ---------- LIKES (🔥) ----------
create table if not exists public.likes (
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (session_id, user_id)
);
alter table public.likes enable row level security;

drop policy if exists "likes_select_all" on public.likes;
create policy "likes_select_all" on public.likes
  for select using (auth.uid() is not null);

drop policy if exists "likes_insert_own" on public.likes;
create policy "likes_insert_own" on public.likes
  for insert with check (auth.uid() = user_id);

drop policy if exists "likes_delete_own" on public.likes;
create policy "likes_delete_own" on public.likes
  for delete using (auth.uid() = user_id);

-- ---------- COMMENTS ----------
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  text text not null,
  emoji text default '💬',
  created_at timestamptz default now()
);
alter table public.comments enable row level security;

drop policy if exists "comments_select_all" on public.comments;
create policy "comments_select_all" on public.comments
  for select using (auth.uid() is not null);

drop policy if exists "comments_insert_own" on public.comments;
create policy "comments_insert_own" on public.comments
  for insert with check (auth.uid() = user_id);

drop policy if exists "comments_delete_own" on public.comments;
create policy "comments_delete_own" on public.comments
  for delete using (auth.uid() = user_id);

create index if not exists comments_session_idx on public.comments(session_id, created_at desc);

-- ---------- DRINK GIFTS (zero-dollar IOU ledger) ----------
create table if not exists public.drink_gifts (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.users(id) on delete cascade,
  to_user uuid not null references public.users(id) on delete cascade,
  drink_name text not null,
  occasion text,
  status text not null default 'pending', -- pending | accepted | declined | redeemed
  created_at timestamptz default now()
);
alter table public.drink_gifts enable row level security;

drop policy if exists "gifts_select_involved" on public.drink_gifts;
create policy "gifts_select_involved" on public.drink_gifts
  for select using (auth.uid() = from_user or auth.uid() = to_user);

drop policy if exists "gifts_insert_own" on public.drink_gifts;
create policy "gifts_insert_own" on public.drink_gifts
  for insert with check (auth.uid() = from_user);

drop policy if exists "gifts_update_recipient" on public.drink_gifts;
create policy "gifts_update_recipient" on public.drink_gifts
  for update using (auth.uid() = to_user);

-- ---------- SOS ALERTS ----------
create table if not exists public.sos_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  venue_name text,
  lat numeric,
  lng numeric,
  status text not null default 'active', -- active | acknowledged | resolved
  created_at timestamptz default now()
);
alter table public.sos_alerts enable row level security;

drop policy if exists "sos_select_all" on public.sos_alerts;
create policy "sos_select_all" on public.sos_alerts
  for select using (auth.uid() is not null);

drop policy if exists "sos_insert_own" on public.sos_alerts;
create policy "sos_insert_own" on public.sos_alerts
  for insert with check (auth.uid() = user_id);

drop policy if exists "sos_update_all" on public.sos_alerts;
create policy "sos_update_all" on public.sos_alerts
  for update using (auth.uid() is not null);

-- ---------- REALTIME ----------
-- Enable realtime on the tables that drive the live UI
alter publication supabase_realtime add table public.sessions;
alter publication supabase_realtime add table public.drinks;
alter publication supabase_realtime add table public.likes;
alter publication supabase_realtime add table public.comments;
alter publication supabase_realtime add table public.drink_gifts;
alter publication supabase_realtime add table public.sos_alerts;
alter publication supabase_realtime add table public.friendships;

-- ---------- STORAGE BUCKET FOR PHOTOS ----------
-- Run this in Storage → New bucket UI as well, OR via SQL:
insert into storage.buckets (id, name, public)
values ('cheers-photos', 'cheers-photos', true)
on conflict (id) do nothing;

-- Anyone signed in can upload to their own folder
drop policy if exists "cheers_upload_own" on storage.objects;
create policy "cheers_upload_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'cheers-photos' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "cheers_select_all" on storage.objects;
create policy "cheers_select_all" on storage.objects
  for select using (bucket_id = 'cheers-photos');

drop policy if exists "cheers_delete_own" on storage.objects;
create policy "cheers_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'cheers-photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- FRIEND REQUEST STATUS ----------
-- Add status column for friend request approval flow.
-- Safe to re-run: IF NOT EXISTS / DO NOTHING.
alter table public.friendships add column if not exists status text default 'pending';
-- Mark ALL existing friendships as accepted (they were already agreed upon)
update public.friendships set status = 'accepted' where status is null or status = 'pending';

-- ---------- INVITE LINK (accept_invite RPC) ----------
-- Called when a new user signs up via an invite link. Both directions auto-accepted.
create or replace function public.accept_invite(inviter_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into friendships (user_id, friend_id, tier, status)
  values (auth.uid(), inviter_id, 'friends', 'accepted')
  on conflict (user_id, friend_id) do update set status = 'accepted';
  insert into friendships (user_id, friend_id, tier, status)
  values (inviter_id, auth.uid(), 'friends', 'accepted')
  on conflict (user_id, friend_id) do update set status = 'accepted';
end;
$$;

-- ---------- ACCEPT FRIEND REQUEST RPC ----------
-- Called when a user approves an incoming friend request.
-- Updates the requester's row to accepted + creates the reverse row as accepted.
create or replace function public.accept_friend_request(requester_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update friendships set status = 'accepted'
  where user_id = requester_id and friend_id = auth.uid();
  insert into friendships (user_id, friend_id, tier, status)
  values (auth.uid(), requester_id, 'friends', 'accepted')
  on conflict (user_id, friend_id) do update set status = 'accepted';
end;
$$;

-- ---------- WEEKEND PLANS ----------
create table if not exists public.weekend_plans (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references public.users(id) on delete cascade,
  name text not null,
  description text default '',
  emoji text default '📍',
  week_start date not null default (date_trunc('week', current_date + interval '1 day'))::date,
  invited_ids text[] default '{}',
  created_at timestamptz default now()
);
-- Add invited_ids column if table already exists (safe to re-run)
alter table public.weekend_plans add column if not exists invited_ids text[] default '{}';

alter table public.weekend_plans enable row level security;
drop policy if exists "plans_select_all" on public.weekend_plans;
create policy "plans_select_all" on public.weekend_plans for select using (auth.uid() is not null);
drop policy if exists "plans_insert_own" on public.weekend_plans;
create policy "plans_insert_own" on public.weekend_plans for insert with check (auth.uid() = created_by);
drop policy if exists "plans_delete_own" on public.weekend_plans;
create policy "plans_delete_own" on public.weekend_plans for delete using (auth.uid() = created_by);

create table if not exists public.weekend_votes (
  plan_id uuid not null references public.weekend_plans(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (plan_id, user_id)
);
alter table public.weekend_votes enable row level security;
drop policy if exists "votes_select_all" on public.weekend_votes;
create policy "votes_select_all" on public.weekend_votes for select using (auth.uid() is not null);
drop policy if exists "votes_insert_own" on public.weekend_votes;
create policy "votes_insert_own" on public.weekend_votes for insert with check (auth.uid() = user_id);
drop policy if exists "votes_delete_own" on public.weekend_votes;
create policy "votes_delete_own" on public.weekend_votes for delete using (auth.uid() = user_id);

-- plan_invites table is no longer used (invited_ids column on weekend_plans replaces it).
-- Kept for backward compat — safe to ignore.
create table if not exists public.plan_invites (
  plan_id uuid not null references public.weekend_plans(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  primary key (plan_id, user_id)
);
alter table public.plan_invites enable row level security;
drop policy if exists "plan_invites_select" on public.plan_invites;
create policy "plan_invites_select" on public.plan_invites for select using (auth.uid() is not null);
drop policy if exists "plan_invites_insert" on public.plan_invites;
create policy "plan_invites_insert" on public.plan_invites for insert with check (true);

alter publication supabase_realtime add table public.weekend_plans;
alter publication supabase_realtime add table public.weekend_votes;

-- ---------- DONE ----------
-- After this runs successfully, head back to your app and sign in.

-- ========== MASTER MIGRATION v50 ==========
-- Run this entire block to ensure all tables, columns, policies, and
-- functions exist. Safe to re-run on any database state.

-- === Column additions (safe to re-run) ===
ALTER TABLE public.friendships ADD COLUMN IF NOT EXISTS status text DEFAULT 'accepted';
ALTER TABLE public.weekend_plans ADD COLUMN IF NOT EXISTS invited_ids text[] DEFAULT '{}';

-- === USERS policies ===
DROP POLICY IF EXISTS "users_select_all_signed_in" ON public.users;
CREATE POLICY "users_select_all_signed_in" ON public.users
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "users_insert_self" ON public.users;
CREATE POLICY "users_insert_self" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "users_update_self" ON public.users;
CREATE POLICY "users_update_self" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- === VENUES policies ===
DROP POLICY IF EXISTS "venues_select_all" ON public.venues;
CREATE POLICY "venues_select_all" ON public.venues
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- === SESSIONS policies ===
DROP POLICY IF EXISTS "sessions_select_all" ON public.sessions;
CREATE POLICY "sessions_select_all" ON public.sessions
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "sessions_insert_own" ON public.sessions;
CREATE POLICY "sessions_insert_own" ON public.sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "sessions_update_own" ON public.sessions;
CREATE POLICY "sessions_update_own" ON public.sessions
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "sessions_delete_own" ON public.sessions;
CREATE POLICY "sessions_delete_own" ON public.sessions
  FOR DELETE USING (auth.uid() = user_id);

-- === DRINKS policies ===
DROP POLICY IF EXISTS "drinks_select_all" ON public.drinks;
CREATE POLICY "drinks_select_all" ON public.drinks
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "drinks_insert_own" ON public.drinks;
CREATE POLICY "drinks_insert_own" ON public.drinks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "drinks_update_own" ON public.drinks;
CREATE POLICY "drinks_update_own" ON public.drinks
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "drinks_delete_own" ON public.drinks;
CREATE POLICY "drinks_delete_own" ON public.drinks
  FOR DELETE USING (auth.uid() = user_id);

-- === FRIENDSHIPS policies ===
DROP POLICY IF EXISTS "friendships_select_own" ON public.friendships;
CREATE POLICY "friendships_select_own" ON public.friendships
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);

DROP POLICY IF EXISTS "friendships_insert_own" ON public.friendships;
CREATE POLICY "friendships_insert_own" ON public.friendships
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "friendships_update_own" ON public.friendships;
CREATE POLICY "friendships_update_own" ON public.friendships
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "friendships_delete_own" ON public.friendships;
CREATE POLICY "friendships_delete_own" ON public.friendships
  FOR DELETE USING (auth.uid() = user_id);

-- === LIKES policies ===
DROP POLICY IF EXISTS "likes_select_all" ON public.likes;
CREATE POLICY "likes_select_all" ON public.likes
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "likes_insert_own" ON public.likes;
CREATE POLICY "likes_insert_own" ON public.likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "likes_delete_own" ON public.likes;
CREATE POLICY "likes_delete_own" ON public.likes
  FOR DELETE USING (auth.uid() = user_id);

-- === COMMENTS policies ===
DROP POLICY IF EXISTS "comments_select_all" ON public.comments;
CREATE POLICY "comments_select_all" ON public.comments
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "comments_insert_own" ON public.comments;
CREATE POLICY "comments_insert_own" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "comments_delete_own" ON public.comments;
CREATE POLICY "comments_delete_own" ON public.comments
  FOR DELETE USING (auth.uid() = user_id);

-- === DRINK GIFTS policies ===
DROP POLICY IF EXISTS "gifts_select_involved" ON public.drink_gifts;
CREATE POLICY "gifts_select_involved" ON public.drink_gifts
  FOR SELECT USING (auth.uid() = from_user OR auth.uid() = to_user);

DROP POLICY IF EXISTS "gifts_insert_own" ON public.drink_gifts;
CREATE POLICY "gifts_insert_own" ON public.drink_gifts
  FOR INSERT WITH CHECK (auth.uid() = from_user);

DROP POLICY IF EXISTS "gifts_update_recipient" ON public.drink_gifts;
CREATE POLICY "gifts_update_recipient" ON public.drink_gifts
  FOR UPDATE USING (auth.uid() = to_user);

-- === SOS ALERTS policies ===
DROP POLICY IF EXISTS "sos_select_all" ON public.sos_alerts;
CREATE POLICY "sos_select_all" ON public.sos_alerts
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "sos_insert_own" ON public.sos_alerts;
CREATE POLICY "sos_insert_own" ON public.sos_alerts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "sos_update_all" ON public.sos_alerts;
CREATE POLICY "sos_update_all" ON public.sos_alerts
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- === WEEKEND PLANS policies ===
DROP POLICY IF EXISTS "plans_select_all" ON public.weekend_plans;
CREATE POLICY "plans_select_all" ON public.weekend_plans
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "plans_insert_own" ON public.weekend_plans;
CREATE POLICY "plans_insert_own" ON public.weekend_plans
  FOR INSERT WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "plans_delete_own" ON public.weekend_plans;
CREATE POLICY "plans_delete_own" ON public.weekend_plans
  FOR DELETE USING (auth.uid() = created_by);

-- === WEEKEND VOTES policies ===
DROP POLICY IF EXISTS "votes_select_all" ON public.weekend_votes;
CREATE POLICY "votes_select_all" ON public.weekend_votes
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "votes_insert_own" ON public.weekend_votes;
CREATE POLICY "votes_insert_own" ON public.weekend_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "votes_delete_own" ON public.weekend_votes;
CREATE POLICY "votes_delete_own" ON public.weekend_votes
  FOR DELETE USING (auth.uid() = user_id);

-- === PLAN INVITES policies ===
DROP POLICY IF EXISTS "plan_invites_select" ON public.plan_invites;
CREATE POLICY "plan_invites_select" ON public.plan_invites
  FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "plan_invites_insert" ON public.plan_invites;
CREATE POLICY "plan_invites_insert" ON public.plan_invites
  FOR INSERT WITH CHECK (true);

-- === STORAGE policies ===
DROP POLICY IF EXISTS "cheers_upload_own" ON storage.objects;
CREATE POLICY "cheers_upload_own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'cheers-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS "cheers_select_all" ON storage.objects;
CREATE POLICY "cheers_select_all" ON storage.objects
  FOR SELECT USING (bucket_id = 'cheers-photos');

DROP POLICY IF EXISTS "cheers_delete_own" ON storage.objects;
CREATE POLICY "cheers_delete_own" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'cheers-photos' AND (storage.foldername(name))[1] = auth.uid()::text);

-- === RPC functions ===
CREATE OR REPLACE FUNCTION public.accept_invite(inviter_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO friendships (user_id, friend_id, tier, status)
  VALUES (auth.uid(), inviter_id, 'friends', 'accepted')
  ON CONFLICT (user_id, friend_id) DO UPDATE SET status = 'accepted';
  INSERT INTO friendships (user_id, friend_id, tier, status)
  VALUES (inviter_id, auth.uid(), 'friends', 'accepted')
  ON CONFLICT (user_id, friend_id) DO UPDATE SET status = 'accepted';
END;
$$;

CREATE OR REPLACE FUNCTION public.accept_friend_request(requester_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE friendships SET status = 'accepted'
  WHERE user_id = requester_id AND friend_id = auth.uid();
  INSERT INTO friendships (user_id, friend_id, tier, status)
  VALUES (auth.uid(), requester_id, 'friends', 'accepted')
  ON CONFLICT (user_id, friend_id) DO UPDATE SET status = 'accepted';
END;
$$;

-- === Realtime publication (safe to re-run — errors on already-added are OK) ===
DO $$
BEGIN
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.drinks; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.likes; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.comments; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.drink_gifts; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.sos_alerts; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.weekend_plans; EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.weekend_votes; EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;

-- ========== END MASTER MIGRATION v50 ==========

-- ========== MIGRATION v74: IDEMPOTENCY KEYS ON WRITES ==========
-- Adds a client-generated op-id column + unique index on drinks and
-- sessions. The app sends a UUID in every write; the unique index means
-- a retry that accidentally succeeded twice is rejected at the DB,
-- preventing the "friends have more drinks than they actually had"
-- duplicate-row bug.
--
-- Safe to re-run. Partial indexes (WHERE ... IS NOT NULL) so existing
-- rows with NULL op-ids don't all collide.

ALTER TABLE public.drinks ADD COLUMN IF NOT EXISTS client_op_id text;
CREATE UNIQUE INDEX IF NOT EXISTS drinks_client_op_id_uniq
  ON public.drinks(client_op_id) WHERE client_op_id IS NOT NULL;

ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS client_op_id text;
CREATE UNIQUE INDEX IF NOT EXISTS sessions_client_op_id_uniq
  ON public.sessions(client_op_id) WHERE client_op_id IS NOT NULL;

-- ========== END MIGRATION v74 ==========
