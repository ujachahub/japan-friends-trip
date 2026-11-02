-- Run in Supabase SQL Editor. Public demo voting: NOT identity-secure.
create table if not exists public.trip_votes (
 voter text primary key check (voter in ('그냥유자','예브니혀나','귀여운재나','인싸어목징')),
 choice integer not null check (choice between 0 and 8),
 updated_at timestamptz not null default now()
);
alter table public.trip_votes enable row level security;
create policy "Read shared trip votes" on public.trip_votes for select to anon using (true);
create policy "Insert trip vote" on public.trip_votes for insert to anon with check (true);
create policy "Update trip vote" on public.trip_votes for update to anon using (true) with check (true);
create policy "Delete trip vote" on public.trip_votes for delete to anon using (true);
-- WARNING: Anyone with the public site can select any of the four names and change votes.
-- This is suitable only for a casual, low-stakes friends poll.
