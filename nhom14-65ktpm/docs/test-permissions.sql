-- Chỉ chạy thủ công trên môi trường Supabase thử nghiệm đã có dữ liệu fields.
-- Thay các UUID bên dưới bằng ID auth.users thật của từng tài khoản demo.
-- Mọi thay đổi trong script được rollback ở cuối.

begin;

-- Khách chỉ thấy đồ án đã duyệt.
set local role anon;
set local "request.jwt.claims" = '{}';
select id, name, status
from public.projects
order by name;
-- Kết quả mong đợi: mọi dòng trả về đều có status = approved.

-- Sinh viên thấy đồ án đã duyệt và các dòng do chính mình gửi.
set local role authenticated;
set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000003","role":"authenticated"}';
select id, name, status, user_id
from public.projects
order by name;
-- Kết quả mong đợi: approved hoặc user_id là UUID của sinh viên.

-- Sinh viên không được INSERT đồ án.
do $$
declare
  field_uuid uuid;
begin
  select id into field_uuid from public.fields order by name limit 1;
  if field_uuid is null then
    raise exception 'Cần có ít nhất một lĩnh vực để chạy kiểm thử';
  end if;
  insert into public.projects
    (name, summary, student_name, supervisor, year, field_id, technologies, status)
  values
    ('Kiểm thử student', 'Tóm tắt', 'Sinh viên', 'Giảng viên', 2026,
     field_uuid, array['Flutter'], 'approved');
  raise exception 'FAIL: student đã INSERT được projects';
exception
  when insufficient_privilege then
    raise notice 'PASS: student không được INSERT projects';
end
$$;

-- Sinh viên không được UPDATE hoặc DELETE đồ án.
do $$
declare
  affected integer;
begin
  update public.projects
  set summary = summary
  where user_id = auth.uid();
  get diagnostics affected = row_count;
  if affected <> 0 then
    raise exception 'FAIL: student đã UPDATE được projects';
  end if;

  delete from public.projects where user_id = auth.uid();
  get diagnostics affected = row_count;
  if affected <> 0 then
    raise exception 'FAIL: student đã DELETE được projects';
  end if;
  raise notice 'PASS: student không được UPDATE/DELETE projects';
end
$$;

-- Sinh viên không được tự đổi role thành admin.
do $$
declare
  blocked boolean := false;
begin
  begin
    update public.profiles
    set role = 'admin'::public.user_role
    where id = auth.uid();
  exception
    when others then
      blocked := true;
  end;
  if not blocked then
    raise exception 'FAIL: student đã tự đổi role thành admin';
  end if;
  raise notice 'PASS: student không thể tự đổi role';
end
$$;

-- Giảng viên xem được mọi trạng thái và CRUD được projects.
set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}';
select id, name, status
from public.projects
order by name;
-- Kết quả mong đợi: lecturer thấy pending, approved và rejected.
do $$
declare
  field_uuid uuid;
  project_uuid uuid;
  affected integer;
begin
  select id into field_uuid from public.fields order by name limit 1;
  if field_uuid is null then
    raise exception 'Cần có ít nhất một lĩnh vực để chạy kiểm thử';
  end if;
  insert into public.projects
    (name, summary, student_name, supervisor, year, field_id, technologies, status)
  values
    ('Kiểm thử lecturer', 'Tóm tắt', 'Sinh viên', 'Giảng viên', 2026,
     field_uuid, array['Flutter'], 'approved')
  returning id into project_uuid;
  update public.projects
  set summary = 'Đã cập nhật bởi lecturer'
  where id = project_uuid;
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'FAIL: lecturer không UPDATE được projects';
  end if;
  delete from public.projects where id = project_uuid;
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'FAIL: lecturer không DELETE được projects';
  end if;
  raise notice 'PASS: lecturer có quyền CRUD projects';
end
$$;

-- Admin xem được mọi trạng thái và CRUD được projects.
set local "request.jwt.claims" =
  '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}';
select id, name, status
from public.projects
order by name;
-- Kết quả mong đợi: admin thấy pending, approved và rejected.
do $$
declare
  field_uuid uuid;
  project_uuid uuid;
  affected integer;
begin
  select id into field_uuid from public.fields order by name limit 1;
  if field_uuid is null then
    raise exception 'Cần có ít nhất một lĩnh vực để chạy kiểm thử';
  end if;
  insert into public.projects
    (name, summary, student_name, supervisor, year, field_id, technologies, status)
  values
    ('Kiểm thử admin', 'Tóm tắt', 'Sinh viên', 'Giảng viên', 2026,
     field_uuid, array['Flutter'], 'approved')
  returning id into project_uuid;
  update public.projects
  set summary = 'Đã cập nhật bởi admin'
  where id = project_uuid;
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'FAIL: admin không UPDATE được projects';
  end if;
  delete from public.projects where id = project_uuid;
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'FAIL: admin không DELETE được projects';
  end if;
  raise notice 'PASS: admin có quyền CRUD projects';
end
$$;

rollback;
