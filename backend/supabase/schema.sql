-- Worship Music App - Supabase/Postgres schema starter
-- Date: 2026-03-07

create extension if not exists pgcrypto;

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key,
  email text not null unique,
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists team_members (
  team_id uuid not null references teams(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null check (role in ('admin', 'worship_leader', 'editor', 'viewer', 'musician')),
  created_at timestamptz not null default now(),
  primary key (team_id, user_id)
);

create table if not exists devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  platform text not null,
  app_version text,
  last_seen_at timestamptz not null default now()
);

create table if not exists songs (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams(id) on delete cascade,
  title text not null,
  artist text,
  ccli_song_id text,
  original_key text,
  current_key text,
  tempo int,
  meter text,
  tags text[] not null default '{}',
  lyrics_with_chords text not null,
  created_by uuid not null references profiles(id),
  updated_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version int not null default 1
);

create index if not exists idx_songs_team_updated on songs(team_id, updated_at desc);

create table if not exists song_versions (
  id uuid primary key default gen_random_uuid(),
  song_id uuid not null references songs(id) on delete cascade,
  version int not null,
  payload jsonb not null,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  unique (song_id, version)
);

create table if not exists setlists (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams(id) on delete cascade,
  name text not null,
  service_date date,
  notes text,
  is_frozen boolean not null default false,
  created_by uuid not null references profiles(id),
  updated_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version int not null default 1
);

create table if not exists setlist_items (
  id uuid primary key default gen_random_uuid(),
  setlist_id uuid not null references setlists(id) on delete cascade,
  song_id uuid not null references songs(id) on delete restrict,
  position int not null,
  notes text,
  created_at timestamptz not null default now(),
  unique (setlist_id, position)
);

create table if not exists setlist_shares (
  setlist_id uuid not null references setlists(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  permission text not null check (permission in ('view', 'edit', 'manage')),
  created_at timestamptz not null default now(),
  primary key (setlist_id, user_id)
);

alter table setlist_shares add column if not exists collaborator_key text;
update setlist_shares
set collaborator_key = user_id::text
where collaborator_key is null;
alter table setlist_shares alter column collaborator_key set not null;
create unique index if not exists idx_setlist_shares_setlist_collaborator
  on setlist_shares(setlist_id, collaborator_key);

create table if not exists integration_accounts (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams(id) on delete cascade,
  provider text not null check (provider in ('songselect', 'planning_center', 'ultimate_guitar')),
  external_account_id text,
  encrypted_tokens text,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists imports (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams(id) on delete cascade,
  provider text not null,
  external_song_id text,
  status text not null check (status in ('queued', 'running', 'done', 'failed')),
  error_message text,
  payload jsonb,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists sync_operations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  device_id uuid not null references devices(id) on delete cascade,
  entity_type text not null,
  entity_id uuid not null,
  operation text not null,
  payload jsonb not null,
  client_created_at timestamptz not null,
  server_received_at timestamptz not null default now(),
  operation_hash text not null,
  unique (operation_hash)
);

create table if not exists sync_cursors (
  user_id uuid not null references profiles(id) on delete cascade,
  device_id uuid not null references devices(id) on delete cascade,
  last_event_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, device_id)
);

create table if not exists audit_events (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams(id) on delete cascade,
  user_id uuid not null references profiles(id),
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb,
  created_at timestamptz not null default now()
);

-- Trigger helper to bump updated_at and version.
create or replace function touch_updated_and_version() returns trigger as $$
begin
  new.updated_at = now();
  new.version = old.version + 1;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_songs_touch on songs;
create trigger trg_songs_touch
before update on songs
for each row execute function touch_updated_and_version();

drop trigger if exists trg_setlists_touch on setlists;
create trigger trg_setlists_touch
before update on setlists
for each row execute function touch_updated_and_version();

-- Supabase RLS starter.
alter table teams enable row level security;
alter table team_members enable row level security;
alter table songs enable row level security;
alter table setlists enable row level security;
alter table setlist_items enable row level security;
alter table setlist_shares enable row level security;
alter table integration_accounts enable row level security;
alter table imports enable row level security;
alter table audit_events enable row level security;

-- Team visibility policy helper.
create or replace function is_team_member(team uuid, uid uuid)
returns boolean as $$
  select exists (
    select 1 from team_members tm
    where tm.team_id = team and tm.user_id = uid
  );
$$ language sql stable;

-- Example policy: members can read songs from their team.
drop policy if exists songs_read_policy on songs;
create policy songs_read_policy on songs
for select
using (is_team_member(team_id, auth.uid()));

-- Example policy: editors/admins can write songs.
drop policy if exists songs_write_policy on songs;
create policy songs_write_policy on songs
for all
using (
  exists (
    select 1 from team_members tm
    where tm.team_id = songs.team_id
      and tm.user_id = auth.uid()
      and tm.role in ('admin', 'worship_leader', 'editor')
  )
)
with check (
  exists (
    select 1 from team_members tm
    where tm.team_id = songs.team_id
      and tm.user_id = auth.uid()
      and tm.role in ('admin', 'worship_leader', 'editor')
  )
);
