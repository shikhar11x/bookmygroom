create extension if not exists pg_cron;

alter table public.appointments add column reminder_sent_at timestamptz;

create function public.send_due_reminders()
returns int
language plpgsql security definer set search_path = ''
as $$
declare
  r public.appointments;
  n int := 0;
begin
  for r in
    select * from public.appointments
    where status = 'confirmed'
      and reminder_sent_at is null
      and start_at between now() + interval '50 minutes'
                       and now() + interval '65 minutes'
    for update skip locked
  loop
    update public.appointments
       set reminder_sent_at = now()
     where id = r.id;

    perform net.http_post(
      url := 'https://faqkzzyalqwpqhnnluqa.supabase.co/functions/v1/send-push',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-push-secret', 'REPLACE_WITH_PUSH_SECRET'
      ),
      body := jsonb_build_object(
        'op', 'REMINDER',
        'record', to_jsonb(r),
        'old_record', null
      )
    );
    n := n + 1;
  end loop;
  return n;
end;
$$;

-- Only the scheduler (and you, in the SQL Editor) may run this.
revoke all on function public.send_due_reminders() from public, anon, authenticated;

select cron.schedule(
  'send-reminders',
  '*/5 * * * *',
  $$ select public.send_due_reminders(); $$
);