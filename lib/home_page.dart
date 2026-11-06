import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'course.dart';

/// 点名首页：随机点名区 + 学生名册列表（数据来自导入的课程）。
class HomePage extends StatefulWidget {
  final Course course;
  final void Function(Student student) onOpenStudent;

  const HomePage({super.key, required this.course, required this.onOpenStudent});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _random = Random();
  Student? _picked;
  bool _rolling = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Student> get _roster => widget.course.students;

  /// 滚动跳名约 1 秒后定格，仅用 Timer 与 Random 实现。
  void _rollCall() {
    if (_rolling || _roster.isEmpty) return;
    setState(() {
      _rolling = true;
    });
    _timer?.cancel();
    var ticks = 0;
    const totalTicks = 16; // 16 次 × 60ms ≈ 1 秒
    _timer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      ticks++;
      if (ticks >= totalTicks) {
        timer.cancel();
        setState(() {
          _rolling = false;
        });
        return;
      }
      setState(() {
        _picked = _roster[_random.nextInt(_roster.length)];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    final course = widget.course;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: '返回课程列表',
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  '${course.name} · ${course.term.isEmpty ? '本学期' : course.term}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRollCard(context, picked),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('学生名册',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${_roster.length}人',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
            ],
          ),
          ..._roster.map((student) => _buildStudentTile(context, student)),
        ],
      ),
    );
  }

  Widget _buildRollCard(BuildContext context, Student? picked) {
    final colorScheme = Theme.of(context).colorScheme;
    final rolling = _rolling;
    return Card(
      color: colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '今天，谁来回答这个问题？',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                picked == null ? '?' : picked.name.characters.first,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              picked == null
                  ? '点击按钮，随机抽取一位学生'
                  : (rolling ? '点名中…' : picked.name),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              picked == null ? ' ' : picked.id,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _rolling ? null : _rollCall,
              icon: const Icon(Icons.casino),
              label: Text(rolling ? '点名中…' : '随机点名'),
            ),
            if (picked != null && !rolling) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => widget.onOpenStudent(picked),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('查看学生详情'),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(BuildContext context, Student student) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        child: Text(student.name.characters.first),
      ),
      title: Text(student.name),
      subtitle: Text(student.id),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => widget.onOpenStudent(student),
    );
  }
}
