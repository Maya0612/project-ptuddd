# Quy Trình Làm Việc Git/GitHub, Issue, Project Board Và CSDL – Nhóm 14

Tài liệu này là **bộ hướng dẫn thống nhất duy nhất** áp dụng cho toàn bộ 5 thành viên Nhóm 14 (65KTPM) khi làm việc trên dự án **Hệ thống hỗ trợ định hướng và chuẩn bị đồ án tốt nghiệp cho sinh viên**.

---

## 1. Thông Tin Repository Và Vai Trò Các Nhánh

- **Repository làm việc của nhóm:** `Maya0612/project-ptuddd`
- **Nhánh tích hợp chung của nhóm:** `nhom14-65ktpm`
- **Nhánh `main`:** **Không sử dụng** làm nhánh phát triển trực tiếp của nhóm. Nhánh `main` luôn được giữ nguyên đồng bộ với kho gốc của giảng viên (`oanhcuongdo/project-ptuddd`).

```text
nhom14-65ktpm  (Nhánh tích hợp chung của nhóm — Base branch cho mọi PR nội bộ)
   ├── feature/nhom14/foundation-auth       (TV1 – Đào Hà Thu)
   ├── feature/nhom14/project-repository    (TV2 – Phạm Kim Anh)
   ├── feature/nhom14/ai-suggestions        (TV3 – Trần Đức Trung)
   ├── feature/nhom14/personal-topics       (TV4 – Trịnh Mạnh Đức)
   └── feature/nhom14/planning-progress     (TV5 – Vương Tiến Dũng)
```

---

## 2. Quy Ước Branch Cá Nhân Chính Thức

Mỗi thành viên sử dụng **duy nhất 01 branch cá nhân cố định** được tách ra từ nhánh `nhom14-65ktpm`:

| Thành Viên | Mã TV | Branch Cá Nhân Cố Định | Module Phụ Trách |
| --- | :---: | --- | --- |
| Đào Hà Thu (Trưởng nhóm) | TV1 | `feature/nhom14/foundation-auth` | Kiến trúc, Flutter & Supabase, Auth, `profiles`, RLS nền tảng, tích hợp |
| Phạm Kim Anh | TV2 | `feature/nhom14/project-repository` | Kho đồ án (`projects`, `fields`, `favorites`), tìm kiếm/lọc, yêu thích, đề xuất & duyệt |
| Trần Đức Trung | TV3 | `feature/nhom14/ai-suggestions` | AI gợi ý (3–5 đề tài) & đối chiếu kho đã duyệt qua backend/Edge Function |
| Trịnh Mạnh Đức | TV4 | `feature/nhom14/personal-topics` | Quản lý đề tài cá nhân (`personal_topics`), CRUD, lưu từ ý tưởng/AI, phân quyền |
| Vương Tiến Dũng | TV5 | `feature/nhom14/planning-progress` | Lập kế hoạch & theo dõi tiến độ (`plans`, `tasks`), liên kết đề tài cá nhân |

### Quy định bắt buộc về Branch
- Mỗi thành viên **chỉ làm việc trên branch được chỉ định** của mình.
- **Không** code trực tiếp trên nhánh `main`.
- **Không** code trực tiếp trên nhánh `nhom14-65ktpm`.
- **Không** tự ý đổi tên branch.
- **Không** sử dụng chung một branch cá nhân cho nhiều thành viên.
- Mỗi thành viên **tự commit và push bằng tài khoản GitHub cá nhân của mình**.
- Tất cả branch cá nhân đều phải được tạo từ nhánh `nhom14-65ktpm`.
- Mọi Pull Request của thành viên phải đặt **Base branch là `nhom14-65ktpm`** (tuyệt đối không tạo PR trực tiếp từ branch cá nhân vào `main`).

---

## 3. Chuẩn Bị Lần Đầu Trên Máy Cá Nhân

Thực hiện **một lần duy nhất** sau khi đã chấp nhận lời mời Collaborator vào repository `Maya0612/project-ptuddd`:

```bash
# 1. Cấu hình danh tính Git (email phải trùng với email đăng ký tài khoản GitHub)
git config --global user.name "Họ và Tên Của Bạn"
git config --global user.email "email_github_cua_ban@example.com"

# 2. Tải repository của nhóm về máy
git clone https://github.com/Maya0612/project-ptuddd.git
cd project-ptuddd

# 3. Chuyển sang nhánh tích hợp chung của nhóm
git checkout --track origin/nhom14-65ktpm
```

---

## 4. Quy Trình Git/GitHub 7 Bước Bắt Buộc

### Bước 1: Đồng bộ nhánh tích hợp (`nhom14-65ktpm`)

Trước khi bắt đầu phiên làm việc hoặc lấy các cập nhật mới nhất mà nhóm đã Merge:

```bash
git fetch origin
git checkout nhom14-65ktpm
git pull origin nhom14-65ktpm
```

*Giải thích lệnh:*
- `git fetch origin`: Lấy thông tin nhánh và commit mới nhất từ GitHub về máy (chưa tự động gộp vào code đang sửa).
- `git checkout nhom14-65ktpm`: Chuyển sang nhánh tích hợp chung của nhóm.
- `git pull origin nhom14-65ktpm`: Cập nhật nhánh `nhom14-65ktpm` trên máy khớp hoàn toàn với phiên bản mới nhất trên GitHub.

### Bước 2: Chuyển sang branch cá nhân

Nếu branch cá nhân **đã có** trên máy:

```bash
# Ví dụ cho TV2 (thay bằng đúng tên branch của bạn tại Mục 2)
git checkout feature/nhom14/project-repository
```

Nếu branch cá nhân **đã có trên GitHub nhưng chưa có trên máy**:

```bash
git fetch origin
git checkout --track origin/feature/nhom14/project-repository
```

Nếu branch cá nhân **chưa tồn tại trên cả máy và GitHub**, tạo mới từ nhánh tích hợp `nhom14-65ktpm`:

```bash
git checkout nhom14-65ktpm
git pull origin nhom14-65ktpm
git checkout -b feature/nhom14/project-repository
git push -u origin feature/nhom14/project-repository
```

*Giải thích lệnh:*
- `git checkout -b <ten-branch>`: Tạo một branch mới tại vị trí hiện tại (`nhom14-65ktpm`) và chuyển sang làm việc trên branch đó.
- `git push -u origin <ten-branch>`: Đẩy branch vừa tạo lên GitHub và thiết lập liên kết theo dõi (`-u` / upstream) để các lần sau đẩy code nhanh hơn.

### Bước 3: Code và Commit

**Phạm vi thay đổi:** Chỉ chỉnh sửa các file thuộc phạm vi module được giao và **nằm hoàn toàn trong thư mục `nhom14-65ktpm/`**. Không sửa `README.md` hoặc `.gitignore` ở thư mục gốc của kho lưu trữ.

Trước khi commit, luôn kiểm tra những file vừa thay đổi:

```bash
git status
```

Sau khi kiểm tra thấy **chỉ có các file hợp lệ trong `nhom14-65ktpm/`**, tiến hành đưa vào staging, commit và push:

```bash
# Đưa toàn bộ thay đổi đã kiểm tra vào staging
git add .
# (Khuyến nghị an toàn theo quy định học phần khi đứng ở thư mục gốc project-ptuddd:
#  dùng `git add nhom14-65ktpm/` để chắc chắn không đưa nhầm file ngoài thư mục nhóm)

# Tạo commit với mô tả cụ thể
git commit -m "feat: implement project search and filter screen"

# Đẩy commit lên branch cá nhân của bạn trên GitHub
git push origin <ten-branch-ca-nhan>
```

*Giải thích từng lệnh:*
- `git status`: Hiển thị nhánh đang đứng và danh sách file đã sửa/tạo mới/xóa để kiểm tra trước khi đóng gói.
- `git add .` (hoặc `git add nhom14-65ktpm/`): Đưa các file thay đổi vào khu vực chuẩn bị lưu (Staging Area).
- `git commit -m "..."`: Lưu lại một mốc thay đổi (snapshot) vào lịch sử Git cục bộ kèm thông điệp mô tả rõ ràng.
- `git push origin <ten-branch-ca-nhan>`: Gửi các commit mới từ máy bạn lên đúng branch cá nhân trên GitHub.

#### Quy chuẩn Commit Message
- **Bắt buộc** nêu rõ loại thay đổi và nội dung cụ thể đã làm.
- **Tuyệt đối không** dùng các thông điệp chung chung như `update`, `fix`, `done`, `test`, `abc`.
- Các tiền tố khuyến nghị:
  - `feat:` Thêm chức năng hoặc màn hình mới (VD: `feat: add favorite toggle for project detail`).
  - `fix:` Sửa lỗi cụ thể (VD: `fix: handle empty response from AI suggestion API`).
  - `docs:` Cập nhật tài liệu (VD: `docs: add database schema proposal for plans and tasks`).
  - `refactor:` Tối ưu cấu trúc code không đổi hành vi (VD: `refactor: extract project card widget`).
  - `chore:` Cấu hình, dọn dẹp (VD: `chore: add env example for supabase config`).

### Bước 4: Tạo Pull Request (PR)

Khi hoàn thành một phần công việc hoặc một chức năng trọn vẹn:

1. Truy cập `https://github.com/Maya0612/project-ptuddd` → tab **Pull requests** → **New pull request**.
2. Kiểm tra kỹ thông tin nhánh:
   - **Base repository:** `Maya0612/project-ptuddd`
   - **Base branch:** `nhom14-65ktpm` *(⚠️ Không chọn `main`)*
   - **Compare branch:** Branch cá nhân của bạn (VD: `feature/nhom14/project-repository`).
3. Điền đầy đủ nội dung mô tả PR theo mẫu sau:

```markdown
## Chức năng đã thực hiện
- Mô tả ngắn gọn các tính năng/thay đổi chính trong PR này.

## Các file quan trọng đã thay đổi
- `nhom14-65ktpm/src/lib/...`

## Cách kiểm thử
1. Bước 1...
2. Bước 2...
3. Kết quả mong đợi...

## Issue liên quan
Refs #<issue_number>
```

4. Gắn **Reviewers** (TV1 hoặc thành viên được phân công review) ở cột bên phải rồi bấm **Create pull request**.
5. Chuyển thẻ Issue tương ứng trên Project Board sang cột **In Review**.

> **Lưu ý:** Không tạo Pull Request trực tiếp từ branch cá nhân vào `main`.

### Bước 5: Review Pull Request

- Người tạo PR **không được tự Approve** PR của chính mình.
- PR bắt buộc phải được **ít nhất 01 thành viên khác có quyền phù hợp** (như Trưởng nhóm TV1 hoặc Reviewer được chỉ định) kiểm tra.
- **Nội dung Reviewer cần kiểm tra:**
  - Logic xử lý và luồng nghiệp vụ có đúng yêu cầu không.
  - Cấu trúc thư mục, đặt tên file/biến, tính dễ đọc.
  - Lỗi biên dịch, lỗi runtime, xử lý trường hợp dữ liệu rỗng/lỗi mạng.
  - Khả năng tương thích với các module khác và schema CSDL chung.
  - Phạm vi thay đổi: có sửa ngoài module được giao hoặc dính file rác (`.env`, build artifacts, file IDE) không.
- **Nếu Reviewer yêu cầu chỉnh sửa (*Request changes*):**
  1. Người tạo PR chỉnh sửa tiếp **ngay trên chính branch cá nhân đó**.
  2. Commit và `git push origin <ten-branch-ca-nhan>` — PR sẽ tự động cập nhật.
  3. Phản hồi lại comment của Reviewer và yêu cầu review lại.
- PR chỉ được phép Merge sau khi đã được **Approve** theo quy định của repository.

### Bước 6: Merge Pull Request

- Chỉ Merge PR vào `nhom14-65ktpm` sau khi đã được chấp thuận (Approve) và **không còn lỗi hay xung đột (conflict)** chưa giải quyết.
- **QUAN TRỌNG — KHÔNG XÓA BRANCH CÁ NHÂN SAU KHI MERGE:**
  - Nhóm sử dụng 5 branch cá nhân cố định theo từng thành viên.
  - Sau khi bấm Merge PR, **không bấm nút "Delete branch"** cho 5 nhánh `feature/tv1-...` đến `feature/tv5-...`.
- Sau khi Merge hoàn tất và xác nhận công việc đạt yêu cầu, cập nhật trạng thái Issue và chuyển thẻ trên Project Board sang **Done**.

### Bước 7: Đồng bộ branch cá nhân sau khi nhóm đã Merge thay đổi mới

Mỗi khi nhánh `nhom14-65ktpm` có PR mới được Merge, trước khi tiếp tục code, mọi thành viên cần cập nhật branch cá nhân của mình theo nhánh tích hợp:

```bash
git fetch origin
git checkout feature/<branch-cua-minh>
git merge origin/nhom14-65ktpm
git push origin feature/<branch-cua-minh>
```

*Giải thích lệnh:*
- `git fetch origin`: Lấy các commit mới nhất trên GitHub về (bao gồm `origin/nhom14-65ktpm`).
- `git checkout feature/<branch-cua-minh>`: Đảm bảo đang đứng đúng trên branch cá nhân.
- `git merge origin/nhom14-65ktpm`: Gộp toàn bộ cập nhật mới từ nhánh tích hợp vào branch cá nhân của bạn.
- `git push origin feature/<branch-cua-minh>`: Đẩy trạng thái đã đồng bộ lên GitHub.

#### Xử lý khi xảy ra Conflict (Xung đột code)
1. Bình tĩnh mở các file bị đánh dấu xung đột (`<<<<<<<`, `=======`, `>>>>>>>`), trao đổi với thành viên liên quan để chọn phần code đúng.
2. Lưu file, chạy kiểm thử ứng dụng (`flutter analyze` / `flutter run`) để chắc chắn không lỗi.
3. Thực hiện `git add nhom14-65ktpm/` → `git commit` → `git push origin feature/<branch-cua-minh>`.
4. **NGHIÊM CẤM:** Không tự ý dùng `git push --force` (`-f`), `git reset --hard` hoặc xóa lịch sử commit để xử lý conflict. Nếu không chắc chắn, hãy dừng lại và báo TV1 hỗ trợ.

---

## 5. Quy Tắc Issue Và Project Board

- Mỗi thành viên được giao các **Issue** tương ứng với phạm vi nhiệm vụ của mình.
- Mỗi Issue bắt buộc có đầy đủ:
  - **Tiêu đề** rõ ràng, ngắn gọn.
  - **Mô tả** mục tiêu và phạm vi công việc.
  - **Checklist** các đầu việc nhỏ (`- [ ] ...`).
  - **Labels** phù hợp (VD: `feature`, `bug`, `database`, `ui`, `ai`, `docs`).
  - **Assignee** (người chịu trách nhiệm chính).
- **Project Board** sử dụng cố định 4 cột trạng thái:
  1. **Todo:** Công việc đã lên kế hoạch, chưa bắt đầu.
  2. **In Progress:** Thành viên đã bắt đầu thực hiện.
  3. **In Review:** Đã hoàn thành code, đã tạo Pull Request (có gắn `Refs #<issue_number>`) và đang chờ Review.
  4. **Done:** Pull Request đã được **Merge** vào `nhom14-65ktpm` và công việc đã được xác nhận hoàn thành.
- **Quy tắc nghiêm ngặt:** Không tự ý kéo thẻ sang **Done** chỉ vì đã `git push` code hoặc mới mở PR.

---

## 6. Quy Ước Thiết Kế Cơ Sở Dữ Liệu (Supabase)

Mỗi thành viên chịu trách nhiệm đề xuất thiết kế cấu trúc bảng thuộc module của mình:
- **TV1:** `profiles` (và tổng hợp, rà soát toàn bộ schema + RLS nền tảng).
- **TV2:** `projects`, `fields`, `favorites`.
- **TV3:** Đối chiếu trên dữ liệu `projects` đã được duyệt (và thiết kế cấu trúc dữ liệu I/O cho AI Edge Function).
- **TV4:** `personal_topics`.
- **TV5:** `plans`, `tasks`.

### Quy trình thống nhất trước khi thao tác trên Supabase thật
Trước khi tạo mới hoặc chỉnh sửa bất kỳ bảng nào trên Supabase thật, thành viên **bắt buộc** đề xuất và thống nhất trước với **TV1** đầy đủ 7 nội dung sau:
1. **Tên bảng** (thống nhất đặt tên `snake_case`, số nhiều theo chuẩn PostgreSQL/Supabase).
2. **Tên cột và kiểu dữ liệu**.
3. **Primary Key (PK) và Foreign Key (FK)**.
4. **Quan hệ giữa các bảng** (1-1, 1-N, N-N).
5. **Ràng buộc dữ liệu** (`NOT NULL`, `UNIQUE`, `CHECK`, giá trị mặc định, `ON DELETE`).
6. **Quyền truy cập và chính sách RLS (Row Level Security)** theo từng vai trò (Sinh viên, Admin).
7. **Các thao tác CRUD** cần hỗ trợ từ phía ứng dụng.

- **TV1** chịu trách nhiệm tổng hợp và kiểm tra tính nhất quán của toàn bộ schema trước khi áp dụng.
- **Nghiêm cấm** từng thành viên tự ý tạo bảng hoặc viết chính sách RLS khác nhau trực tiếp trên Supabase gây xung đột khi tích hợp.

---

## 7. Nguyên Tắc Bảo Mật Và Tệp Tin Không Được Commit

- **Tuyệt đối không commit** API Key (AI API Key, Supabase Service Role Key), mật khẩu, thông tin bí mật hoặc file `.env` vào mã nguồn hay tài liệu.
- Không commit các thư mục/tệp tạm và build artifacts: `.dart_tool/`, `build/`, `.gradle/`, `Pods/`, `.idea/`, `.vscode/`, `*.iml`, `*.apk`, `*.aab`, `*.ipa`.
- Không chỉnh sửa các tệp gốc ngoài thư mục nhóm (`README.md`, `.gitignore` ở thư mục gốc `project-ptuddd/`).

---

## 8. Quy Định Nộp Bài Về Kho Giảng Viên

- Trong suốt quá trình phát triển, mọi PR của thành viên chỉ gửi vào `Maya0612/project-ptuddd` nhánh `nhom14-65ktpm`.
- Việc đồng bộ từ `upstream/main` và mở Pull Request nộp bài sang kho gốc của giảng viên (`oanhcuongdo/project-ptuddd`, nhánh `main`) do **Trưởng nhóm (TV1)** đại diện thực hiện từ nhánh `nhom14-65ktpm` theo đúng hướng dẫn tại tệp `README.md` ở thư mục gốc của kho lưu trữ.
