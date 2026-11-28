-- Bảng thông tin đồ án và quy trình duyệt đề xuất.
create table public.projects (
  id            bigint generated always as identity primary key,
  title         text not null,
  summary       text not null,
  student_name  text not null,
  supervisor    text not null,                       -- giảng viên hướng dẫn
  year          int  not null check (year between 2000 and 2100),
  field_id      bigint not null
                references public.fields(id) on delete restrict,
  technologies  text[] not null default '{}',        -- ví dụ {Node.js,PostgreSQL}
  file_url      text,

  -- Quy trình duyệt đề xuất
  status        public.project_status not null default 'pending',
  submitted_by  uuid references auth.users(id) on delete set null, -- null = giảng viên/admin nhập trực tiếp
  reviewed_by   uuid references auth.users(id) on delete set null,
  reviewed_at   timestamptz,
  reject_reason text,

  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),

  -- Bị từ chối thì bắt buộc có lý do
  constraint rejected_needs_reason
    check (status <> 'rejected' or length(btrim(coalesce(reject_reason, ''))) > 0)
);

create trigger projects_set_updated_at
  before update on public.projects
  for each row execute function public.set_updated_at();
