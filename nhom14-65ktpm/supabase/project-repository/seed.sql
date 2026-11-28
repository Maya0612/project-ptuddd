-- =====================================================================
-- DỮ LIỆU MẪU (GIẢ) để chạy thử. Dữ liệu đồ án chính thức do giảng viên cung cấp sau.
-- Chạy SAU file 001_core_tables.sql. Có thể chạy lại nhiều lần, không bị trùng.
-- =====================================================================

-- ---------- 4 lĩnh vực ----------
insert into public.fields (name, description) values
  ('Phát triển Web',               'Website, ứng dụng web, thương mại điện tử, hệ thống quản lý trực tuyến'),
  ('Trí tuệ nhân tạo',             'Học máy, học sâu, xử lý ngôn ngữ tự nhiên, thị giác máy tính'),
  ('Hệ thống nhúng/IoT',           'Vi điều khiển, cảm biến, tự động hóa, nhà thông minh'),
  ('Phát triển ứng dụng di động',  'Ứng dụng Android, iOS và đa nền tảng')
on conflict (name) do nothing;

-- ---------- 10 đồ án mẫu: 8 approved, 1 pending, 1 rejected ----------
insert into public.projects
  (title, summary, student_name, supervisor, year, field_id, technologies, status, reject_reason)
select
  v.title, v.summary, v.student_name, v.supervisor, v.year, f.id,
  v.technologies, v.status::public.project_status, v.reject_reason
from (values
  ('Hệ thống quản lý thư viện trực tuyến',
   'Website quản lý mượn trả sách, tra cứu tài liệu và thống kê cho thư viện trường.',
   'Nguyễn Văn An', 'ThS. Trần Minh Quân', 2023, 'Phát triển Web',
   array['Node.js','Express','PostgreSQL','React'], 'approved', null::text),

  ('Website thương mại điện tử bán sách cũ',
   'Nền tảng mua bán sách cũ có giỏ hàng, thanh toán và đánh giá người bán.',
   'Lê Thị Bình', 'TS. Phạm Hoàng Nam', 2024, 'Phát triển Web',
   array['Next.js','Supabase','Tailwind CSS'], 'approved', null),

  ('Hệ thống quản lý đồ án sinh viên',
   'Ứng dụng web hỗ trợ giảng viên giao đề tài, theo dõi tiến độ và chấm điểm đồ án.',
   'Phạm Quốc Cường', 'ThS. Đỗ Thu Hà', 2025, 'Phát triển Web',
   array['Laravel','MySQL','Bootstrap'], 'approved', null),

  ('Nhận diện biển số xe bằng học sâu',
   'Phát hiện và đọc biển số xe từ ảnh, video camera với mô hình YOLO và OCR.',
   'Hoàng Đức Dũng', 'TS. Phạm Hoàng Nam', 2023, 'Trí tuệ nhân tạo',
   array['Python','PyTorch','OpenCV','YOLO'], 'approved', null),

  ('Chatbot hỗ trợ tư vấn tuyển sinh',
   'Chatbot trả lời câu hỏi tuyển sinh bằng tiếng Việt dựa trên xử lý ngôn ngữ tự nhiên.',
   'Vũ Thị Lan', 'TS. Nguyễn Hải Đăng', 2024, 'Trí tuệ nhân tạo',
   array['Python','Transformers','FastAPI'], 'approved', null),

  ('Hệ thống giám sát môi trường nhà kính',
   'Đo nhiệt độ, độ ẩm, ánh sáng và tự động điều khiển quạt, đèn, tưới nước.',
   'Đặng Minh Khoa', 'ThS. Lý Văn Thắng', 2024, 'Hệ thống nhúng/IoT',
   array['ESP32','MQTT','C++','Node-RED'], 'approved', null),

  ('Hệ thống nhà thông minh điều khiển qua điện thoại',
   'Điều khiển thiết bị điện trong nhà từ xa, đặt lịch và nhận cảnh báo cháy.',
   'Bùi Thanh Mai', 'ThS. Lý Văn Thắng', 2025, 'Hệ thống nhúng/IoT',
   array['Arduino','Wi-Fi','Firebase','C++'], 'approved', null),

  ('Ứng dụng quản lý chi tiêu cá nhân',
   'Ứng dụng di động ghi chép thu chi, đặt ngân sách và vẽ biểu đồ thống kê.',
   'Ngô Gia Huy', 'ThS. Đỗ Thu Hà', 2025, 'Phát triển ứng dụng di động',
   array['Flutter','Dart','SQLite'], 'approved', null),

  -- Đề xuất đang chờ duyệt (submitted_by để trống; sau khi có tài khoản sinh viên,
  -- cập nhật bằng: update public.projects set submitted_by = '<uuid user>' where title = '...';)
  ('Ứng dụng học từ vựng tiếng Anh bằng flashcard',
   'Ứng dụng di động học từ vựng theo phương pháp lặp lại ngắt quãng, có nhắc nhở hằng ngày.',
   'Trịnh Anh Tuấn', 'ThS. Đỗ Thu Hà', 2025, 'Phát triển ứng dụng di động',
   array['React Native','Expo','Supabase'], 'pending', null),

  -- Đề xuất bị từ chối (bắt buộc có lý do)
  ('Website giới thiệu cá nhân',
   'Trang web giới thiệu bản thân với vài trang tĩnh.',
   'Lương Văn Sơn', 'TS. Phạm Hoàng Nam', 2022, 'Phát triển Web',
   array['HTML','CSS'], 'rejected',
   'Nội dung quá đơn giản, chưa đủ quy mô và tính mới của một đồ án tốt nghiệp.')
) as v(title, summary, student_name, supervisor, year, field_name, technologies, status, reject_reason)
join public.fields f on f.name = v.field_name
where not exists (select 1 from public.projects p where p.title = v.title);

-- ---------- Kiểm tra nhanh ----------
select f.name as linh_vuc, p.status, count(*) as so_do_an
from public.projects p
join public.fields f on f.id = p.field_id
group by f.name, p.status
order by f.name, p.status;
