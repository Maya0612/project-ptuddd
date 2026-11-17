# Danh Sách Thành Viên - Nhóm 14

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** Xây dựng hệ thống hỗ trợ định hướng và chuẩn bị đồ án tốt nghiệp cho sinh viên
- **Mục tiêu tổng quát:** Xây dựng một hệ thống đa nền tảng hỗ trợ sinh viên chủ động định hướng và chuẩn bị thực hiện đồ án tốt nghiệp thông qua việc tra cứu dữ liệu đồ án các khóa trước, sử dụng AI để tham khảo hướng đề tài, quản lý đề tài cá nhân và lập kế hoạch học tập, thực hiện.
- **Giảng viên hướng dẫn:** ThS. Đỗ Oanh Cường

## Bảng Thông Tin Thành Viên

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| :---: | --------- | :----------: | :-----------: | ------- | ------------------- | :----------: | ----- |
| 1 | Đào Hà Thu | 2351170623 | 65KTPM | Trưởng nhóm | Quản lý dự án, backend, điều phối chung | 100% | 2351170623@e.tlu.edu.vn |
| 2 | Phạm Kim Anh | 2351170572 | 65KTPM | Thành viên | Thiết kế giao diện (UI/UX), mobile frontend | 100% | 2351170572@e.tlu.edu.vn |
| 3 | Vương Tiến Dũng | 2351170586 | 65KTPM | Thành viên | Tích hợp AI gợi ý đề tài, phát triển API | 100% | 2351170586@e.tlu.edu.vn |
| 4 | Trịnh Mạnh Đức | 2251243284 | 64KTPM | Thành viên | Module tra cứu dữ liệu đồ án, kiểm thử | 100% | 2251243284@e.tlu.edu.vn |
| 5 | Trần Đức Trung | 2251162191 | 64KTPM | Thành viên | Module quản lý đề tài cá nhân, lập kế hoạch, kiểm thử | 100% | 2251162191@e.tlu.edu.vn |

## Hướng Dẫn Thiết Lập Môi Trường Và Khởi Chạy Ứng Dụng

### 1. Yêu cầu môi trường
- Flutter SDK: version >= 3.0.0
- Dart SDK: version >= 3.0.0
- Android Studio / VS Code (đã cài đặt Flutter & Dart extensions)
- Thiết bị giả lập Android (AVD) hoặc thiết bị thật bật USB Debugging

### 2. Các bước cài đặt và khởi chạy
1. Mở terminal và chuyển vào thư mục chứa mã nguồn:
   ```bash
   cd nhom14-65ktpm/src
   ```
2. Cài đặt các gói phụ thuộc (dependencies):
   ```bash
   flutter pub get
   ```
3. Kiểm tra thiết bị kết nối:
   ```bash
   flutter devices
   ```
4. Khởi chạy ứng dụng:
   ```bash
   flutter run
   ```