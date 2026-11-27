# Tài khoản demo

Tạo ba tài khoản trên **Supabase Dashboard → Authentication → Users**:

| Vai trò | Email |
|---|---|
| Admin | `admin@demo.com` |
| Lecturer | `lecturer@demo.com` |
| Student | `student@demo.com` |

Đặt mật khẩu tùy ý, tối thiểu 6 ký tự. Không ghi mật khẩu thật vào tài liệu hoặc mã nguồn.

Sau khi tạo xong tài khoản, chạy từng câu SQL sau trong SQL Editor:

```sql
update public.profiles set role = 'admin'::public.user_role
where email = 'admin@demo.com';

update public.profiles set role = 'lecturer'::public.user_role
where email = 'lecturer@demo.com';

update public.profiles set role = 'student'::public.user_role
where email = 'student@demo.com';
```
