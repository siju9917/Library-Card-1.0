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

-- ---------- DONE ----------
-- After this runs successfully, head back to your app and sign in.
