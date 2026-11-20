-- Các chỉ mục phục vụ lọc và tìm kiếm đồ án.
create index projects_status_idx       on public.projects (status);
create index projects_field_id_idx     on public.projects (field_id);
create index projects_year_idx         on public.projects (year);
create index projects_submitted_by_idx on public.projects (submitted_by);
create index projects_technologies_idx on public.projects using gin (technologies);
create index projects_search_idx       on public.projects
  using gin (to_tsvector('simple', title || ' ' || summary || ' ' || student_name || ' ' || supervisor));

-- Các chỉ mục phục vụ tra cứu danh sách yêu thích.
create index favorites_user_id_idx    on public.favorites (user_id);
create index favorites_project_id_idx on public.favorites (project_id);

-- Bật RLS ngay từ đầu; policy sẽ được viết ở giai đoạn phân quyền.
alter table public.fields    enable row level security;
alter table public.projects  enable row level security;
alter table public.favorites enable row level security;
