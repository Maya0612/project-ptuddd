-- Bảng đồ án yêu thích của sinh viên.
create table public.favorites (
  id         bigint generated always as identity primary key,
  user_id    uuid   not null references auth.users(id)       on delete cascade,
  project_id bigint not null references public.projects(id)  on delete cascade,
  created_at timestamptz not null default now(),
  constraint favorites_user_project_unique unique (user_id, project_id)
);
