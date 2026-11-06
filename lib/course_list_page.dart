import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'course.dart';

/// 课程列表页：App 首页，导入教务系统导出的点名册，按课程进入点名。
class CourseListPage extends StatefulWidget {
  final void Function(Course course) onOpenCourse;

  const CourseListPage({super.key, required this.onOpenCourse});

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  List<Course> _courses = [];
  bool _loading = true;
  bool _importing = false;

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

  Future<void> _importRoster() async {
    if (_importing) return;
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (bytes == null) return;
      final course = parseDmcXlsx(bytes);
      if (course == null) {
        _toast('无法识别：请选择教务系统导出的点名册 xlsx');
        return;
      }
      final replaced = await CourseStore.upsert(course);
      await _reload();
      _toast(replaced
          ? '已更新「${course.name}」名册（${course.students.length}人）'
          : '已导入「${course.name}」（${course.students.length}人）');
    } catch (e) {
      _toast('导入失败：$e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
            tooltip: '导入点名册',
            onPressed: _importing ? null : _importRoster,
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
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
              '点右上角 + 导入教务系统导出的\n点名册（xlsx）即可开始点名',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
