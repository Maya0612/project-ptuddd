import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/main.dart';

void main() {
  testWidgets('App renders LoginScreen by default', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hệ Thống Hỗ Trợ Đồ Án'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
