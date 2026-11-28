import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhom14_app/models/profile.dart';
import 'package:nhom14_app/models/project.dart';
import 'package:nhom14_app/widgets/role_gate.dart';

void main() {
  test('Project chuyển đổi JSON với technologies và status', () {
    final project = Project.fromJson({
      'id': '00000000-0000-0000-0000-000000000007',
      'name': 'Ứng dụng quản lý đồ án',
      'summary': 'Tóm tắt',
      'student_name': 'Nguyễn Văn An',
      'supervisor': 'ThS. Đỗ Thu Hà',
      'year': 2026,
      'field_id': '00000000-0000-0000-0000-000000000004',
      'technologies': ['Flutter', 'Supabase'],
      'file_url': null,
      'status': 'approved',
      'user_id': null,
    });

    expect(project.name, 'Ứng dụng quản lý đồ án');
    expect(project.technologies, ['Flutter', 'Supabase']);
    expect(project.status, ProjectStatus.approved);

    final json = project.toJson();
    expect(json['technologies'], ['Flutter', 'Supabase']);
    expect(json['status'], 'approved');
    expect(json['name'], 'Ứng dụng quản lý đồ án');
    expect(json.containsKey('title'), isFalse);
  });

  testWidgets('RoleGate ẩn hiện theo role', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            RoleGate(role: UserRole.student, child: Text('Nút staff')),
            RoleGate(role: UserRole.lecturer, child: Text('Nút giảng viên')),
            RoleGate(role: UserRole.admin, child: Text('Nút quản trị')),
          ],
        ),
      ),
    );

    expect(find.text('Nút staff'), findsNothing);
    expect(find.text('Nút giảng viên'), findsOneWidget);
    expect(find.text('Nút quản trị'), findsOneWidget);
  });
}
