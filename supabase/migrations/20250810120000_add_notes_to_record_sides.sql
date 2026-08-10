-- Add optional notes per side (existing projects).
alter table public.record_sides
  add column if not exists notes text;
