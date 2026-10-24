-- Realtime: changes to appointments are pushed to subscribed clients (RLS still applies).
alter publication supabase_realtime add table public.appointments;
alter table public.appointments replica identity full;

-- Staff can see all appointments (needed for the queue screen).
create policy "staff read all appointments" on public.appointments
  for select using (
    exists (select 1 from public.staff s where s.user_id = auth.uid())
  );

-- Staff-only status changes. Only forward transitions are allowed.
create function public.set_appointment_status(p_id text, p_status text)
returns public.appointments
language plpgsql security definer set search_path = ''
as $$
declare
  v_from text;
  v_row public.appointments;
begin
  if not exists (select 1 from public.staff where user_id = auth.uid()) then
    raise exception 'not_staff';
  end if;

  if p_status = 'in_service' then v_from := 'checked_in';
  elsif p_status = 'completed' then v_from := 'in_service';
  else raise exception 'bad_status';
  end if;

  update public.appointments
     set status = p_status,
         -- Pay-at-salon bookings are settled at the desk when service completes.
         payment_status = case
           when p_status = 'completed' and payment_status = 'unpaid'
             then 'paid' else payment_status end
   where id = p_id and status = v_from
   returning * into v_row;

  if not found then raise exception 'bad_transition'; end if;
  return v_row;
end;
$$;

-- How many checked-in guests are ahead of this appointment (own bookings only).
create function public.queue_ahead(p_id text)
returns int
language plpgsql stable security definer set search_path = ''
as $$
declare v public.appointments;
begin
  select * into v from public.appointments
  where id = p_id and user_id = auth.uid();
  if not found or v.status <> 'checked_in' then return null; end if;

  return (
    select count(*)::int from public.appointments a
    where a.branch_name = v.branch_name
      and a.status = 'checked_in'
      and a.checked_in_at < v.checked_in_at
      and a.start_at::date = v.start_at::date
  );
end;
$$;

revoke all on function public.set_appointment_status(text,text) from public, anon;
grant execute on function public.set_appointment_status(text,text) to authenticated;
revoke all on function public.queue_ahead(text) from public, anon;
grant execute on function public.queue_ahead(text) to authenticated;