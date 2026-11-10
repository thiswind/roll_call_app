import 'dart:convert';

import 'package:excel/excel.dart' as package_excel;
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

  test('教务点名册格式 xlsx 可解析（信息区+表头+学生行）', () {
    // 用 excel 包生成与教务系统导出同构的点名册：信息区键值对、
    // 学号/姓名表头、学生行。自包含，不依赖外部文件。
    final excel = package_excel.Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    sheet.appendRow([
      package_excel.TextCellValue('课程号'),
      package_excel.TextCellValue('CS301'),
    ]);
    sheet.appendRow([
      package_excel.TextCellValue('课程名'),
      package_excel.TextCellValue('数据结构'),
    ]);
    sheet.appendRow([
      package_excel.TextCellValue('上课教师'),
      package_excel.TextCellValue('张老师'),
    ]);
    sheet.appendRow([
      package_excel.TextCellValue('开课单位'),
      package_excel.TextCellValue('信息学院'),
    ]);
    sheet.appendRow([
      // 学年学期值独立成格（真实导出同构），parser 取含"学年+学期"的首格
      package_excel.TextCellValue('2026学年 秋季学期'),
    ]);
    sheet.appendRow([
      package_excel.TextCellValue('序号'),
      package_excel.TextCellValue('学号'),
      package_excel.TextCellValue('姓名'),
      package_excel.TextCellValue('班级'),
    ]);
    for (var i = 1; i <= 12; i++) {
      sheet.appendRow([
        package_excel.IntCellValue(i),
        package_excel.TextCellValue('202610${i.toString().padLeft(4, '0')}'),
        package_excel.TextCellValue('测试同学$i'),
        package_excel.TextCellValue('计科2601班'),
      ]);
    }
    final bytes = excel.encode()!;
    final course = parseDmcXlsx(bytes);
    expect(course, isNotNull, reason: '同构点名册应解析成功');
    expect(course!.name, '数据结构');
    expect(course.code, 'CS301');
    expect(course.teacher, '张老师');
    expect(course.term, '2026学年 秋季学期');
    expect(course.students.length, 12);
    expect(course.students.first.id, '2026100001');
    expect(course.students.first.name, '测试同学1');
  });
}
