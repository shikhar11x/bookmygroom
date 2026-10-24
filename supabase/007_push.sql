create table public.device_tokens (
  token text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  updated_at timestamptz not null default now()
);
-- No policies on purpose: only the functions below and the server touch it.
alter table public.device_tokens enable row level security;

create function public.register_device_token(p_token text)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  if p_token is null or char_length(p_token) < 20
     or char_length(p_token) > 4096 then
    raise exception 'bad_token';
  end if;
  insert into public.device_tokens (token, user_id)
  values (p_token, auth.uid())
  on conflict (token) do update
    set user_id = auth.uid(), updated_at = now();
end;
$$;

create function public.unregister_device_token(p_token text)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  delete from public.device_tokens
  where token = p_token and user_id = auth.uid();
end;
$$;

revoke all on function public.register_device_token(text) from public, anon;
grant execute on function public.register_device_token(text) to authenticated;
revoke all on function public.unregister_device_token(text) from public, anon;
grant execute on function public.unregister_device_token(text) to authenticated;

create extension if not exists pg_net with schema extensions;

create function public.notify_appointment_change()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform net.http_post(
    url := 'https://faqkzzyalqwpqhnnluqa.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-push-secret', 'REPLACE_WITH_PUSH_SECRET'
    ),
    body := jsonb_build_object(
      'op', TG_OP,
      'record', to_jsonb(new),
      'old_record', case when TG_OP = 'UPDATE' then to_jsonb(old) else null end
    )
  );
  return new;
exception when others then
  return new; -- A notification problem must never block a booking.
end;
$$;

create trigger appointments_push
after insert or update of status on public.appointments
for each row execute function public.notify_appointment_change();