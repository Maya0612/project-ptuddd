# Nhóm 14 – 65KTPM: Hệ Thống Hỗ Trợ Định Hướng Và Chuẩn Bị Đồ Án Tốt Nghiệp Cho Sinh Viên

## 1. Giới Thiệu Đề Tài

- **Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD)
- **Giảng viên hướng dẫn:** ThS. Đỗ Oanh Cường
- **Repository nhóm:** `Maya0612/project-ptuddd`
- **Nhánh tích hợp chung:** `nhom14-65ktpm` *(không phát triển trực tiếp trên `main` hoặc `nhom14-65ktpm`)*
- **Công nghệ chính:** Flutter (ứng dụng di động đa nền tảng), Supabase (Auth, PostgreSQL, RLS, Edge Functions), tích hợp AI API qua backend/Edge Function.
- **Mục tiêu tổng quát:** Xây dựng một hệ thống đa nền tảng hỗ trợ sinh viên chủ động định hướng và chuẩn bị thực hiện đồ án tốt nghiệp thông qua việc tra cứu dữ liệu đồ án các khóa trước, sử dụng AI để tham khảo và đối chiếu hướng đề tài, quản lý đề tài cá nhân và lập kế hoạch học tập, thực hiện.

---

## 2. Tài Liệu Thành Viên Cần Đọc Trước (Theo Thứ Tự)

Toàn bộ thành viên mới tham gia hoặc chuẩn bị bắt đầu code cần đọc lần lượt các tài liệu sau:

1. **[`danhsachnhom.md`](./danhsachnhom.md)** – Thông tin nhóm, phân công nhiệm vụ chính thức từng module, danh sách bảng CSDL và hướng dẫn cài đặt môi trường.
2. **[`docs/GIT_WORKFLOW.md`](./docs/GIT_WORKFLOW.md)** – **Tài liệu bắt buộc:** Quy ước 5 branch cố định, quy trình Git/GitHub 7 bước (Pull, Commit, PR, Review, Merge, Sync), quy tắc Issue & Project Board, và quy ước thiết kế CSDL & RLS trên Supabase.
3. **[`../README.md`](../README.md)** – Quy định chung của giảng viên về cấu trúc thư mục và nộp bài học phần *(chỉ đọc để tuân thủ, không chỉnh sửa)*.

---

## 3. Tóm Tắt Phân Công Và Branch Cá Nhân Cố Định

> Mọi branch cá nhân đều tách từ `nhom14-65ktpm` và mọi Pull Request đều đặt **Base branch là `nhom14-65ktpm`**. Không xóa branch cá nhân sau khi Merge.

| Mã TV | Thành Viên | Branch Cá Nhân Cố Định | Module & Bảng CSDL Chính |
| :---: | --- | --- | --- |
| **TV1** | Đào Hà Thu (Trưởng nhóm) | `feature/tv1-foundation-auth` | Kiến trúc, Flutter & Supabase, Auth, `profiles`, RLS nền tảng, tổng hợp schema & tích hợp |
| **TV2** | Phạm Kim Anh | `feature/tv2-project-repository` | Kho đồ án (`projects`, `fields`, `favorites`), tìm kiếm/lọc, yêu thích, đề xuất & Admin/GV duyệt |
| **TV3** | Trần Đức Trung | `feature/tv3-ai-suggestions` | AI gợi ý (3–5 đề tài) & đối chiếu kho đã duyệt qua backend/Edge Function, xử lý lỗi API |
| **TV4** | Trịnh Mạnh Đức | `feature/tv4-personal-topics` | Quản lý đề tài cá nhân (`personal_topics`), CRUD từ ý tưởng/AI, phân quyền theo sinh viên |
| **TV5** | Vương Tiến Dũng | `feature/tv5-planning-progress` | Lập kế hoạch & tiến độ (`plans`, `tasks`), đầu việc/thời hạn/trạng thái, liên kết đề tài cá nhân |

Chi tiết nhiệm vụ từng thành viên xem tại [`danhsachnhom.md`](./danhsachnhom.md).

---

## 4. Cấu Trúc Thư Mục Nhóm

```text
nhom14-65ktpm/
├── README.md                  # Trang tổng quan dự án và chỉ mục tài liệu của nhóm
├── danhsachnhom.md            # Thông tin thành viên, phân công chính thức và hướng dẫn chạy app
├── docs/                      # Tài liệu quy trình, thiết kế và báo cáo đồ án
│   ├── GIT_WORKFLOW.md        # Hướng dẫn Git/GitHub, Issue/Project Board và quy ước CSDL
│   └── ...                    # (Báo cáo đồ án baocao_doan.pdf sẽ được bổ sung tại đây)
└── src/                       # Toàn bộ mã nguồn ứng dụng Flutter
    ├── android/
    ├── ios/
    ├── lib/
    ├── test/
    └── pubspec.yaml
```

---

## 5. Khởi Chạy Nhanh Ứng Dụng Flutter

```bash
# 1. Di chuyển vào thư mục mã nguồn
cd nhom14-65ktpm/src

# 2. Cài đặt dependencies
flutter pub get

# 3. Chạy ứng dụng trên thiết bị/máy ảo đang kết nối
flutter run
```

> **Lưu ý bảo mật:** Không đưa API Key, mật khẩu, hoặc tệp `.env` lên repository. Xem đầy đủ quy định tại [`docs/GIT_WORKFLOW.md`](./docs/GIT_WORKFLOW.md).
