create extension if not exists btree_gist;

create table public.stylists (
  id text primary key,
  name text not null
);
insert into public.stylists (id, name) values
  ('s1', 'Aarav Mehta'),
  ('s2', 'Naina Kapoor'),
  ('s3', 'Rohan Verma'),
  ('s4', 'Isha Malhotra');

alter table public.stylists enable row level security;
create policy "stylists readable" on public.stylists
  for select to authenticated using (true);

create table public.appointments (
  id text primary key,
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  branch_name text not null,
  stylist_id text not null references public.stylists(id),
  stylist_name text not null,
  service_names text[] not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  duration_min int not null check (duration_min > 0),
  subtotal int not null,
  discount int not null default 0,
  tax int not null,
  total int not null,
  payment_method text not null,
  coupon_code text,
  status text not null default 'confirmed'
    check (status in ('confirmed','checked_in','in_service','completed','cancelled')),
  created_at timestamptz not null default now(),
  check (end_at > start_at),
  constraint no_stylist_overlap exclude using gist (
    stylist_id with =, tstzrange(start_at, end_at) with &&
  ) where (status in ('confirmed','checked_in','in_service')),
  constraint no_user_overlap exclude using gist (
    user_id with =, tstzrange(start_at, end_at) with &&
  ) where (status in ('confirmed','checked_in','in_service'))
);

alter table public.appointments enable row level security;

-- Users can only read their own rows. No insert/update policies:
-- all writes go through the functions below.
create policy "read own appointments" on public.appointments
  for select using (auth.uid() = user_id);

create function public.book_appointment(
  p_id text, p_branch_name text, p_stylist_id text, p_service_names text[],
  p_start timestamptz, p_duration int, p_subtotal int, p_discount int,
  p_tax int, p_total int, p_payment_method text, p_coupon text
) returns public.appointments
language plpgsql security definer set search_path = ''
as $$
declare
  v_stylist text := p_stylist_id;
  v_name text;
  v_end timestamptz;
  v_constraint text;
  v_row public.appointments;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if p_duration < 1 or p_duration > 600 then raise exception 'bad_duration'; end if;
  if p_start < now() then raise exception 'in_past'; end if;

  v_end := p_start + make_interval(mins => p_duration);

  if v_stylist is null then
    select s.id into v_stylist
    from public.stylists s
    where not exists (
      select 1 from public.appointments a
      where a.stylist_id = s.id
        and a.status in ('confirmed','checked_in','in_service')
        and tstzrange(a.start_at, a.end_at) && tstzrange(p_start, v_end)
    )
    order by s.id
    limit 1;
    if v_stylist is null then raise exception 'slot_taken'; end if;
  end if;

  select name into v_name from public.stylists where id = v_stylist;
  if v_name is null then raise exception 'bad_stylist'; end if;

  insert into public.appointments (
    id, user_id, branch_name, stylist_id, stylist_name, service_names,
    start_at, end_at, duration_min, subtotal, discount, tax, total,
    payment_method, coupon_code
  ) values (
    p_id, auth.uid(), p_branch_name, v_stylist, v_name, p_service_names,
    p_start, v_end, p_duration, p_subtotal, p_discount, p_tax, p_total,
    p_payment_method, p_coupon
  ) returning * into v_row;

  return v_row;
exception when exclusion_violation then
  get stacked diagnostics v_constraint = constraint_name;
  if v_constraint = 'no_user_overlap' then raise exception 'user_overlap'; end if;
  raise exception 'slot_taken';
end;
$$;

create function public.cancel_appointment(p_id text)
returns public.appointments
language plpgsql security definer set search_path = ''
as $$
declare v_row public.appointments;
begin
  select * into v_row from public.appointments
  where id = p_id and user_id = auth.uid() for update;
  if not found then raise exception 'not_found'; end if;
  if v_row.status <> 'confirmed' then raise exception 'not_cancellable'; end if;
  if v_row.start_at - now() < interval '4 hours' then
    raise exception 'cancel_window';
  end if;
  update public.appointments set status = 'cancelled'
  where id = p_id returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.book_appointment(text,text,text,text[],timestamptz,int,int,int,int,int,text,text) from public, anon;
grant execute on function public.book_appointment(text,text,text,text[],timestamptz,int,int,int,int,int,text,text) to authenticated;
revoke all on function public.cancel_appointment(text) from public, anon;
grant execute on function public.cancel_appointment(text) to authenticated;