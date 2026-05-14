-- 78 rpm catalog: records + sides, RLS, private Storage bucket.
-- Apply in Supabase SQL Editor or via supabase db push.

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

create table if not exists public.records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.record_sides (
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references public.records (id) on delete cascade,
  side text not null check (side in ('A', 'B')),
  song_title text,
  artist text,
  composer text,
  label text,
  year integer,
  image_storage_path text,
  unique (record_id, side)
);

create index if not exists record_sides_record_id_idx on public.record_sides (record_id);

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------

create or replace function public.handle_records_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_records_updated on public.records;
create trigger on_records_updated
  before update on public.records
  for each row
  execute function public.handle_records_updated_at();

-- ---------------------------------------------------------------------------
-- Row Level Security: records
-- ---------------------------------------------------------------------------

alter table public.records enable row level security;

drop policy if exists "records_select_own" on public.records;
create policy "records_select_own"
  on public.records for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "records_insert_own" on public.records;
create policy "records_insert_own"
  on public.records for insert
  to authenticated
  with check (user_id = auth.uid());

drop policy if exists "records_update_own" on public.records;
create policy "records_update_own"
  on public.records for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "records_delete_own" on public.records;
create policy "records_delete_own"
  on public.records for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Row Level Security: record_sides (via parent record ownership)
-- ---------------------------------------------------------------------------

alter table public.record_sides enable row level security;

drop policy if exists "record_sides_select_own" on public.record_sides;
create policy "record_sides_select_own"
  on public.record_sides for select
  to authenticated
  using (
    exists (
      select 1 from public.records r
      where r.id = record_sides.record_id and r.user_id = auth.uid()
    )
  );

drop policy if exists "record_sides_insert_own" on public.record_sides;
create policy "record_sides_insert_own"
  on public.record_sides for insert
  to authenticated
  with check (
    exists (
      select 1 from public.records r
      where r.id = record_sides.record_id and r.user_id = auth.uid()
    )
  );

drop policy if exists "record_sides_update_own" on public.record_sides;
create policy "record_sides_update_own"
  on public.record_sides for update
  to authenticated
  using (
    exists (
      select 1 from public.records r
      where r.id = record_sides.record_id and r.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.records r
      where r.id = record_sides.record_id and r.user_id = auth.uid()
    )
  );

drop policy if exists "record_sides_delete_own" on public.record_sides;
create policy "record_sides_delete_own"
  on public.record_sides for delete
  to authenticated
  using (
    exists (
      select 1 from public.records r
      where r.id = record_sides.record_id and r.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- Storage (private bucket + policies: first path segment = auth.uid())
-- ---------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('record-images', 'record-images', false)
on conflict (id) do nothing;

drop policy if exists "record_images_select" on storage.objects;
create policy "record_images_select"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'record-images'
    and (storage.foldername (name)) [1] = auth.uid()::text
  );

drop policy if exists "record_images_insert" on storage.objects;
create policy "record_images_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'record-images'
    and (storage.foldername (name)) [1] = auth.uid()::text
  );

drop policy if exists "record_images_update" on storage.objects;
create policy "record_images_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'record-images'
    and (storage.foldername (name)) [1] = auth.uid()::text
  )
  with check (
    bucket_id = 'record-images'
    and (storage.foldername (name)) [1] = auth.uid()::text
  );

drop policy if exists "record_images_delete" on storage.objects;
create policy "record_images_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'record-images'
    and (storage.foldername (name)) [1] = auth.uid()::text
  );
