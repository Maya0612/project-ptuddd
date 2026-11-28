# Module 3 – AI Gợi ý và Đối chiếu Đề tài



**Thành viên phụ trách:** Trần Đức Trung – TV3  

**Branch:** `feature/tv3-ai-suggestions`  

**Phạm vi:** AI gợi ý đề tài, đối chiếu kho đồ án đã duyệt và tích hợp AI API.



## 1. Giới thiệu



Module 3 hỗ trợ sinh viên định hướng đề tài tốt nghiệp dựa trên sở thích, kỹ năng và công nghệ mà sinh viên quan tâm.



Hệ thống sử dụng AI API thông qua Backend hoặc Supabase Edge Function để đề xuất từ 3–5 hướng đề tài phù hợp. Đồng thời, hệ thống đối chiếu các đề tài được đề xuất với dữ liệu đồ án đã được duyệt trong kho đồ án của hệ thống.



AI chỉ đóng vai trò tham khảo và hỗ trợ định hướng, không thay thế việc đánh giá hoặc phê duyệt đề tài chính thức.



## 2. Phạm vi chức năng



Module 3 bao gồm các chức năng chính:



- Tiếp nhận sở thích, kỹ năng và công nghệ quan tâm của sinh viên.

- Thiết kế cấu trúc dữ liệu đầu vào và đầu ra cho AI.

- Tích hợp AI API thông qua Backend hoặc Supabase Edge Function.

- Đề xuất từ 3–5 hướng đề tài dựa trên thông tin sinh viên cung cấp.

- Cung cấp mô tả, mục tiêu và phương pháp thực hiện cho từng đề tài.

- Đối chiếu đề tài được đề xuất với dữ liệu đồ án đã được duyệt.

- Cảnh báo những đề tài có nội dung tương đồng.

- Xử lý lỗi API và các trường hợp dữ liệu không hợp lệ.



### Giới hạn phạm vi



- Không xây dựng chatbot đa năng.

- Không huấn luyện mô hình AI riêng.

- Không để AI tự động phê duyệt đề tài.

- Không tự ý thay đổi Database dùng chung của nhóm.



## 3. Thiết kế dữ liệu đầu vào (Input)



Sinh viên nhập thông tin trên giao diện Flutter. Backend tiếp nhận và kiểm tra dữ liệu trước khi gửi yêu cầu đến AI API.



Các nhóm thông tin đầu vào:



| Thông tin | Mô tả |

|---|---|

| Sở thích (interests) | Những lĩnh vực sinh viên quan tâm |

| Kỹ năng (skills) | Ngôn ngữ lập trình và kỹ năng chuyên môn |

| Công nghệ (technologies) | Framework, công cụ và nền tảng đã biết hoặc muốn sử dụng |

| Mô tả (description) | Mong muốn và định hướng đề tài của sinh viên |



### Ví dụ cấu trúc JSON đầu vào



```json

{

&#x20; "interests": [

&#x20;   "Trí tuệ nhân tạo",

&#x20;   "Phát triển ứng dụng"

&#x20; ],

&#x20; "skills": [

&#x20;   "Flutter",

&#x20;   "Dart",

&#x20;   "SQL"

&#x20; ],

&#x20; "technologies": [

&#x20;   "Supabase",

&#x20;   "Firebase"

&#x20; ],

&#x20; "description": "Muốn phát triển ứng dụng hỗ trợ sinh viên có tích hợp AI"

}

```



Đây là cấu trúc đề xuất ban đầu để TV3 và TV1 thống nhất trước khi triển khai API chính thức.



## 4. Thiết kế dữ liệu đầu ra (Output)



AI cần trả về danh sách từ 3–5 đề tài gợi ý.



Mỗi đề tài dự kiến bao gồm:



| Thông tin | Mô tả |

|---|---|

| title | Tên đề tài được đề xuất |

| description | Mô tả tổng quan về đề tài |

| objectives | Mục tiêu cần đạt được |

| methodology | Phương pháp thực hiện |

| field | Lĩnh vực chuyên môn liên quan |

| technologies | Danh sách công nghệ dự kiến sử dụng |



### Ví dụ cấu trúc JSON đầu ra



```json

{

&#x20; "suggestions": [

&#x20;   {

&#x20;     "title": "Xây dựng ứng dụng quản lý chi tiêu cá nhân tích hợp AI",

&#x20;     "description": "Ứng dụng hỗ trợ quản lý thu chi và phân tích thói quen tài chính.",

&#x20;     "objectives": "Quản lý thu chi, thống kê và hỗ trợ phân tích chi tiêu.",

&#x20;     "methodology": "Phân tích yêu cầu, xây dựng ứng dụng và tích hợp AI.",

&#x20;     "field": "Phát triển phần mềm",

&#x20;     "technologies": [

&#x20;       "Flutter",

&#x20;       "Supabase",

&#x20;       "Python"

&#x20;     ]

&#x20;   }

&#x20; ]

}

```



Đây là dữ liệu minh họa cho một đề tài, không phải kết quả AI thực tế. Cấu trúc Output chính thức cần được thống nhất giữa TV3 và TV1 trước khi tích hợp.



## 5. Luồng xử lý nghiệp vụ



Quy trình xử lý dự kiến:



1\. Sinh viên nhập sở thích, kỹ năng và công nghệ quan tâm trên Flutter.

2\. Flutter gửi dữ liệu đến Backend hoặc Supabase Edge Function.

3\. Backend kiểm tra và chuẩn hóa dữ liệu đầu vào.

4\. Backend truy vấn kho đồ án đã được duyệt từ bảng `projects` của TV2.

5\. Backend gửi yêu cầu đến AI API để tạo các đề tài gợi ý.

6\. Hệ thống thực hiện đối chiếu nội dung đề tài với dữ liệu đồ án đã duyệt.

7\. Backend tổng hợp kết quả và trả về Flutter.

8\. Flutter hiển thị các đề tài gợi ý và cảnh báo tương đồng.

9\. Khi sinh viên lựa chọn đề tài, thông tin được chuyển sang TV4 để lưu vào `personal_topics`.



## 6. Sử dụng cơ sở dữ liệu



Module 3 ưu tiên sử dụng lại cấu trúc Database hiện có của hệ thống.



| Bảng | Thành viên quản lý | Mục đích sử dụng |

|---|---|---|

| `profiles` | TV1 | Thông tin tài khoản khi cần thiết |

| `projects` | TV2 | Truy xuất đồ án đã được duyệt để đối chiếu |

| `fields` | TV2 | Tham khảo và phân loại lĩnh vực |

| `personal_topics` | TV4 | Tiếp nhận đề tài được sinh viên lựa chọn |



### Nguyên tắc sử dụng Database



- Không tạo bảng CSDL mới cho Module 3 trong phạm vi hiện tại.

- Không tự ý thêm cột vào các bảng của thành viên khác.

- Chỉ truy xuất các đồ án đã được duyệt để phục vụ đối chiếu.

- Không lưu dữ liệu đầu vào và kết quả AI tạm thời vào Database.

- Khi sinh viên lựa chọn đề tài, chuyển thông tin sang Module 4 để TV4 xử lý và lưu trữ.



Trường hợp phát sinh yêu cầu lưu lịch sử gợi ý AI, TV3 sẽ đề xuất bảng `ai_suggestions` và phối hợp với TV1 đánh giá trước khi thực hiện. Đây không phải yêu cầu bắt buộc của phiên bản hiện tại.



## 7. Đối chiếu với kho đồ án



Mục tiêu của chức năng này là giúp sinh viên nhận biết những đề tài có nội dung tương đồng với các đồ án đã được thực hiện trước đó.



Nguồn dữ liệu đối chiếu:



- Tên đồ án (`name`).

- Tóm tắt nội dung (`summary`).

- Lĩnh vực (`field_id`).

- Công nghệ sử dụng (`technologies`).



Quy trình đối chiếu:



1\. Tiếp nhận danh sách đề tài do AI đề xuất.

2\. Truy xuất các đồ án có trạng thái đã được duyệt từ bảng `projects`.

3\. Thu thập thông tin cần thiết để so sánh.

4\. Đánh giá mức độ tương đồng dựa trên nội dung và lĩnh vực.

5\. Trả về những đồ án có nội dung tương đồng cùng thông tin giải thích.

6\. Hiển thị cảnh báo để sinh viên tham khảo và điều chỉnh đề tài.



Phương pháp tính điểm tương đồng và ngưỡng cảnh báo cần được thống nhất trong quá trình triển khai. Không mặc định một ngưỡng điểm hoặc thuật toán cụ thể khi chưa được nhóm thống nhất.



## 8. Xử lý lỗi và dữ liệu không hợp lệ



Module 3 cần xem xét các trường hợp sau:



| Tình huống | Hướng xử lý |

|---|---|

| Thiếu thông tin đầu vào | Yêu cầu sinh viên bổ sung |

| Dữ liệu sai định dạng | Kiểm tra và từ chối yêu cầu không hợp lệ |

| AI API không phản hồi | Thông báo lỗi và hỗ trợ thử lại |

| AI trả về dữ liệu không đúng định dạng | Kiểm tra và xử lý hoặc từ chối kết quả |

| Không tìm thấy đồ án tương đồng | Thông báo chưa tìm thấy kết quả phù hợp |

| Không có đồ án đã được duyệt | Thông báo chưa có dữ liệu để đối chiếu |

| AI trả về ít hơn số lượng đề tài yêu cầu | Kiểm tra kết quả và xử lý theo quy tắc đã thống nhất |



Không tự tạo kết quả đối chiếu hoặc điểm tương đồng khi hệ thống chưa thực hiện được việc kiểm tra.



## 9. Bảo mật



- AI API Key phải được lưu trong môi trường server-side.

- Không nhúng khóa bí mật vào mã nguồn Flutter.

- Các yêu cầu AI cần được xử lý thông qua Backend hoặc Supabase Edge Function.

- Tuân thủ cơ chế xác thực và phân quyền của hệ thống.

- Chỉ truy xuất dữ liệu đồ án được phép sử dụng.

- Tuân thủ chính sách RLS và quy định bảo mật chung của nhóm.



## 10. Phối hợp với các thành viên



| Thành viên | Nội dung phối hợp |

|---|---|

| TV1 – Đào Hà Thu | Thống nhất API, kiến trúc Backend, bảo mật khóa AI và quy tắc truy cập dữ liệu |

| TV2 – Phạm Kim Anh | Thống nhất cấu trúc bảng `projects`, `fields` và điều kiện truy xuất đồ án đã duyệt |

| TV4 – Trịnh Mạnh Đức | Thống nhất cách chuyển đề tài AI được lựa chọn sang `personal_topics` |

| TV5 – Vương Tiến Dũng | Phối hợp khi đề tài cá nhân được lựa chọn để lập kế hoạch thực hiện |



## 11. Tiêu chí hoàn thành Module 3



- [ ] Tiếp nhận được thông tin sở thích, kỹ năng và công nghệ.

- [ ] Kiểm tra và xử lý dữ liệu đầu vào không hợp lệ.

- [ ] Tích hợp AI API qua Backend hoặc Edge Function.

- [ ] AI trả về từ 3–5 đề tài theo cấu trúc thống nhất.

- [ ] Mỗi đề tài có mô tả, mục tiêu và phương pháp thực hiện.

- [ ] Truy xuất được dữ liệu đồ án đã được duyệt.

- [ ] Thực hiện đối chiếu và hiển thị cảnh báo tương đồng.

- [ ] Xử lý được lỗi API và kết quả không hợp lệ.

- [ ] Chuyển được đề tài sinh viên lựa chọn sang Module 4.

- [ ] Đảm bảo bảo mật khóa API và dữ liệu hệ thống.



---



**Ghi chú:** Tài liệu này mô tả phạm vi và thiết kế ban đầu của Module 3. Các cấu trúc API, thuật toán đối chiếu và phương thức tích hợp cụ thể cần được thống nhất với các thành viên liên quan trước khi triển khai.
