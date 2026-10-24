create table public.loyalty_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  appointment_id text unique references public.appointments(id) on delete set null,
  points int not null,
  reason text not null,
  created_at timestamptz not null default now()
);

alter table public.loyalty_ledger enable row level security;
-- Read-only for users. Points are written only by the trigger below.
create policy "read own ledger" on public.loyalty_ledger
  for select using (auth.uid() = user_id);

create function public.award_points()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare v_points int;
begin
  if new.status = 'completed' and old.status is distinct from 'completed' then
    v_points := floor((new.subtotal - new.discount) / 100.0)::int;
    if v_points > 0 then
      insert into public.loyalty_ledger (user_id, appointment_id, points, reason)
      values (new.user_id, new.id, v_points, 'Completed visit')
      on conflict (appointment_id) do nothing;
    end if;
  end if;
  return new;
end;
$$;

create trigger appointments_award_points
after update of status on public.appointments
for each row execute function public.award_points();

-- Backfill visits that were already completed.
insert into public.loyalty_ledger (user_id, appointment_id, points, reason)
select user_id, id, floor((subtotal - discount) / 100.0)::int, 'Completed visit'
from public.appointments
where status = 'completed' and floor((subtotal - discount) / 100.0) > 0
on conflict (appointment_id) do nothing;