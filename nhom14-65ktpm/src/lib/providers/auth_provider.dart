import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _authSubscription = supabase.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.signedOut) {
          profile = null;
          errorMessage = null;
          isLoading = false;
          notifyListeners();
        } else if (!isLoading) {
          unawaited(refresh());
        }
      },
      onError: (Object _) {
        errorMessage = 'Không thể cập nhật trạng thái đăng nhập';
        isLoading = false;
        notifyListeners();
      },
    );
    unawaited(refresh());
  }

  final AuthService _service;
  late final StreamSubscription<AuthState> _authSubscription;

  UserProfile? profile;
  bool isLoading = true;
  String? errorMessage;

  bool get isAuthenticated => supabase.auth.currentUser != null;
  bool get isStaff => profile?.isStaff ?? false;

  /// Đồng bộ hồ sơ và vai trò theo phiên Supabase hiện tại.
  Future<void> refresh() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      profile = await _service.getProfile();
      if (isAuthenticated && profile == null) {
        errorMessage = 'Không tìm thấy hồ sơ người dùng';
      }
    } on PostgrestException {
      profile = null;
      errorMessage = 'Không thể tải hồ sơ người dùng';
    } catch (_) {
      profile = null;
      errorMessage = 'Không thể tải hồ sơ người dùng';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng nhập và tải role từ bảng profiles.
  Future<bool> signIn(String email, String password) async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.signIn(email.trim(), password);
      profile = await _service.getProfile();
      if (profile == null) {
        errorMessage = 'Không tìm thấy hồ sơ người dùng';
        return false;
      }
      return true;
    } on AuthException {
      errorMessage = 'Email hoặc mật khẩu không đúng';
      return false;
    } on PostgrestException {
      errorMessage = 'Đăng nhập được nhưng không thể tải hồ sơ người dùng';
      return false;
    } catch (_) {
      errorMessage = 'Không thể đăng nhập. Vui lòng thử lại';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng xuất phiên Supabase hiện tại.
  Future<bool> signOut() async {
    if (isLoading) return false;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _service.signOut();
      profile = null;
      return true;
    } on AuthException {
      errorMessage = 'Không thể đăng xuất. Vui lòng thử lại';
      return false;
    } catch (_) {
      errorMessage = 'Không thể đăng xuất. Vui lòng thử lại';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}
