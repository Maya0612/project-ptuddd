-- ==============================================================================
-- Migration: Thiết lập bảng profiles và bảo mật RLS nền tảng
-- Dự án: Hệ Thống Hỗ Trợ Định Hướng Và Chuẩn Bị Đồ Án Tốt Nghiệp Cho Sinh Viên
-- Tác giả: TV1 – Đào Hà Thu (Nhóm 14 - 65KTPM)
-- ==============================================================================

-- 1. Tạo bảng public.profiles liên kết trực tiếp với auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'student' CONSTRAINT check_profiles_role CHECK (role IN ('student', 'lecturer', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ghi chú chú thích cho bảng và các cột
COMMENT ON TABLE public.profiles IS 'Hồ sơ người dùng đồng bộ từ auth.users';
COMMENT ON COLUMN public.profiles.id IS 'Định danh người dùng, khóa ngoại tham chiếu auth.users.id';
COMMENT ON COLUMN public.profiles.full_name IS 'Họ và tên người dùng';
COMMENT ON COLUMN public.profiles.avatar_url IS 'Đường dẫn ảnh đại diện (có thể null)';
COMMENT ON COLUMN public.profiles.role IS 'Phân quyền người dùng: student (mặc định), lecturer, admin';
COMMENT ON COLUMN public.profiles.created_at IS 'Thời điểm tạo hồ sơ';
COMMENT ON COLUMN public.profiles.updated_at IS 'Thời điểm cập nhật hồ sơ gần nhất';

-- 2. Bật Row Level Security (RLS) bắt buộc
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Trigger hàm tự động cập nhật updated_at và chặn tự nâng quyền role
CREATE OR REPLACE FUNCTION public.handle_profile_before_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Nghiêm cấm người dùng tự sửa đổi trường role của chính mình
  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'Người dùng không được phép tự nâng cấp hoặc thay đổi quyền (role)';
  END IF;

  -- Luôn tự động cập nhật updated_at về thời điểm hiện tại
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_profiles_before_update ON public.profiles;
CREATE TRIGGER tr_profiles_before_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_profile_before_update();

-- 4. Trigger hàm tự động tạo hồ sơ profile khi người dùng đăng ký qua auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Khi tài khoản được tạo trong auth.users, tự động tạo 1 bản ghi profile tương ứng
  -- Mặc định role luôn là 'student', không cho phép tự đăng ký với quyền admin hoặc lecturer
  INSERT INTO public.profiles (id, full_name, avatar_url, role, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.raw_user_meta_data->>'avatar_url',
    'student',
    now(),
    now()
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 5. Các chính sách Row Level Security (RLS)
-- Người dùng chỉ được xem hồ sơ của chính mình
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Người dùng chỉ được cập nhật hồ sơ của chính mình
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Không cấp quyền INSERT/DELETE trực tiếp cho người dùng authenticated
-- Việc thêm profile được thực hiện tự động qua trigger SECURITY DEFINER từ auth.users.
-- Việc xóa profile được thực hiện tự động qua ON DELETE CASCADE khi xóa tài khoản trong auth.users.
