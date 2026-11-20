-- Kiểu trạng thái đồ án: chờ duyệt, được duyệt hoặc bị từ chối.
create type public.project_status as enum ('pending', 'approved', 'rejected');

-- Hàm tự cập nhật updated_at khi bản ghi được cập nhật.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
