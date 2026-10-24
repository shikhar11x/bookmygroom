create table public.staff (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'reception'
);
alter table public.staff enable row level security;
-- A user can only see their own staff row. Nobody can write from the app.
create policy "read own staff row" on public.staff
  for select using (auth.uid() = user_id);

alter table public.appointments add column checked_in_at timestamptz;