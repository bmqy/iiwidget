# Widget Studio

一个「自己造 iOS 桌面小组件」的 App：桌面只需添加 **一个** Widget Studio 小组件，选尺寸；之后长按它 →「编辑小组件」，就能在三种模板之间切换。

## 添加与切换（重要）

1. 桌面长按空白处 → 左上角「+」→ 搜索 **Widget Studio**
2. 选尺寸：小 / 中 / 大（三种尺寸都支持全部模板）
3. 添加完成后，**长按该小组件 → 编辑小组件**，在参数里选：
   - 模板：文字卡片 / 计数器 / 倒班日历
   - 主题色、图标、标题、正文、数值、单位
   - 排班制、日历风格

## 三种模板

**文字卡片**：标题 + 正文 + 图标 + 主题色渐变。文字来源可选「在编辑小组件里直接填」或「用 App 里编辑的」。

**计数器**：标题 + 数值 + 单位，适合天数、次数、打卡。

**倒班日历**
- 内置 5 套排班制：上二休二、做一休一、两班倒、三班倒、四班三运转
- 也可在 App 内自定义循环班次（增删、排序、设置起始日期），排班制选「App 内自定义」
- 三种视觉风格：极光（深色渐变）、简约（暖纸感）、柔和（浅色渐变）
- 小尺寸显示今日 + 本周，中尺寸显示一周班次 + 图例，大尺寸显示整月日历
- 今日高亮、班次配色区分、休息日标记

> 只有「App 内自定义排班」和「用 App 里编辑的文字」需要 App Group（付费开发者账号签名才稳定可用）。免费 Apple ID 签名时用内置排班制与直接填写的文字，功能照常。

## 工程结构

```text
project.yml                          XcodeGen 工程定义（App + Widget Extension）
Sources/App/                         宿主 App：文字卡片编辑器、倒班日历编辑器、诊断页
Sources/Shared/                      配置模型、App Group 存储、卡片渲染视图
Sources/Widget/                      WidgetKit 扩展（单一 kind + AppIntent 配置）
Resources/Assets.xcassets/           App 图标
.github/workflows/build.yml          GitHub Actions 云端编译并产出未签名 ipa
```

```text
Sources/Widget/
  WidgetBundle.swift                 只注册 StudioWidget 一个 kind
  StudioWidget.swift                 kind、尺寸支持、Timeline 提供器、模板分发视图
  StudioIntent.swift                 「编辑小组件」里的全部参数与枚举
  ShiftCalendarView.swift            倒班日历渲染（小/中/大三种布局）
```

## 生成 IPA

```bash
git push origin main     # 触发 Actions
```

仓库 Actions → 最新一次 `build-ipa` → Artifacts 下载 `WidgetStudio-unsigned-ipa`，解压得 ipa。

## 本地构建

```bash
brew install xcodegen
xcodegen generate
open WidgetStudio.xcodeproj
```

## 签名与安装

产物 **未签名**，需自行签名安装：

- Sideloadly / AltStore：免费 Apple ID，约 7 天有效，到期重签
- 付费开发者账号：约 1 年有效，并可注册 App Group

## 常见问题

**桌面列表里没有对应模板？** 现在只有一个 Widget Studio 条目，模板在「编辑小组件」里切换，不再依赖多个 kind。

**改了 App 里的排班，桌面没变？** 检查 App 内「诊断」页的 App Group 状态；免费签名通常不可用，请在「编辑小组件」里选内置排班制。

**Bundle ID 要求**：widget 的 Bundle ID 必须以主 App 的 Bundle ID 为前缀，例如 `com.you.app` 与 `com.you.app.widget`。
