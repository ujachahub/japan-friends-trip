-- Matsuyama expenses date upgrade. Run ONCE in the same Supabase SQL Editor.
-- Preserves all existing expense rows and access-code settings.
alter table public.matsu_expenses add column if not exists expense_date date;
update public.matsu_expenses set expense_date=(created_at at time zone 'Asia/Tokyo')::date where expense_date is null;
alter table public.matsu_expenses alter column expense_date set default (now() at time zone 'Asia/Tokyo')::date;
alter table public.matsu_expenses alter column expense_date set not null;

create or replace function public.matsu_expense_list_dated(p_code text)
returns table (id uuid, place text, amount_yen integer, category text, created_by text, created_at timestamptz, expense_date date)
language plpgsql security definer set search_path='' as $$
begin
 if not public.matsu_code_ok(p_code) then raise exception '접근 코드가 올바르지 않습니다'; end if;
 return query select e.id,e.place,e.amount_yen,e.category,e.created_by,e.created_at,e.expense_date
 from public.matsu_expenses e order by e.expense_date desc,e.created_at desc limit 1000;
end $$;
create or replace function public.matsu_expense_add_dated(
 p_code text, p_place text, p_amount integer, p_category text, p_actor text, p_date date)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.matsu_code_ok(p_code) then raise exception '접근 코드가 올바르지 않습니다'; end if;
 if p_date is null or p_date < date '2020-01-01' or p_date > date '2100-12-31'
 then raise exception '날짜가 올바르지 않습니다'; end if;
 insert into public.matsu_expenses(place,amount_yen,category,created_by,expense_date)
 values(trim(p_place),p_amount,p_category,trim(p_actor),p_date);
end $$;
revoke all on function public.matsu_expense_list_dated(text),public.matsu_expense_add_dated(text,text,integer,text,text,date) from public;
grant execute on function public.matsu_expense_list_dated(text),public.matsu_expense_add_dated(text,text,integer,text,text,date) to anon,authenticated;
