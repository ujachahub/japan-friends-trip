-- Run ONCE in Supabase SQL Editor to enable multiple likes per person.
-- This creates a new table and copies previous single-choice votes, if any.
create table if not exists public.trip_likes (
  voter text not null check (voter in ('상코미유자','예쀼니혀나','귀여미재나','핫걸어목징')),
  choice integer not null check (choice between 0 and 8),
  created_at timestamptz not null default now(),
  primary key (voter, choice)
);
alter table public.trip_likes enable row level security;
drop policy if exists "Read trip likes" on public.trip_likes;
drop policy if exists "Add trip likes" on public.trip_likes;
drop policy if exists "Remove trip likes" on public.trip_likes;
create policy "Read trip likes" on public.trip_likes for select to anon using (true);
create policy "Add trip likes" on public.trip_likes for insert to anon with check (true);
create policy "Remove trip likes" on public.trip_likes for delete to anon using (true);
insert into public.trip_likes (voter, choice)
select case voter
  when '그냥유자' then '상코미유자'
  when '예브니혀나' then '예쀼니혀나'
  when '귀여운재나' then '귀여미재나'
  when '인싸어목징' then '핫걸어목징'
  else voter end, choice
from public.trip_votes
on conflict (voter, choice) do nothing;
