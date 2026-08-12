-- Ensure authenticated users can delete their own records and sides.
grant select, insert, update, delete on table public.records to authenticated;
grant select, insert, update, delete on table public.record_sides to authenticated;

drop policy if exists "records_delete_own" on public.records;
create policy "records_delete_own"
  on public.records for delete
  to authenticated
  using (user_id = auth.uid());

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
