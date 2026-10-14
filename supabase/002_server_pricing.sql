create table public.services (
  id text primary key,
  category_id text not null,
  name text not null,
  price int not null check (price >= 0),
  duration_min int not null check (duration_min > 0),
  exclusive_group text,
  active boolean not null default true
);

insert into public.services (id, category_id, name, price, duration_min, exclusive_group) values
  ('sv_cut','hair','Signature Cut & Style',899,45,'haircut'),
  ('sv_blow','hair','Blow Dry & Finish',549,30,'finish'),
  ('sv_balayage','colour','Balayage Colour',4499,150,'colour'),
  ('sv_gloss','colour','Gloss & Tone Treatment',1999,60,'colour'),
  ('sv_beard','beard','Beard Sculpt & Shave',599,30,'beard'),
  ('sv_shave','beard','Classic Hot Towel Shave',449,25,'beard'),
  ('sv_hydra','facial','Hydrating Facial',1799,60,'facial'),
  ('sv_cleanup','facial','Express Clean-up',899,30,'facial'),
  ('sv_wax_arms','wax','Arms Waxing',499,20,null),
  ('sv_wax_legs','wax','Full Legs Waxing',899,40,null),
  ('sv_mani','nails','Classic Manicure',599,40,null),
  ('sv_pedi','nails','Spa Pedicure',799,50,null),
  ('sv_head','spa','Head & Shoulder Massage',699,30,'massage'),
  ('sv_body','spa','Relaxing Body Massage',2499,60,'massage'),
  ('sv_bridal','bridal','Bridal Makeup & Styling',14999,240,'bridal'),
  ('sv_trial','bridal','Bridal Trial Session',2999,90,'bridal');

alter table public.services enable row level security;
create policy "services readable" on public.services
  for select to authenticated using (true);

create table public.coupons (
  code text primary key,
  percent int not null check (percent between 1 and 100),
  max_discount int not null check (max_discount >= 0),
  category_id text,
  active boolean not null default true,
  expires_at timestamptz
);

insert into public.coupons (code, percent, max_discount, category_id) values
  ('WELCOME20', 20, 500, null),
  ('GLOW15', 15, 400, 'facial');

-- No policy on coupons: clients can't list codes. Only the function reads them.
alter table public.coupons enable row level security;

drop function public.book_appointment(
  text,text,text,text[],timestamptz,int,int,int,int,int,text,text);

create function public.book_appointment(
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
  v_row public.appointments;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if p_start < now() then raise exception 'in_past'; end if;
  if p_payment_method <> 'Pay at salon' then raise exception 'bad_payment'; end if;

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
    p_id, auth.uid(), p_branch_name, v_stylist, v_name, v_names,
    p_start, v_end, v_duration, v_subtotal, v_discount, v_tax,
    v_subtotal - v_discount + v_tax,
    p_payment_method, upper(nullif(btrim(p_coupon), ''))
  ) returning * into v_row;

  return v_row;
exception when exclusion_violation then
  get stacked diagnostics v_constraint = constraint_name;
  if v_constraint = 'no_user_overlap' then raise exception 'user_overlap'; end if;
  raise exception 'slot_taken';
end;
$$;

revoke all on function public.book_appointment(text,text,text,text[],timestamptz,text,text) from public, anon;
grant execute on function public.book_appointment(text,text,text,text[],timestamptz,text,text) to authenticated;