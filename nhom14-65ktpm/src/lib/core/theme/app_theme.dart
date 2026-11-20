import 'package:flutter/material.dart';

/// Hệ thống màu chủ đạo chuẩn hóa của toàn bộ ứng dụng Nhóm 14.
/// 
/// 4 mã màu bắt buộc:
/// - [primaryBackground]: #EBEAFF (Nền chính)
/// - [secondary]: #9694FF (Màu phụ / viền nhẹ / tương tác phụ)
/// - [primaryAction]: #3D3BF3 (Hành động chính / nút bấm / điểm nhấn)
/// - [danger]: #FF2929 (Cảnh báo / lỗi / trạng thái nguy hiểm / đăng xuất)
class AppColors {
  AppColors._();

  // 4 mã màu chủ đạo theo quy định
  static const Color primaryBackground = Color(0xFFEBEAFF);
  static const Color secondary = Color(0xFF9694FF);
  static const Color primaryAction = Color(0xFF3D3BF3);
  static const Color danger = Color(0xFFFF2929);

  // Màu trung tính bổ trợ cho chữ và bề mặt hiển thị
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E1B4B); // Chữ đậm chính
  static const Color textSecondary = Color(0xFF535086); // Chữ phụ / nhãn
  static const Color textLight = Colors.white; // Chữ trắng trên nền đậm
  static const Color border = Color(0xFFCAC8F4); // Viền mặc định
}

/// Theme dùng chung toàn hệ thống, tuân thủ bảng màu chuẩn hóa.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryAction,
      onPrimary: AppColors.textLight,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textLight,
      error: AppColors.danger,
      onError: AppColors.textLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.primaryBackground,
      outline: AppColors.secondary,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.primaryBackground,

      // Cấu hình AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryAction,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textLight),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
      ),

      // Nút bấm chính (FilledButton)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryAction,
          foregroundColor: AppColors.textLight,
          disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.textLight.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Nút viền (OutlinedButton)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryAction,
          side: const BorderSide(color: AppColors.primaryAction, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Nút chữ (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryAction,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Trường nhập liệu (TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryAction, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.secondary),
        prefixIconColor: AppColors.secondary,
        suffixIconColor: AppColors.secondary,
        errorStyle: const TextStyle(
          color: AppColors.danger,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card hiển thị
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1.5,
        shadowColor: AppColors.primaryAction.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 15,
          color: AppColors.textSecondary,
        ),
      ),

      // SnackBar
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryAction,
        foregroundColor: AppColors.textLight,
      ),
    );
  }
}
