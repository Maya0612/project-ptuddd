import 'package:flutter/material.dart';
import 'core/supabase_config.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase Client đúng một lần duy nhất trước runApp
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ Thống Hỗ Trợ Đồ Án - Nhóm 14',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Future<Map<String, dynamic>>? _connectionFuture;

  @override
  void initState() {
    super.initState();
    _connectionFuture = SupabaseConfig.checkConnection();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Thẻ hiển thị trạng thái kết nối Supabase
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud_sync, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            'Trạng thái kết nối Supabase',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      FutureBuilder<Map<String, dynamic>>(
                        future: _connectionFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text('Đang kiểm tra kết nối...'),
                              ],
                            );
                          }

                          final data = snapshot.data;
                          final isConnected = data?['connected'] == true;
                          final message = data?['message'] ?? 'Chưa xác định';
                          final needsMigration = data?['needs_migration'] == true;

                          Color statusColor = Colors.red;
                          IconData statusIcon = Icons.error_outline;

                          if (isConnected && !needsMigration) {
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle_outline;
                          } else if (needsMigration) {
                            statusColor = Colors.orange;
                            statusIcon = Icons.warning_amber_rounded;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isConnected ? 'Đã kết nối máy chủ' : 'Chưa kết nối',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                message,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Số lần bạn đã bấm nút:'),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
