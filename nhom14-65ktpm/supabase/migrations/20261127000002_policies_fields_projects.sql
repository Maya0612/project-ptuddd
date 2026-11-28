-- Mọi người đều được tra cứu danh mục lĩnh vực.
drop policy if exists fields_select_public on public.fields;
create policy fields_select_public
  on public.fields for select to public
  using (true);

-- Chỉ staff được thêm lĩnh vực.
drop policy if exists fields_insert_staff on public.fields;
create policy fields_insert_staff
  on public.fields for insert to authenticated
  with check (public.is_staff());

-- Chỉ staff được sửa lĩnh vực.
drop policy if exists fields_update_staff on public.fields;
create policy fields_update_staff
  on public.fields for update to authenticated
  using (public.is_staff())
  with check (public.is_staff());

-- Chỉ staff được xóa lĩnh vực.
drop policy if exists fields_delete_staff on public.fields;
create policy fields_delete_staff
  on public.fields for delete to authenticated
  using (public.is_staff());

-- Khách và người dùng đã đăng nhập chỉ xem được đồ án đã duyệt.
drop policy if exists projects_select_approved_public on public.projects;
create policy projects_select_approved_public
  on public.projects for select to public
  using (status = 'approved'::public.project_status);

-- Sinh viên xem được đề xuất do chính mình gửi.
drop policy if exists projects_select_own on public.projects;
create policy projects_select_own
  on public.projects for select to authenticated
  using (user_id = auth.uid());

-- Staff xem được tất cả đồ án.
drop policy if exists projects_select_staff on public.projects;
create policy projects_select_staff
  on public.projects for select to authenticated
  using (public.is_staff());

-- Chỉ staff được thêm đồ án đã duyệt, gắn với chính staff hoặc không gắn user.
drop policy if exists projects_insert_staff on public.projects;
create policy projects_insert_staff
  on public.projects for insert to authenticated
  with check (
    public.is_staff()
    and status = 'approved'::public.project_status
    and (user_id is null or user_id = auth.uid())
  );

-- Chỉ staff được sửa đồ án.
drop policy if exists projects_update_staff on public.projects;
create policy projects_update_staff
  on public.projects for update to authenticated
  using (public.is_staff())
  with check (public.is_staff());

-- Chỉ staff được xóa đồ án.
drop policy if exists projects_delete_staff on public.projects;
create policy projects_delete_staff
  on public.projects for delete to authenticated
  using (public.is_staff());
