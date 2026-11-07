import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 学生条目。
class Student {
  final String id;
  final String name;
  final String className;

  const Student(this.id, this.name, this.className);

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'className': className};

  factory Student.fromJson(Map<String, dynamic> j) =>
      Student(j['id'] as String, j['name'] as String, j['className'] as String);
}

/// 一门课程（来自一份教务系统导出的教师工作手册 xlsx）。
class Course {
  final String name; // 课程名
  final String code; // 课程号
  final String term; // 学年学期，如 2026学年 秋季学期
  final String teacher; // 上课教师
  final String unit; // 开课单位
  final List<Student> students;

  const Course({
    required this.name,
    required this.code,
    required this.term,
    required this.teacher,
    required this.unit,
    required this.students,
  });

  /// 同课程号同学期视为同一门课，重复导入时替换。
  String get key => '$code|$term';

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'term': term,
        'teacher': teacher,
        'unit': unit,
        'students': students.map((s) => s.toJson()).toList(),
      };

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        name: j['name'] as String,
        code: j['code'] as String,
        term: j['term'] as String,
        teacher: j['teacher'] as String? ?? '',
        unit: j['unit'] as String? ?? '',
        students: (j['students'] as List)
            .map((e) => Student.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 课程本地存储：shared_preferences 里的一个 JSON 列表。
class CourseStore {
  static const _prefsKey = 'courses_v1';

  static Future<List<Course>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(List<Course> courses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey, jsonEncode(courses.map((c) => c.toJson()).toList()));
  }

  /// 导入课程：同 key 替换（更新名册），新 key 追加。返回是否发生了替换。
  static Future<bool> upsert(Course course) async {
    final courses = await load();
    final before = courses.length;
    courses.removeWhere((c) => c.key == course.key);
    final replaced = courses.length < before;
    await save([...courses, course]);
    return replaced;
  }

  static Future<void> remove(Course course) async {
    final courses = await load();
    courses.removeWhere((c) => c.key == course.key);
    await save(courses);
  }
}

/// 解析云大教务系统导出的教师工作手册（dmc.xlsx）。
/// 返回 null 表示文件不是该格式（找不到表头或没有学生行）。
Course? parseDmcXlsx(List<int> bytes) {
  Excel excel;
  try {
    excel = Excel.decodeBytes(bytes);
  } catch (_) {
    return null;
  }
  if (excel.tables.isEmpty) return null;
  final sheet = excel.tables.values.first;
  final rows = sheet.rows;

  String? term, code, name, teacher, unit;
  int headerRow = -1;

  String? cellText(Data? c) {
    final v = c?.value;
    if (v == null) return null;
    String s;
    switch (v) {
      case TextCellValue t:
        s = t.value.toString(); // excel 包自定义 TextSpan，toString 拼接全部文本
      case IntCellValue i:
        s = i.value.toString();
      case DoubleCellValue d:
        s = d.value == d.value.truncateToDouble()
            ? d.value.toInt().toString()
            : d.value.toString();
      default:
        s = v.toString();
    }
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

  // 表头前的信息区：找 课程号/课程名/上课教师/开课单位/学年学期。
  for (var r = 0; r < rows.length; r++) {
    final texts = rows[r].map(cellText).toList();
    String? next(int c) {
      for (var i = c + 1; i < texts.length; i++) {
        if (texts[i] != null) return texts[i];
      }
      return null;
    }

    for (var c = 0; c < texts.length; c++) {
      final t = texts[c];
      if (t == null) continue;
      if (term == null && t.contains('学年') && t.contains('学期')) term = t;
      if (t.contains('课程号')) code ??= next(c);
      if (t.contains('课程名')) name ??= next(c);
      if (t.contains('上课教师')) teacher ??= next(c);
      if (t.contains('开课单位')) unit ??= next(c);
    }

    final hasId = texts.any((t) => t == '学号');
    final hasName = texts.any((t) => t == '姓名');
    if (hasId && hasName && headerRow < 0) headerRow = r;
  }

  if (headerRow < 0) return null;

  // 学生行：学号、姓名两列都有值的行。
  final students = <Student>[];
  for (var r = headerRow + 1; r < rows.length; r++) {
    final cells = rows[r].map(cellText).toList();
    String? col(int i) => i < cells.length ? cells[i] : null;
    final id = col(1);
    final stuName = col(2);
    if (id == null || stuName == null) continue;
    students.add(Student(id, stuName, col(3) ?? ''));
  }
  if (students.isEmpty || name == null) return null;

  return Course(
    name: name,
    code: code ?? '',
    term: term ?? '',
    teacher: teacher ?? '',
    unit: unit ?? '',
    students: students,
  );
}
