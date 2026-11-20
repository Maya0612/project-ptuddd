import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../main.dart';

/// Màn hình đăng nhập sử dụng Email và Password với Supabase Auth.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Chuyển đổi mã lỗi kỹ thuật từ Supabase / Network thành thông điệp thân thiện với người dùng
  String _getReadableErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials') ||
          error.statusCode == '400') {
        return 'Email hoặc mật khẩu không chính xác. Vui lòng kiểm tra lại.';
      } else if (msg.contains('email not confirmed')) {
        return 'Tài khoản chưa được kích hoạt qua email. Vui lòng kiểm tra hộp thư.';
      } else if (msg.contains('too many requests') ||
          msg.contains('rate limit')) {
        return 'Bạn đã thử đăng nhập quá nhiều lần. Vui lòng thử lại sau ít phút.';
      }
      return 'Đăng nhập không thành công: ${error.message}';
    }

    final errStr = error.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('network') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('clientexception')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.';
    }

    return 'Đã có lỗi xảy ra trong quá trình đăng nhập. Vui lòng thử lại sau.';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleLogin() async {
    // Ngăn chặn gửi yêu cầu liên tục khi đang xử lý
    if (_isLoading) return;

    // Kiểm tra dữ liệu hợp lệ trước khi gọi API
    if (!_formKey.currentState!.validate()) return;

    // Đóng bàn phím ảo
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Text('Đăng nhập thành công!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );

        // Điều hướng vào màn hình chính hiện có và thay thế màn hình đăng nhập
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MyHomePage(
              title: 'Hệ Thống Hỗ Trợ Đồ Án - Nhóm 14',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_getReadableErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(_getReadableErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Biểu tượng ứng dụng
                    Icon(
                      Icons.school_rounded,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề
                    Text(
                      'Hệ Thống Hỗ Trợ Đồ Án',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đăng nhập để tiếp tục',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Trường nhập Email
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'vidu@e.tlu.edu.vn',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Vui lòng nhập địa chỉ email';
                        }
                        // Kiểm tra định dạng email hợp lệ
                        final emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(trimmed)) {
                          return 'Email không hợp lệ (ví dụ: sinhvien@e.tlu.edu.vn)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Trường nhập Password
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          tooltip: _obscurePassword
                              ? 'Hiển thị mật khẩu'
                              : 'Ẩn mật khẩu',
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Nút Đăng nhập
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
