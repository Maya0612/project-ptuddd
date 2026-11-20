import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme/app_theme.dart';
import '../main.dart';
import 'login_screen.dart';

/// Cổng kiểm soát và điều hướng xác thực (AuthGate):
/// - Kiểm tra trạng thái xác thực khi ứng dụng khởi động.
/// - Nếu có phiên hợp lệ (Session != null), chuyển đến màn hình chính (MyHomePage).
/// - Nếu chưa đăng nhập hoặc phiên không hợp lệ/hết hạn, chuyển đến màn hình đăng nhập (LoginScreen).
/// - Theo dõi luồng sự kiện onAuthStateChange của Supabase Auth để phản hồi tức thì.
/// - Hiển thị màn hình chờ (SplashLoadingView) trong quá trình khôi phục phiên để tránh nháy màn hình.
/// - Tận dụng cơ chế lưu trữ phiên tự động trong SharedPreferences của supabase_flutter.
/// - Hủy subscription thích hợp trong dispose() để tránh rò rỉ bộ nhớ.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = true;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    // Đảm bảo hiển thị SplashLoadingView trong khung hình đầu tiên, tránh nhấp nháy giao diện
    await Future.microtask(() {});

    if (!mounted) return;

    // Xử lý an toàn nếu Supabase chưa được cấu hình (ví dụ: môi trường test không có env.json)
    if (!SupabaseConfig.isInitialized) {
      if (mounted) {
        setState(() {
          _session = null;
          _isLoading = false;
        });
      }
      return;
    }

    // Đăng ký listener duy nhất theo dõi thay đổi phiên (đăng nhập, đăng xuất, token refresh)
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _session = data.session;
        _isLoading = false;
      });

      // Nếu đang có route phụ/dialog được push phía trên, đóng lại để về root
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    // Đọc phiên đăng nhập hiện tại từ bộ nhớ đệm của Supabase Client
    Session? currentSession = supabase.auth.currentSession;

    // Nếu phiên đã hết hạn, cố gắng làm mới phiên
    if (currentSession != null && currentSession.isExpired) {
      try {
        final res = await supabase.auth.refreshSession();
        currentSession = res.session;
      } catch (_) {
        currentSession = null;
      }
    }

    if (mounted) {
      setState(() {
        _session = currentSession;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Hủy subscription khi widget bị hủy để tránh rò rỉ tài nguyên
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashLoadingView();
    }

    if (_session != null) {
      return const MyHomePage(
        title: 'Hệ Thống Hỗ Trợ Đồ Án - Nhóm 14',
      );
    }

    return const LoginScreen();
  }
}

/// Màn hình chờ hiển thị trong khi kiểm tra phiên đăng nhập ban đầu.
/// Tuân thủ hệ thống màu chuẩn hóa:
/// - Primary background: #EBEAFF
/// - Secondary: #9694FF
/// - Primary action: #3D3BF3
class SplashLoadingView extends StatelessWidget {
  const SplashLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAction.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 44,
                color: AppColors.primaryAction,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hệ Thống Hỗ Trợ Đồ Án',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang kiểm tra phiên đăng nhập...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
