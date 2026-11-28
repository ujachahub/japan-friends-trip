-- Execute AFTER matsuyama/expenses-setup.sql in the same Supabase project.
-- Only visitors who know the shared expense access code may list/toggle restaurant votes.
create table if not exists public.matsu_restaurant_votes(
  food_id text not null check (char_length(food_id) between 1 and 60),
  voter text not null check (voter in ('친구1','친구2','친구3','친구4')),
  created_at timestamptz not null default now(),
  primary key(food_id,voter)
);
alter table public.matsu_restaurant_votes enable row level security;
revoke all on public.matsu_restaurant_votes from anon, authenticated;
create or replace function public.matsu_votes_list(p_code text)
returns table(food_id text,voter text)
language plpgsql security definer set search_path='' as $$
begin
  if not public.matsu_code_ok(p_code) then
    raise exception '접근 코드가 올바르지 않습니다';
  end if;
  return query select v.food_id,v.voter from public.matsu_restaurant_votes v;
end $$;
create or replace function public.matsu_votes_toggle(p_code text,p_food_id text,p_voter text)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not public.matsu_code_ok(p_code) then
    raise exception '접근 코드가 올바르지 않습니다';
  end if;
  if p_voter not in ('친구1','친구2','친구3','친구4') or
     char_length(p_food_id) < 1 or char_length(p_food_id) > 60 then
    raise exception '투표 정보가 올바르지 않습니다';
  end if;
  if exists(select 1 from public.matsu_restaurant_votes where food_id=p_food_id and voter=p_voter) then
    delete from public.matsu_restaurant_votes where food_id=p_food_id and voter=p_voter;
  else
    insert into public.matsu_restaurant_votes(food_id,voter) values(p_food_id,p_voter);
  end if;
end $$;
revoke all on function public.matsu_votes_list(text),public.matsu_votes_toggle(text,text,text) from public;
grant execute on function public.matsu_votes_list(text),public.matsu_votes_toggle(text,text,text) to anon,authenticated;
-- Shared code only provides group-level access; user names are self-selected, not identity verified.
