import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'course.dart';
import 'course_list_page.dart';
import 'detail_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

void main() {
  runApp(const RollCallApp());
}

class RollCallApp extends StatelessWidget {
  const RollCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '课堂点名',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
      ),
      home: const RootPage(),
    );
  }
}

/// 根页面：课程列表 → 课程内（点名 / 我的）两级结构。
/// 支持从微信等 App 分享 xlsx 点名册进来（冷启动与运行中均可）。
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  Course? _course;
  int _index = 0; // 0 点名 1 我的
  Student? _selectedStudent;
  bool _showDetail = false;

  @override
  void initState() {
    super.initState();
    _initSharing();
  }

  Future<void> _initSharing() async {
    // 冷启动：本次启动就是由分享唤起。
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      await _importShared(files);
      await ReceiveSharingIntent.instance.reset();
    } catch (_) {}
    // 运行中监听后续分享。
    ReceiveSharingIntent.instance.getMediaStream().listen((files) async {
      await _importShared(files);
    });
  }

  Future<void> _importShared(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    final path = files.first.path;
    if (!path.toLowerCase().endsWith('.xlsx')) return;
    try {
      final bytes = await File(path).readAsBytes();
      final course = parseDmcXlsx(bytes);
      if (course == null) {
        _toast('无法识别该文件，请分享教务系统导出的点名册 xlsx');
        return;
      }
      final replaced = await CourseStore.upsert(course);
      setState(() {
        _course = null; // 回到课程列表，让用户看到导入结果
        _showDetail = false;
      });
      _toast(replaced
          ? '已更新「${course.name}」名册（${course.students.length}人）'
          : '已导入「${course.name}」（${course.students.length}人）');
    } catch (e) {
      _toast('导入失败：$e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openCourse(Course course) {
    setState(() {
      _course = course;
      _index = 0;
      _selectedStudent = null;
      _showDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    if (course == null) {
      return CourseListPage(onOpenCourse: _openCourse);
    }
    if (_showDetail && _selectedStudent != null) {
      return DetailPage(
        student: _selectedStudent!,
        onBack: () => setState(() => _showDetail = false),
      );
    }
    final pages = [
      HomePage(
          course: course,
          onOpenStudent: (s) => setState(() {
                _selectedStudent = s;
                _showDetail = true;
              })),
      ProfilePage(course: course),
    ];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_search_outlined),
            selectedIcon: Icon(Icons.person_search),
            label: '点名',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
