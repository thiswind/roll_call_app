import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:roll_call_app/course.dart';

void main() {
  // 桌面上的真实点名册（移动应用软件开发实训，44 人）。文件缺失时跳过。
  const sample = '/Users/thiswind/Desktop/未命名文件夹/dmc.xlsx';

  test('dmc 解析：真实文件字段与学生数', () {
    final f = File(sample);
    if (!f.existsSync()) {
      markTestSkipped('样例文件不存在，跳过');
      return;
    }
    final course = parseDmcXlsx(f.readAsBytesSync());
    expect(course, isNotNull, reason: '应能解析教务系统导出的点名册');
    expect(course!.students.length, 44);
    expect(course.name, '移动应用软件开发实训');
    expect(course.code, 'YN253011140052');
    expect(course.teacher, '胡矿');
    expect(course.students.last.name, 'OUK CHANNIKA');
    expect(course.students.every((s) => s.id.length == 11), isTrue);
  });

  test('同课程号同学期视为同一门课（覆盖更新）', () {
    final a = const Course(
        name: 'A', code: 'C1', term: 'T', teacher: '', unit: '', students: []);
    final b = const Course(
        name: 'A2', code: 'C1', term: 'T', teacher: '', unit: '', students: []);
    expect(a.key == b.key, isTrue);
  });

  test('空字节不是合法点名册', () {
    expect(parseDmcXlsx(List<int>.empty()), isNull);
  });
}
