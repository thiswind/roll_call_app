import 'package:flutter/material.dart';

import 'course.dart';

/// 个人中心页：教师信息 + 当前课程信息。
class ProfilePage extends StatelessWidget {
  final Course course;
  final VoidCallback onBack;

  const ProfilePage({super.key, required this.course, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: '返回课程列表',
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  course.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(
                    (course.teacher.isEmpty ? '师' : course.teacher.characters.first),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w400),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                    course.teacher.isEmpty ? '任课教师' : course.teacher,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  course.unit.isEmpty ? '开课单位' : course.unit,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('当前课程', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            color: colorScheme.surfaceContainerLow,
            elevation: 0,
            child: Column(
              children: [
                _buildRow(context, '课程名称', course.name),
                Divider(height: 1, color: colorScheme.outlineVariant),
                _buildRow(context, '课程号', course.code.isEmpty ? '—' : course.code),
                Divider(height: 1, color: colorScheme.outlineVariant),
                _buildRow(
                    context, '学年学期', course.term.isEmpty ? '—' : course.term),
                Divider(height: 1, color: colorScheme.outlineVariant),
                _buildRow(context, '学生人数', '${course.students.length}人'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '名册存在手机本地，无需联网',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
