-- Run in Supabase SQL Editor. Replace the placeholder code before running.
create extension if not exists pgcrypto;
create table if not exists public.matsu_expenses (
 id uuid primary key default gen_random_uuid(),
 place text not null check (char_length(place) between 1 and 80),
 amount_yen integer not null check (amount_yen between 1 and 10000000),
 category text not null check (category in ('식비','교통','관광','쇼핑','기타')),
 created_by text not null check (char_length(created_by) between 1 and 20),
 created_at timestamptz not null default now()
);
create table if not exists public.matsu_expense_access (
 id integer primary key check (id=1),
 code_hash text not null
);
insert into public.matsu_expense_access(id,code_hash)
values (1,crypt('REPLACE_WITH_A_LONG_RANDOM_SHARED_CODE',extensions.gen_salt('bf')))
on conflict (id) do update set code_hash=excluded.code_hash;
alter table public.matsu_expenses enable row level security;
alter table public.matsu_expense_access enable row level security;
revoke all on public.matsu_expenses from anon,authenticated;
revoke all on public.matsu_expense_access from anon,authenticated;
create or replace function public.matsu_code_ok(p_code text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.matsu_expense_access where id=1 and code_hash=extensions.crypt(p_code,code_hash))
$$;
revoke all on function public.matsu_code_ok(text) from public,anon,authenticated;
create or replace function public.matsu_expense_list(p_code text)
returns table(id uuid,place text,amount_yen integer,category text,created_by text,created_at timestamptz)
language plpgsql security definer set search_path='' as $$
begin
 if not public.matsu_code_ok(p_code) then raise exception '접근 코드가 올바르지 않습니다'; end if;
 return query select e.id,e.place,e.amount_yen,e.category,e.created_by,e.created_at from public.matsu_expenses e order by e.created_at desc limit 1000;
end $$;
create or replace function public.matsu_expense_add(p_code text,p_place text,p_amount integer,p_category text,p_actor text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.matsu_code_ok(p_code) then raise exception '접근 코드가 올바르지 않습니다'; end if;
 insert into public.matsu_expenses(place,amount_yen,category,created_by)
 values(trim(p_place),p_amount,p_category,trim(p_actor));
end $$;
create or replace function public.matsu_expense_delete(p_code text,p_id uuid,p_actor text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.matsu_code_ok(p_code) then raise exception '접근 코드가 올바르지 않습니다'; end if;
 delete from public.matsu_expenses where id=p_id and created_by=p_actor;
end $$;
revoke all on function public.matsu_expense_list(text),public.matsu_expense_add(text,text,integer,text,text),public.matsu_expense_delete(text,uuid,text) from public;
grant execute on function public.matsu_expense_list(text),public.matsu_expense_add(text,text,integer,text,text),public.matsu_expense_delete(text,uuid,text) to anon,authenticated;
-- Shared code authorizes access; names are not authenticated identities.
-- For production use, apply API rate limiting / bot protection to reduce code guessing.
