# 课堂点名（roll_call_app）

适配云南大学本科教务系统的 iOS 点名应用。导入教务系统"教师工作手册"导出的点名册
（dmc.xlsx），一个 App 管理多门课程，滚动点名。

## 功能

- **导入点名册**：App 内通过文件选择器导入，或从微信等其他 App "用其他应用打开" 分享 xlsx 进来
- **多课程管理**：导入几份名单就有几门课；同一门课（课程号+学期相同）再次导入自动覆盖更新
- **滚动点名**：随机抽取学生，已点/未点状态管理
- **本地持久化**：课程数据存 SharedPreferences，无需联网、无需写死名单

## 点名册格式

云大教务系统教师工作手册导出的 xlsx：信息区含学年学期/课程号/课程名/上课教师，
表头行含"学号/姓名/班级"，学号在第 2 列、姓名第 3 列。

## 开发

```bash
flutter pub get
flutter test
flutter run -d <simulator-udid>
```

仅保留 iOS 平台。iOS 平台目录位于 `~/dev/roll_call_ios/ios`（本仓库内 `ios` 为符号链接，
不入库，克隆后需自行 `flutter create --platforms=ios .` 重建）。
