-- Run once in the Supabase SQL editor.
-- Accounts only: no case / hearing / document / fee columns, ever.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  plan text not null default 'free',
  salt text not null,              -- base64 PBKDF2 salt (not secret)
  display_name text,
  enrolment text,
  bar_council text,
  chamber text,
  created_at timestamptz not null default now()
);

-- For existing projects that already created profiles without chamber fields:
alter table public.profiles add column if not exists display_name text;
alter table public.profiles add column if not exists enrolment text;
alter table public.profiles add column if not exists bar_council text;
alter table public.profiles add column if not exists chamber text;
alter table public.profiles add column if not exists phone text;

alter table public.profiles enable row level security;

drop policy if exists "read own profile" on public.profiles;
create policy "read own profile"
  on public.profiles for select
  using (auth.uid() = id);

drop policy if exists "insert own profile" on public.profiles;
create policy "insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "update own profile salt only" on public.profiles;
drop policy if exists "update own profile" on public.profiles;
create policy "update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Plan changes go through the service-role key (Stripe webhook), bypassing RLS.
