# 课堂点名（roll_call_app）

适配云南大学本科教务系统的点名应用（iOS + Android）。导入教务系统"教师工作手册"导出的点名册
（dmc.xlsx），一个 App 管理多门课程，滚动点名。

## 下载安装

- **iOS**：[App Store](https://apps.apple.com/us/app/id6832057743)（课堂点名-ehall）
- **Android**：扫码或从 [Releases](https://github.com/thiswind/roll_call_app/releases/latest) 下载 APK 安装

<p align="center">
  <img src="screenshots/download_qr.png" width="220" alt="Android 版下载二维码" title="扫码下载 Android 版"/>
</p>

扫码后若微信拦截下载，请点右上角菜单 →「在浏览器打开」，浏览器下载后点击安装（需允许安装未知来源应用）。

## 功能

- **导入点名册**：从微信、"文件"等 App 打开 xlsx 后"用其他应用打开" → 课堂点名，即完成导入
- **多课程管理**：导入几份名单就有几门课；同一门课（课程号+学期相同）再次导入自动覆盖更新
- **滚动点名**：随机抽取学生，已点/未点状态管理
- **本地持久化**：课程数据存本地，无需联网、无需写死名单

## 点名册格式

云大教务系统教师工作手册导出的 xlsx：信息区含学年学期/课程号/课程名/上课教师，
表头行含"学号/姓名/班级"，学号在第 2 列、姓名第 3 列。

## 开发

```bash
flutter pub get
flutter test
flutter run -d <device-id>
```

支持 iOS 与 Android 双平台，平台目录 `ios/`、`android/` 均在库中。
Android 签名：构建机放置 `android/key.properties`（不入库），缺失时退回 debug 签名。

## 隐私

课程点名册数据仅存储在设备本地。[隐私政策](https://thiswind.github.io/roll_call_app/privacy.html)
