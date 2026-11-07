import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roll_call_app/course.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Course sampleCourse(String code) => Course(
        name: '人工智能程序设计与实践',
        code: code,
        term: '2026学年 秋季学期',
        teacher: '胡康',
        unit: '智能系统与计算重点实验室',
        students: const [
          Student('20261000001', '张三', '金融学2026级'),
          Student('20261000002', '李四', '金融学2026级'),
        ],
      );

  test('课程 JSON 序列化往返', () {
    final c = sampleCourse('YN253011180031');
    final back = Course.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>);
    expect(back.key, c.key);
    expect(back.students.length, 2);
    expect(back.students.first.name, '张三');
  });

  test('同课程号同学期重复导入只保留一份（覆盖更新）', () async {
    SharedPreferences.setMockInitialValues({});
    await CourseStore.upsert(sampleCourse('YN253011180031'));
    final replaced = await CourseStore.upsert(sampleCourse('YN253011180031'));
    final courses = await CourseStore.load();
    expect(courses.length, 1);
    expect(replaced, isTrue);
  });

  test('不同课程号导入为两门课，删除后清空', () async {
    SharedPreferences.setMockInitialValues({});
    await CourseStore.upsert(sampleCourse('YN253011180031'));
    await CourseStore.upsert(sampleCourse('YN253011140052'));
    var courses = await CourseStore.load();
    expect(courses.length, 2);
    await CourseStore.remove(courses.first);
    courses = await CourseStore.load();
    expect(courses.length, 1);
  });

  test('非 xlsx 字节返回 null（无法解析）', () {
    expect(parseDmcXlsx(utf8.encode('这不是表格文件')), isNull);
  });
}
