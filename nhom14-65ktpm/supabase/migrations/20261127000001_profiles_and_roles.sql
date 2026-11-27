-- Tạo kiểu vai trò dùng chung cho hồ sơ người dùng.
do $$
begin
  create type public.user_role as enum ('student', 'lecturer', 'admin');
exception
  when duplicate_object then null;
end
$$;

-- Tạo hồ sơ cho người dùng nếu bảng chưa tồn tại.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role public.user_role not null default 'student',
  created_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists full_name text,
  add column if not exists email text,
  add column if not exists role public.user_role default 'student',
  add column if not exists created_at timestamptz default now();

-- Chuyển role từ text nếu bảng profiles cũ đã được tạo trước migration này.
alter table public.profiles
  drop constraint if exists check_profiles_role;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'role'
      and udt_name <> 'user_role'
  ) then
    alter table public.profiles
      alter column role drop default;
    alter table public.profiles
      alter column role type public.user_role
      using role::text::public.user_role;
  end if;
end
$$;

update public.profiles set role = 'student' where role is null;
update public.profiles set created_at = now() where created_at is null;
alter table public.profiles
  alter column role set default 'student',
  alter column role set not null,
  alter column created_at set default now(),
  alter column created_at set not null;

-- Tạo hồ sơ student tự động khi người dùng đăng ký qua Supabase Auth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data->>'full_name', ''),
      nullif(new.raw_user_meta_data->>'name', '')
    ),
    new.email,
    'student'::public.user_role
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Trả về vai trò của phiên hiện tại mà không để RLS gây truy vấn đệ quy.
create or replace function public.current_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid();
$$;

-- Kiểm tra người dùng hiện tại có vai trò giảng viên hoặc quản trị viên.
create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    public.current_role() in (
      'lecturer'::public.user_role,
      'admin'::public.user_role
    ),
    false
  );
$$;

-- Chặn người dùng tự đổi vai trò; chỉ admin được đổi vai trò người khác.
create or replace function public.protect_profile_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role and auth.uid() is not null then
    if auth.uid() = old.id then
      raise exception 'Không được tự thay đổi vai trò của chính mình';
    end if;
    if public.current_role() is distinct from 'admin'::public.user_role then
      raise exception 'Chỉ admin mới được thay đổi vai trò';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_protect_role on public.profiles;
create trigger profiles_protect_role
  before update on public.profiles
  for each row execute function public.protect_profile_role();

alter table public.profiles enable row level security;

-- Người dùng đã đăng nhập chỉ được đọc hồ sơ của mình.
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
  on public.profiles for select to authenticated
  using (id = auth.uid());

-- Staff được đọc tất cả hồ sơ.
drop policy if exists profiles_select_staff on public.profiles;
create policy profiles_select_staff
  on public.profiles for select to authenticated
  using (public.is_staff());

-- Người dùng chỉ được sửa dữ liệu hồ sơ của mình; trigger giữ role bất biến.
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
  on public.profiles for update to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

-- Chỉ admin được cập nhật hồ sơ của người dùng khác.
drop policy if exists profiles_update_admin on public.profiles;
create policy profiles_update_admin
  on public.profiles for update to authenticated
  using (public.current_role() = 'admin'::public.user_role)
  with check (public.current_role() = 'admin'::public.user_role);
