-- Tạo bảng personal_topics cho TV4
CREATE TABLE personal_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  objectives TEXT,
  field TEXT,
  technologies TEXT,
  implementation_plan TEXT,
  status TEXT NOT NULL DEFAULT 'Ý tưởng',
  source TEXT NOT NULL DEFAULT 'manual',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Bật bảo mật phân quyền RLS
ALTER TABLE personal_topics ENABLE ROW LEVEL SECURITY;

-- Chính sách: Sinh viên chỉ quản lý đề tài cá nhân của mình
CREATE POLICY "Sinh vien chi quan ly de tai ca nhan cua minh"
ON personal_topics
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);