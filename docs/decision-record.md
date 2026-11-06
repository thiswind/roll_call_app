# Flutter 实现方案决策记录

日期：2026-11-05
方法：multipass-think 多立场会议（提案人/质询人/证据官/裁判）
输入：HTML 原型（random-roll-call-draft/index.html）+ 用户三项拍板（先模拟器、滚动跳名后定格、每页一文件）

## 结论

1. **导航：RootPage setState 内部切换**（index 0 首页 / 1 我的 / 2 详情），否决 `Navigator.push`。
   - 理由①：HTML 原型即锚点内部切换，Flutter 版语义对齐。
   - 理由②：学生未学路由，边界约束禁止未学 API。
2. **状态：纯 setState**，否决 provider/Riverpod（未学、越界）。
3. **点名动画：`Timer.periodic` 16×60ms 滚动跳名后定格**，否决 `AnimatedSwitcher`（隐式动画组件未学）。Timer/Random 属 Dart 核心库（dart:async/dart:math），不在"未学组件"边界内。
4. **名册：`const List<Student>` 硬编码于 roster.dart**，44 人。用户原话"这学期都不会变，下学期再说"。
5. **主题：`ColorScheme.fromSeed(0xFF6750A4)`** —— M3 baseline 紫，与原型参数文档一致。

## 被否决备选

- Navigator 嵌套（NavigationBar shell + 内层 Navigator）：过度设计，学生无法维护。
- IndexedStack 保活三页：详情页数据每次更新，无需保活，简单数组切换足够。

## 存疑项

- 无。用户已确认全部三项分歧点。

## 验证

- flutter analyze：0 issues
- flutter test：2 passed（名册 44 人唯一性、点名交互）
- 模拟器运行：见运行日志

---

# 应用图标决策记录

日期：2026-11-06
方法：multipass-think（提案人/质询人/用户代言人/执行者/裁判）+ needfinding 两问收敛
用户拍板：上网找现成矢量图标（举手/骰子由我定）+ Material 3 紫配色

## 结论

1. **视觉：五点骰子（filled）白图形 + M3 紫底（#6750A4）**，与 App 内「随机点名」按钮（Icons.casino）语义同源，纯几何图形小尺寸清晰。
2. **素材：Material Symbols 官方 `casino` fill1 SVG**（Apache 2.0 许可，github.com/google/material-design-icons），满足"上网下矢量图"要求。
3. **落地：flutter_launcher_icons 0.14.4，仅 iOS**（工程 android 骨架不完整，目标设备 iOS）。
   - iOS 母版 1024×1024：骰子占 68%（696/1024），无预渲染圆角，remove_alpha_ios: true。
   - Android 自适应前景母版同步备好（骰子收在 66dp 安全区，600/1024≈58.6%），配 adaptive_icon_background "#6750A4"，未来补 Android 平台直接可用。
4. **顺手修正：CFBundleDisplayName → 「课堂点名」**（原默认 "Roll Call App"，与"去默认化"目标同源）。

## 被否决备选

- 骰子+举手组合图：小尺寸必糊（质询人驳倒）。
- 举手学生单图：语义弱于骰子（用户代言人）。
- AI 生成位图：用户明确要求上网找矢量素材。
- 线条（outline）版图标：桌面远看像"贴纸"，选 filled 版。

## 事实核查（perplexity，两源交叉）

- flutter_launcher_icons 仍为官方推荐：docs.flutter.dev/deployment/android [实证·网证]
- iOS 1024×1024、系统遮罩不预渲染圆角、remove_alpha_ios：Apple HIG + 包文档 [实证·网证]
- Android 自适应图标 108dp 层 / 66dp 安全区：developer.android.com [实证·网证]

## 验证

- 图标生成：ios/Runner/Assets.xcassets/AppIcon.appiconset 全套尺寸已更新（07:03）
- 模拟器主屏截图（视觉模型复核）：紫色底 + 白色五点骰子，非 Flutter 默认蓝 ✓
- App 名称截图复核：「课堂点名」✓
- 母版留档：assets/icon/app_icon.png（iOS）、assets/icon/adaptive_foreground.png（Android 前景）

---

# 真机自用分发路径决策记录

日期：2026-11-06
方法：multipass-think（提案人/质询人/执行者/风险官/裁判）+ multipass-search 两轮网查（perplexity × Apple 官方域）
用户问题：能否在自己 iPhone 12 Pro Max 上使用自研 App，不上架

## 结论

1. **可行且合法**：免费 Apple ID（Xcode Personal Team）开发签名自装自用，Apple 官方支持路径。
2. **选免费路径**：¥0，签名 7 天有效；到期 App 无法启动，重新构建安装即续。决定性条件：本 App 名册硬编码、零持久化用户数据，重装无痛；用户 Mac 常在手边。
3. 付费个人账号（US$99/年，中国区价格以购买页为准）留给未来上架/分发需求；AltStore/Sideloadly 对有 Mac 的用户是多余一层（本质仍复用免费 7 天签名）。

## 被否决备选

- AltStore/Sideloadly：面向无 Mac 用户，本场景徒增工具链。
- 直接付费 ¥688：买到的主要是分发能力（App Store/TestFlight），纯自用用不上。

## 事实核查（perplexity，Apple 官方域）

- 免费 Personal Team：7 天 / 3 App 每设备 / 3 设备 / 10 App ID：developer.apple.com/support/compare-memberships [实证·网证]
- 到期行为：App 无法启动，rebuild+reinstall 续期；非数据销毁 [实证·网证]
- TestFlight 每个 build 90 天：developer.apple.com TestFlight overview [实证·网证]
- 付费开发签名"约一年"：社区共识，Apple 文档仅称 profile 有效期"通常不超过一年" [存疑·以官方页为准]
- 中国区 ¥688/年：官方页未能核实，付费前以 developer.apple.com/cn 购买页为准 [存疑]

## 落地条件（已具备）

- 用户 iPhone 12 Pro Max 已与 Mac 配对（flutter devices 曾识别 wireless 在线）[实证·本地]
- 待办：Xcode 登录个人 Apple ID → Runner 签名 Team 选 Personal Team → flutter run -d 真机

---

# 真机白屏根因排查与 Flutter 升级决策记录

日期：2026-11-06 晚
方法：取证链（devicectl 进程/截图/codesign/构建日志）+ multipass-search（perplexity × GitHub issue）+ 工具链源码精读

## 现象链

1. Debug 版主屏图标启动闪退（signal 5 SIGTRAP）——Flutter Debug 为 JIT 编译，真机脱离 lldb 调试器不能运行，**预期行为，非 bug**。
2. 改 scheme LaunchAction → Release 重装后：进程存活（devicectl info processes 可见 PID）、状态栏正常、内容区纯白（devicectl 截图 + 视觉模型复核证实）、无任何 UI。devicectl launch 返回成功不代表首帧渲染成功。

## 审查结论（逐项排除）

| 检查项 | 结果 |
|---|---|
| Dart 代码 / AppDelegate / Info.plist | 标准模板，无插件无 Podfile，无问题 |
| Release 产物结构 | App.framework 纯 AOT（3.9MB）、flutter_assets 齐全、embedded.mobileprovision 在位 |
| codesign --verify --deep --strict | 通过，签名链完整（Apple Development 证书） |
| 真机 Release 构建日志 | "Build succeeded"，无 release_unpack_ios 报错 |
| 沙盒 vs 非沙盒 | 失败可复现于两种模式，排除沙盒 |

## 根因：Flutter 3.38.4（2025-12）与 Xcode 27.2 / iOS 27 不兼容

**证据 A（实锤，本地复现）**：Xcode 27 的 lipo 存在回归 bug——`lipo <file> -verify_arch arm64 x86_64` 多架构调用报 `-verify_arch requires exactly one input file`，单架构调用正常。Flutter 3.38.4 `darwin.dart thinFramework()` 使用多架构旧写法 → 模拟器构建必失败（`Target debug_unpack_ios failed`）。上游：flutter/flutter#188346、#188461；修复 PR #188625（改为逐架构单独校验），3.44.5 仍复现，3.44.8 起包含修复。

**证据 B（主嫌，待升级后验证）**：Flutter iOS 27 场景生命周期/display-link 兼容问题导致白屏（#188106 场景未适配白屏、#195401 折叠屏 display-link 挂错屏幕）。Flutter 3.41+ 默认启用 UIScene 支持并自动迁移旧工程；3.47 为 Xcode 27 / iOS 27 适配版本。

## 决策

升级 Flutter 3.38.4 → 3.47.9（Homebrew cask，旧版保留于 Caskroom 可回退）。被否决备选：
- 降级 Xcode：刚为真机 iOS 27.0.1 升级到 27.2，降级即失去真机调试能力。
- 手改 darwin.dart 补丁：只修 lipo 一处，不解决引擎场景兼容；且会被升级覆盖。
- 关闭 Impeller：iOS 上 Impeller 为唯一受支持渲染器，官方无此 workaround。

## 验证计划

1. 升级后模拟器 Debug 构建运行（此前必失败的 lipo 环节应通过）。
2. 真机 Release 重装 + 主屏图标启动（白屏场景的原始复现路径）。

## 升级执行结果（当晚完成）

- Flutter 3.38.4 → **3.47.9**（brew cask，2026-10-29 发布）。
- 下载踩坑：官方源 ~20KB/s 放弃；镜像站（flutter-io.cn）两次下载均截断（真实大小 2,268,740,583 B，首次仅得 83%，zip 目录丢失）；最终腾讯镜像 Range 续传补齐，SHA256 与 brew cask 官方值 6545b859… 完全一致后才喂给 brew 缓存安装。**教训：大文件必须 SHA256 验证，http 200 不代表完整。**
- 新版 `thinFramework` 已逐架构校验（darwin.dart:87-89），模拟器 Debug 构建 29.4s 成功（此前必失败）。
- 3.47.9 自动完成 **UIScene 生命周期迁移**：Info.plist 新增 UIApplicationSceneManifest（FlutterSceneDelegate），AppDelegate 更新。
- 模拟器（iOS 27.2）运行截图复核：界面完整渲染（课程标题/随机点名按钮/44 人名册），非白屏。
- 顺手清理：~/.zshrc 中 3.19.6 硬编码 PATH 残留（改为注释说明 brew cask 管理）。
- **待验收**：真机 Release 重装 + 主屏图标启动（Xcode GUI Run，签名通道）。
