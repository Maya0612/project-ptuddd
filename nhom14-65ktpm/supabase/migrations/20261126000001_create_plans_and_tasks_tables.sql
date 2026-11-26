-- ==============================================================================
-- Migration: Thiết lập bảng plans, tasks và bảo mật RLS cho Module Kế hoạch
-- Dự án: Hệ Thống Hỗ Trợ Định Hướng Và Chuẩn Bị Đồ Án Tốt Nghiệp Cho Sinh Viên
-- Tác giả: TV5 – Vương Tiến Dũng (Nhóm 14 - 65KTPM)
-- Lưu ý: Chạy sau migration tạo bảng public.personal_topics (TV4)
-- ==============================================================================

-- 1. Tạo bảng public.plans (Kế hoạch thực hiện đề tài)
CREATE TABLE IF NOT EXISTS public.plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  personal_topic_id UUID NOT NULL REFERENCES public.personal_topics(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
  description TEXT DEFAULT NULL,
  start_date DATE DEFAULT NULL,
  end_date DATE DEFAULT NULL,
  status TEXT NOT NULL DEFAULT 'active' CONSTRAINT check_plans_status CHECK (status IN ('active', 'completed', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT check_plans_date_range CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE public.plans IS 'Danh sách kế hoạch thực hiện đồ án gắn với đề tài cá nhân';
COMMENT ON COLUMN public.plans.id IS 'Mã định danh kế hoạch';
COMMENT ON COLUMN public.plans.user_id IS 'Mã người dùng sở hữu kế hoạch, tham chiếu auth.users(id)';
COMMENT ON COLUMN public.plans.personal_topic_id IS 'Mã đề tài cá nhân liên kết, tham chiếu public.personal_topics(id)';
COMMENT ON COLUMN public.plans.title IS 'Tiêu đề kế hoạch';
COMMENT ON COLUMN public.plans.description IS 'Mô tả mục tiêu kế hoạch';
COMMENT ON COLUMN public.plans.start_date IS 'Ngày bắt đầu dự kiến';
COMMENT ON COLUMN public.plans.end_date IS 'Ngày kết thúc dự kiến';
COMMENT ON COLUMN public.plans.status IS 'Trạng thái kế hoạch: active, completed hoặc archived';
COMMENT ON COLUMN public.plans.created_at IS 'Thời điểm tạo kế hoạch';
COMMENT ON COLUMN public.plans.updated_at IS 'Thời điểm cập nhật kế hoạch gần nhất';

-- 2. Tạo bảng public.tasks (Danh mục công việc chi tiết theo giai đoạn)
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES public.plans(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  phase TEXT NOT NULL CHECK (length(btrim(phase)) > 0),
  title TEXT NOT NULL CHECK (length(btrim(title)) > 0),
  description TEXT DEFAULT NULL,
  due_date DATE DEFAULT NULL,
  status TEXT NOT NULL DEFAULT 'todo' CONSTRAINT check_tasks_status CHECK (status IN ('todo', 'in_progress', 'done')),
  order_index INTEGER NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ DEFAULT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.tasks IS 'Danh sách công việc chi tiết thuộc từng kế hoạch';
COMMENT ON COLUMN public.tasks.id IS 'Mã định danh công việc';
COMMENT ON COLUMN public.tasks.plan_id IS 'Mã kế hoạch chứa công việc, tham chiếu public.plans(id)';
COMMENT ON COLUMN public.tasks.user_id IS 'Mã người dùng sở hữu công việc, tham chiếu auth.users(id)';
COMMENT ON COLUMN public.tasks.phase IS 'Giai đoạn thực hiện (ví dụ: Khảo sát, Thiết kế, Lập trình, Báo cáo)';
COMMENT ON COLUMN public.tasks.title IS 'Tên công việc';
COMMENT ON COLUMN public.tasks.description IS 'Mô tả chi tiết công việc';
COMMENT ON COLUMN public.tasks.due_date IS 'Hạn hoàn thành công việc';
COMMENT ON COLUMN public.tasks.status IS 'Trạng thái: todo, in_progress hoặc done';
COMMENT ON COLUMN public.tasks.order_index IS 'Thứ tự sắp xếp công việc trong giai đoạn';
COMMENT ON COLUMN public.tasks.completed_at IS 'Thời điểm hoàn thành công việc';
COMMENT ON COLUMN public.tasks.created_at IS 'Thời điểm tạo công việc';
COMMENT ON COLUMN public.tasks.updated_at IS 'Thời điểm cập nhật công việc gần nhất';

-- 3. Tạo Index tối ưu truy vấn
CREATE INDEX IF NOT EXISTS idx_plans_personal_topic_id ON public.plans (personal_topic_id);
CREATE INDEX IF NOT EXISTS idx_plans_user_id ON public.plans (user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_plan_id ON public.tasks (plan_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks (user_id);

-- 4. Trigger tự động cập nhật updated_at và completed_at
CREATE OR REPLACE FUNCTION public.handle_plan_before_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_plans_before_update ON public.plans;
CREATE TRIGGER tr_plans_before_update
  BEFORE UPDATE ON public.plans
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_plan_before_update();

CREATE OR REPLACE FUNCTION public.handle_task_before_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();

  IF NEW.status = 'done' AND OLD.status IS DISTINCT FROM 'done' THEN
    NEW.completed_at = COALESCE(NEW.completed_at, now());
  ELSIF NEW.status <> 'done' THEN
    NEW.completed_at = NULL;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_tasks_before_update ON public.tasks;
CREATE TRIGGER tr_tasks_before_update
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_task_before_update();

-- 5. Bật Row Level Security (RLS) bắt buộc
ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tasks TO authenticated;

-- Chính sách RLS cho bảng plans
DROP POLICY IF EXISTS "Users can view own plans" ON public.plans;
CREATE POLICY "Users can view own plans"
  ON public.plans FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own plans" ON public.plans;
CREATE POLICY "Users can insert own plans"
  ON public.plans FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own plans" ON public.plans;
CREATE POLICY "Users can update own plans"
  ON public.plans FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own plans" ON public.plans;
CREATE POLICY "Users can delete own plans"
  ON public.plans FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Chính sách RLS cho bảng tasks (kiểm tra đồng thời quyền sở hữu task và plan cha)
DROP POLICY IF EXISTS "Users can view own tasks" ON public.tasks;
CREATE POLICY "Users can view own tasks"
  ON public.tasks FOR SELECT TO authenticated
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.plans
      WHERE plans.id = tasks.plan_id AND plans.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can insert own tasks" ON public.tasks;
CREATE POLICY "Users can insert own tasks"
  ON public.tasks FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.plans
      WHERE plans.id = tasks.plan_id AND plans.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
CREATE POLICY "Users can update own tasks"
  ON public.tasks FOR UPDATE TO authenticated
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.plans
      WHERE plans.id = tasks.plan_id AND plans.user_id = auth.uid()
    )
  )
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.plans
      WHERE plans.id = tasks.plan_id AND plans.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can delete own tasks" ON public.tasks;
CREATE POLICY "Users can delete own tasks"
  ON public.tasks FOR DELETE TO authenticated
  USING (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.plans
      WHERE plans.id = tasks.plan_id AND plans.user_id = auth.uid()
    )
  );