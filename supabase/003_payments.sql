alter table public.appointments
  add column payment_status text not null default 'unpaid'
    check (payment_status in ('unpaid','pending','paid','failed','refund_pending')),
  add column razorpay_order_id text unique,
  add column razorpay_payment_id text unique,
  add column hold_expires_at timestamptz;

alter table public.appointments drop constraint appointments_status_check;
alter table public.appointments add constraint appointments_status_check
  check (status in ('pending_payment','confirmed','checked_in','in_service','completed','cancelled'));

-- Held (unpaid) slots must block other bookings too.
alter table public.appointments drop constraint no_stylist_overlap;
alter table public.appointments drop constraint no_user_overlap;
alter table public.appointments add constraint no_stylist_overlap exclude using gist (
  stylist_id with =, tstzrange(start_at, end_at) with &&
) where (status in ('pending_payment','confirmed','checked_in','in_service'));
alter table public.appointments add constraint no_user_overlap exclude using gist (
  user_id with =, tstzrange(start_at, end_at) with &&
) where (status in ('pending_payment','confirmed','checked_in','in_service'));

create or replace function public.book_appointment(
  p_id text, p_branch_name text, p_stylist_id text, p_service_ids text[],
  p_start timestamptz, p_coupon text, p_payment_method text
) returns public.appointments
language plpgsql security definer set search_path = ''
as $$
declare
  v_ids text[];
  v_count int;
  v_groups int;
  v_distinct_groups int;
  v_names text[];
  v_subtotal int;
  v_duration int;
  v_discount int := 0;
  v_eligible int;
  v_tax int;
  v_coupon public.coupons;
  v_stylist text := p_stylist_id;
  v_name text;
  v_end timestamptz;
  v_constraint text;
  v_online boolean := (p_payment_method = 'Online');
  v_row public.appointments;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if p_start < now() then raise exception 'in_past'; end if;
  if p_payment_method not in ('Pay at salon', 'Online') then
    raise exception 'bad_payment';
  end if;

  -- Release expired payment holds so the slots free up.
  update public.appointments
     set status = 'cancelled', payment_status = 'failed'
   where status = 'pending_payment' and hold_expires_at < now();

  select array_agg(distinct x) into v_ids from unnest(p_service_ids) as x;
  if v_ids is null then raise exception 'bad_services'; end if;

  select count(*), sum(price), sum(duration_min),
         array_agg(name order by name),
         count(exclusive_group), count(distinct exclusive_group)
    into v_count, v_subtotal, v_duration, v_names, v_groups, v_distinct_groups
  from public.services
  where id = any(v_ids) and active;

  if v_count <> cardinality(v_ids) or v_groups <> v_distinct_groups then
    raise exception 'bad_services';
  end if;

  if p_coupon is not null and btrim(p_coupon) <> '' then
    select * into v_coupon from public.coupons
    where code = upper(btrim(p_coupon)) and active
      and (expires_at is null or expires_at > now());
    if not found then raise exception 'bad_coupon'; end if;

    if v_coupon.category_id is null then
      v_eligible := v_subtotal;
    else
      select coalesce(sum(price), 0) into v_eligible from public.services
      where id = any(v_ids) and category_id = v_coupon.category_id;
    end if;
    if v_eligible = 0 then raise exception 'bad_coupon'; end if;

    v_discount := least(
      round(v_eligible * v_coupon.percent / 100.0)::int,
      v_coupon.max_discount);
  end if;

  v_tax := round((v_subtotal - v_discount) * 18 / 100.0)::int;
  v_end := p_start + make_interval(mins => v_duration);

  if v_stylist is null then
    select s.id into v_stylist
    from public.stylists s
    where not exists (
      select 1 from public.appointments a
      where a.stylist_id = s.id
        and a.status in ('pending_payment','confirmed','checked_in','in_service')
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
    payment_method, coupon_code, status, payment_status, hold_expires_at
  ) values (
    p_id, auth.uid(), p_branch_name, v_stylist, v_name, v_names,
    p_start, v_end, v_duration, v_subtotal, v_discount, v_tax,
    v_subtotal - v_discount + v_tax,
    p_payment_method, upper(nullif(btrim(p_coupon), '')),
    case when v_online then 'pending_payment' else 'confirmed' end,
    case when v_online then 'pending' else 'unpaid' end,
    case when v_online then now() + interval '10 minutes' else null end
  ) returning * into v_row;

  return v_row;
exception when exclusion_violation then
  get stacked diagnostics v_constraint = constraint_name;
  if v_constraint = 'no_user_overlap' then raise exception 'user_overlap'; end if;
  raise exception 'slot_taken';
end;
$$;

create or replace function public.cancel_appointment(p_id text)
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
  update public.appointments
     set status = 'cancelled',
         payment_status = case when payment_status = 'paid'
                               then 'refund_pending' else payment_status end
   where id = p_id returning * into v_row;
  return v_row;
end;
$$;