# Widget Studio

一个「自己造 iOS 桌面小组件」的 App：预置模板 + 可视化编辑，设置好后直接添加到 iPhone 主屏幕。

- 宿主 App：SwiftUI 编辑器
- WidgetKit 扩展：文字卡片、计数器、倒班日历

## 倒班日历

- 自定义轮班循环：增加、删除、排序班次，可填「白班」「夜班」「中班」「休息」等。
- 自定义循环锚点日期：锚点当天对应循环的第一个班次，按自然日向前/后推算。
- 三种视觉样式：极光深色渐变、简约暖纸感、柔和浅色渐变。
- 小号组件：月历周格、每日班次色点、今日班次胶囊。
- 中号/大号组件：月历班次标签、今日状态、班次图例；切换横竖尺寸由系统完成。
- App 内实时预览、可切换小号/中号预览和月份，保存后刷新桌面小组件。

编辑入口：打开 App 首页的「倒班日历」卡片。按循环顺序编辑班次，设置第一天日期，选择喜欢的风格，点「保存排班并刷新小组件」。回到桌面添加「倒班日历」小组件即可。

## 工程

```text
project.yml                         XcodeGen 工程定义（App + Widget Extension）
Sources/App/                        宿主 App 与编辑器
Sources/Shared/                     共用配置模型、App Group 存储、卡片渲染
Sources/Widget/                     WidgetKit 扩展（3 种模板）
Resources/Assets.xcassets/           App 图标
.github/workflows/build.yml         GitHub Actions 云端编译、打包未签名 ipa
```

## 生成 IPA

1. 将本目录推到 GitHub 仓库 `main`（或 `master`）分支。
2. 在仓库 Actions 查看 `build-ipa` 工作流。
3. 构建成功后从 Artifacts 下载 `WidgetStudio-unsigned-ipa.zip`，解压得 `WidgetStudio-unsigned.ipa`。

该 IPA **未签名**，需用 Sideloadly / AltStore 等签名后安装。免费 Apple ID 签名有效期通常 7 天；付费开发者账号通常一年。

## Xcode 本地构建

```bash
brew install xcodegen
xcodegen generate
open WidgetStudio.xcodeproj
```

## 重要提示

1. `Sources/Shared/SharedStore.swift` 的 App Group ID 要与开发者账号中启用的值一致。免费 Apple ID 一般不支持 App Group entitlement；这种情况下文字卡片、倒班日历 App 内保存共享配置不会工作。**计数器的 AppIntent 配置不受影响。**
2. `project.yml` 中 Bundle ID 建议改成你自己的，且 widget Bundle ID 必须以主 App Bundle ID 为前缀。
3. WidgetKit 的小组件类型需在编译时注册，不能运行时新增；当前是预置三类模板。
