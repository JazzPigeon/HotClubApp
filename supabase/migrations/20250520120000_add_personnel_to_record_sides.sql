-- Add optional personnel per side (existing projects).
alter table public.record_sides
  add column if not exists personnel text;
