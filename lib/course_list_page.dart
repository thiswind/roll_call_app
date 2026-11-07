import 'package:flutter/material.dart';

import 'course.dart';

/// 课程列表页：App 首页。点名册通过系统分享导入（微信/文件 App → 用其他应用打开 → 课堂点名）。
class CourseListPage extends StatefulWidget {
  final void Function(Course course) onOpenCourse;

  const CourseListPage({super.key, required this.onOpenCourse});

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  List<Course> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final courses = await CourseStore.load();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  void _showImportGuide() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('如何导入点名册'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. 在微信或"文件"中打开教务系统导出的点名册（xlsx）'),
            SizedBox(height: 8),
            Text('2. 选择"用其他应用打开"'),
            SizedBox(height: 8),
            Text('3. 选择"课堂点名"即完成导入'),
            SizedBox(height: 12),
            Text('同一门课再次导入会自动更新名册；新课自动新增。',
                style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Course course) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${course.name}」？'),
        content: const Text('仅从手机中移除该课程名册，可随时重新导入。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await CourseStore.remove(course);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('课程点名'),
        actions: [
          IconButton(
            tooltip: '如何导入点名册',
            onPressed: _showImportGuide,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _courses.isEmpty
                ? _buildEmpty(context)
                : _buildList(context, colorScheme),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined,
                size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('还没有课程', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '在微信或"文件"中打开点名册（xlsx），\n选择"用其他应用打开" → "课堂点名"\n即可导入',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _showImportGuide,
              child: const Text('查看导入步骤'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final course in _courses)
          Card(
            color: colorScheme.surfaceContainerLow,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Text(course.name.characters.first),
              ),
              title: Text(course.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                  '${course.term.isEmpty ? '未标注学期' : course.term} · ${course.students.length}人',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: '删除课程',
                icon: Icon(Icons.delete_outline,
                    color: colorScheme.onSurfaceVariant),
                onPressed: () => _confirmDelete(course),
              ),
              onTap: () => widget.onOpenCourse(course),
            ),
          ),
      ],
    );
  }
}
