import 'package:flutter/material.dart';

import '../models/project.dart';

class StatusChip extends StatelessWidget {
  final ProjectStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final values = switch (status) {
      ProjectStatus.pending => ('Chờ duyệt', colors.secondary),
      ProjectStatus.approved => ('Đã duyệt', colors.primary),
      ProjectStatus.rejected => ('Bị từ chối', colors.error),
    };
    return Chip(
      label: Text(values.$1),
      labelStyle: TextStyle(
        color: values.$2,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: values.$2),
      backgroundColor: colors.surface,
      visualDensity: VisualDensity.compact,
    );
  }
}
