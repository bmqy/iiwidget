import SwiftUI
import WidgetKit

/// 自查用：确认扩展是否被系统识别、App Group 是否可用。
struct DiagnosticsView: View {
    @State private var widgetKinds: [String] = []
    @State private var widgetError: String?

    private var appID: String { Bundle.main.bundleIdentifier ?? "未知" }

    private var extensionIDs: [String] {
        let plugIns = Bundle.main.bundleURL.appendingPathComponent("PlugIns")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: plugIns.path)) ?? []
        return names.compactMap { name in
            Bundle(url: plugIns.appendingPathComponent(name))?.bundleIdentifier
        }
    }

    private var prefixOK: Bool {
        guard let appex = extensionIDs.first else { return false }
        return appex.hasPrefix(appID + ".")
    }

    var body: some View {
        Form {
            Section("宿主 App") {
                LabeledContent("Bundle ID", value: appID)
                LabeledContent(
                    "版本",
                    value: "v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
                        + " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?") + ")"
                )
            }

            Section {
                LabeledContent(
                    "App Group",
                    value: SharedStore.appGroupID
                )
                LabeledContent(
                    "共享容器",
                    value: SharedStore.isAppGroupAvailable ? "可用" : "不可用"
                )
                if !SharedStore.isAppGroupAvailable {
                    Text("当前安装包没有带上 App Group 权限：桌面小组件会显示默认内容，右上角出现「共享未启用」角标。请安装 Actions 产物 mini-widgets-trollstore.ipa（已预签名并写入权限），或在你自己的签名描述文件里启用 App Group。")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("共享存储")
            }

            Section {
                if extensionIDs.isEmpty {
                    Text("未检测到扩展：签名工具可能漏签了 Widget 扩展。")
                        .foregroundStyle(.red)
                } else {
                    ForEach(extensionIDs, id: \.self) { id in
                        Text(id).font(.footnote.monospaced())
                    }
                    LabeledContent("前缀检查", value: prefixOK ? "正常" : "异常（扩展 Bundle ID 必须以主 App 为前缀）")
                }
            } header: {
                Text("内嵌小组件扩展")
            } footer: {
                Text("扩展 Bundle ID 必须是「主 App Bundle ID + .后缀」。TrollStore / 自签改名时若只改了主 App，小组件会一直停在占位状态。")
            }

            Section {
                if let widgetError {
                    Text(widgetError).font(.footnote).foregroundStyle(.red)
                } else if widgetKinds.isEmpty {
                    Text("系统里还没有已添加的 Mini Widgets 小组件。")
                        .font(.footnote)
                } else {
                    ForEach(widgetKinds, id: \.self) { kind in
                        Text(kind).font(.footnote.monospaced())
                    }
                }
            } header: {
                Text("系统已登记的小组件")
            }

            Section {
                Text("若小组件一直是占位图（灰底幽灵块），说明扩展没能启动：请查看 设置 → 隐私与安全性 → 分析与改进 → 分析数据，找 MiniWidgetsWidget 开头的崩溃日志。")
                    .font(.footnote)
            }
        }
        .task {
            WidgetCenter.shared.getCurrentConfigurations { result in
                switch result {
                case .success(let infos):
                    widgetKinds = infos.map { "kind: \($0.kind)" }
                case .failure(let error):
                    widgetError = error.localizedDescription
                }
            }
        }
    }
}
