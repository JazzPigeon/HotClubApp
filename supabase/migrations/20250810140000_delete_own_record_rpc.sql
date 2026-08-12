-- Reliable ownership-checked delete that bypasses RLS edge cases.
-- Still only deletes rows owned by auth.uid().

create or replace function public.delete_own_record(p_record_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer;
  owner_id uuid;
  caller_id uuid := auth.uid();
begin
  if caller_id is null then
    raise exception 'Not authenticated';
  end if;

  select user_id into owner_id
  from public.records
  where id = p_record_id;

  if not found then
    raise exception 'Record not found';
  end if;

  if owner_id is distinct from caller_id then
    raise exception 'Record is owned by a different user (owner=%, you=%)', owner_id, caller_id;
  end if;

  delete from public.record_sides
  where record_id = p_record_id;

  delete from public.records
  where id = p_record_id
    and user_id = caller_id;

  get diagnostics deleted_count = row_count;

  if deleted_count = 0 then
    raise exception 'Delete failed unexpectedly';
  end if;
end;
$$;

revoke all on function public.delete_own_record(uuid) from public;
grant execute on function public.delete_own_record(uuid) to authenticated;
