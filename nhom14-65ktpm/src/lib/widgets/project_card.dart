import 'package:flutter/material.dart';

import '../models/project.dart';
import 'status_chip.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fieldName = project.field?['name'] as String?;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Sinh viên: ${project.studentName}'),
              Text('GVHD: ${project.supervisor}'),
              Text('Năm: ${project.year}'),
              if (fieldName != null) Text('Lĩnh vực: $fieldName'),
              if (project.technologies.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: project.technologies
                      .map(
                        (item) => Chip(
                          label: Text(item),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
