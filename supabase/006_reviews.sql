create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  appointment_id text not null unique
    references public.appointments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  stylist_id text not null,
  service_rating smallint not null check (service_rating between 1 and 5),
  stylist_rating smallint not null check (stylist_rating between 1 and 5),
  comment text check (comment is null or char_length(comment) <= 500),
  photo_path text,
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

-- Users read only their own reviews. No insert policy: writes use submit_review().
create policy "read own reviews" on public.reviews
  for select using (auth.uid() = user_id);

create function public.submit_review(
  p_appointment_id text, p_service_rating int, p_stylist_rating int,
  p_comment text, p_photo_path text
) returns public.reviews
language plpgsql security definer set search_path = ''
as $$
declare
  v public.appointments;
  v_row public.reviews;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;

  select * into v from public.appointments
  where id = p_appointment_id and user_id = auth.uid();
  if not found then raise exception 'not_found'; end if;
  if v.status <> 'completed' then raise exception 'not_completed'; end if;

  if p_service_rating not between 1 and 5
     or p_stylist_rating not between 1 and 5 then
    raise exception 'bad_rating';
  end if;
  if p_photo_path is not null
     and split_part(p_photo_path, '/', 1) <> auth.uid()::text then
    raise exception 'bad_photo';
  end if;

  insert into public.reviews (
    appointment_id, user_id, stylist_id, service_rating, stylist_rating,
    comment, photo_path
  ) values (
    p_appointment_id, auth.uid(), v.stylist_id, p_service_rating,
    p_stylist_rating, nullif(btrim(p_comment), ''), p_photo_path
  ) returning * into v_row;

  return v_row;
exception when unique_violation then
  raise exception 'already_reviewed';
end;
$$;

-- Average stylist rating from verified reviews only.
create function public.stylist_ratings()
returns table (stylist_id text, average numeric, review_count int)
language sql stable security definer set search_path = ''
as $$
  select stylist_id,
         round(avg(stylist_rating)::numeric, 1),
         count(*)::int
  from public.reviews
  group by stylist_id;
$$;

revoke all on function public.submit_review(text,int,int,text,text) from public, anon;
grant execute on function public.submit_review(text,int,int,text,text) to authenticated;
revoke all on function public.stylist_ratings() from public, anon;
grant execute on function public.stylist_ratings() to authenticated;

-- Private photo bucket: 3 MB, images only, each user writes/reads only their own folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('review-photos', 'review-photos', false, 3145728,
        array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "upload own review photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'review-photos'
              and (storage.foldername(name))[1] = auth.uid()::text);

create policy "read own review photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'review-photos'
         and (storage.foldername(name))[1] = auth.uid()::text);