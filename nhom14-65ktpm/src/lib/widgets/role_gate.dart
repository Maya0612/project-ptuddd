import 'package:flutter/widgets.dart';

import '../models/profile.dart';

class RoleGate extends StatelessWidget {
  final UserRole? role;
  final Widget child;
  final Widget fallback;

  const RoleGate({
    super.key,
    required this.role,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final allowed = role == UserRole.lecturer || role == UserRole.admin;
    return allowed ? child : fallback;
  }
}
