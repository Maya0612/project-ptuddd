import 'package:flutter_test/flutter_test.dart';

import 'package:nhom14_app/main.dart';

void main() {
  testWidgets('Hiển thị hướng dẫn khi thiếu cấu hình Supabase', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.textContaining('Thiếu cấu hình Supabase'), findsOneWidget);
  });
}
