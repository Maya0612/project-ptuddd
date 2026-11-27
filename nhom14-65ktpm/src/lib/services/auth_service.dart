import '../core/supabase_config.dart';
import '../models/profile.dart';

class AuthService {
  /// Tải profile và role của người dùng hiện tại.
  Future<UserProfile?> getProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return data == null ? null : UserProfile.fromJson(data);
  }

  /// Đăng nhập bằng email và mật khẩu Supabase Auth.
  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supabase.auth.signOut();
}
