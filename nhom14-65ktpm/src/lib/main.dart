import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'screens/project_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isInitialized) {
      return MaterialApp(
        title: 'Kho đồ án',
        theme: AppTheme.lightTheme,
        home: const _ConfigurationRequiredScreen(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: MaterialApp(
        title: 'Kho đồ án',
        theme: AppTheme.lightTheme,
        home: const _AppHome(),
      ),
    );
  }
}

class _AppHome extends StatelessWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => ProjectListScreen(
        role: auth.profile?.role,
        isAuthenticated: auth.isAuthenticated,
      ),
    );
  }
}

class _ConfigurationRequiredScreen extends StatelessWidget {
  const _ConfigurationRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Thiếu cấu hình Supabase. Khởi chạy với SUPABASE_URL và '
            'SUPABASE_ANON_KEY trong env.json, sau đó chạy với '
            '--dart-define-from-file=env.json.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
