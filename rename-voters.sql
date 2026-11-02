-- Run ONCE in the existing Supabase project's SQL Editor.
-- Keep existing votes while renaming the four voters.
begin;
alter table public.trip_votes drop constraint if exists trip_votes_voter_check;
update public.trip_votes set voter = case voter
  when '그냥유자' then '상코미유자'
  when '예브니혀나' then '예쀼니혀나'
  when '귀여운재나' then '귀여미재나'
  when '인싸어목징' then '핫걸어목징'
  else voter end;
alter table public.trip_votes add constraint trip_votes_voter_check
  check (voter in ('상코미유자','예쀼니혀나','귀여미재나','핫걸어목징'));
commit;
