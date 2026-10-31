# Widget Studio

一个「自己造 iOS 桌面小组件」的 App：内置模板 + 可视化编辑，改完保存直接上桌面。

- 宿主 App：SwiftUI，编辑标题 / 正文 / SF Symbol 图标 / 配色 / 样式（渐变、纯色、毛玻璃）
- 小组件扩展：WidgetKit，两种模板
  - **文字卡片**：读取 App 里保存的配置（走 App Group 共享）
  - **计数器**：走 `AppIntentConfiguration`，长按小组件即可改标题、数值、单位、颜色（不依赖 App Group，自签也能改）

## 一、目录结构

```
project.yml                       XcodeGen 工程定义（App + Widget Extension）
Sources/App/                      宿主 App
Sources/Shared/                   两端共用：数据模型、App Group 存储、卡片渲染视图
Sources/Widget/                   WidgetKit 扩展
Resources/Assets.xcassets/        App 图标
.github/workflows/build.yml       云端编译出 ipa
```

## 二、拿 ipa 的三步

1. 在 GitHub 建一个空仓库（private 也可以），把本目录所有文件推上去
2. 打开仓库的 **Actions** 标签，等 `build-ipa` 跑完（约 3-6 分钟）
3. 在这次的运行记录底部 **Artifacts** 里下载 `WidgetStudio-unsigned-ipa`，解压得 `WidgetStudio-unsigned.ipa`

> 工作流只在 push 到 main/master 或手动 `Run workflow` 时触发。产物是**未签名**的，直接装不上手机，必须自己签一次。

## 三、签名并安装（择一）

**A. Sideloadly（免费 Apple ID，7 天有效）**
1. 电脑装 [Sideloadly](https://sideloadly.io/)，iPhone 用数据线连电脑
2. 把 ipa 拖进去，填 Apple ID，点 Start
3. 手机上「设置 → 通用 → VPN与设备管理」信任开发者证书
4. 7 天后过期，重新拖一次即可（App 数据会保留）

**B. 付费开发者账号（$99/年，1 年有效）**
用 Xcode 打开工程（`xcodegen generate` 后），Signing 里选团队、填你自己的 Bundle ID，直接 Run 到手机；或继续用 Sideloadly 签。

## 四、必须知道的三个坑

1. **App Group 要匹配**：`Sources/Shared/SharedStore.swift` 里 `group.com.widgetstudio.shared` 必须与你在开发者后台注册的 App Group 一致（免费 Apple ID 不支持 App Group 能力）。不一致时「文字卡片」会一直显示默认内容——不影响编译和安装，「计数器」模板完全不受影响。
2. **Bundle ID 要改**：`project.yml` 里的 `com.widgetstudio.app` / `com.widgetstudio.widget` 建议换成你自己的前缀，避免和别人冲突。
3. **第三方 App 不能运行时新增小组件类型**：系统只认编译期注册的 widget kind。这个 App 的「制作」= 在预置模板里换内容与样式；想加全新模板，就在 `Sources/Widget/` 里加一个 `Widget` 并在 `WidgetBundle` 里注册。

## 五、本地编译

```bash
brew install xcodegen
xcodegen generate
open WidgetStudio.xcodeproj
```
