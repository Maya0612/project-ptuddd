-- Bảng lĩnh vực phân loại đồ án.
create table public.fields (
  id          bigint generated always as identity primary key,
  name        text not null unique,
  description text,
  created_at  timestamptz not null default now()
);
