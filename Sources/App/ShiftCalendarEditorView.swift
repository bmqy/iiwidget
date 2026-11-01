import SwiftUI
import WidgetKit
import UIKit

struct ShiftCalendarEditorView: View {
    @State private var config = SharedStore.loadShiftCalendar()
    @State private var previewDate = Date()
    @State private var saved = false
    @State private var showDiagnostics = false

    private var previewCaption: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: previewDate)
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 18) {
                    HStack {
                        Button {
                            previewDate = Calendar.current.date(byAdding: .month, value: -1, to: previewDate) ?? previewDate
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Text(previewCaption)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            previewDate = Calendar.current.date(byAdding: .month, value: 1, to: previewDate) ?? previewDate
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }

                    previewBlock("小号 · 今日与本周", family: .systemSmall, canvas: CGSize(width: 158, height: 158))
                    previewBlock("中号 · 一周班次", family: .systemMedium, canvas: CGSize(width: 338, height: 158))
                    previewBlock("大号 · 整月日历", family: .systemLarge, canvas: CGSize(width: 338, height: 338))
                }
                .padding(.vertical, 6)
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            } header: {
                Text("预览 · 三种尺寸")
            }

            Section {
                ForEach(config.cycle.indices, id: \.self) { index in
                    HStack(spacing: 12) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 27, height: 27)
                            .background(Circle().fill(Color.secondary.opacity(0.1)))
                        TextField("班次名称", text: Binding(
                            get: { config.cycle.indices.contains(index) ? config.cycle[index] : "" },
                            set: { newValue in
                                guard config.cycle.indices.contains(index) else { return }
                                config.cycle[index] = String(newValue.prefix(8))
                            }
                        ))
                        .submitLabel(.done)
                        if index < config.cycle.count - 1 {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .onDelete { offsets in
                    guard config.cycle.count - offsets.count >= 1 else { return }
                    config.cycle.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    config.cycle.move(fromOffsets: source, toOffset: destination)
                }

                if config.cycle.count < 14 {
                    Button {
                        config.cycle.append("白班")
                    } label: {
                        Label("添加一个班次", systemImage: "plus.circle.fill")
                            .fontWeight(.medium)
                    }
                }

                DatePicker("循环从哪天开始", selection: $config.anchorDate, displayedComponents: .date)
                    .datePickerStyle(.compact)

                LabeledContent("锚点当天班次", value: config.cycle.first ?? "白班")
                    .foregroundStyle(.secondary)
            } header: {
                Text("排班循环 · \(config.cycle.count) 天")
            } footer: {
                Text("从上往下依次循环。例：白班 → 夜班 → 休息 → 休息。所选日期当天对应第一个班次，向前向后自动推算。点右上角「编辑」可删除或拖动排序。")
            }

            Section {
                HStack(spacing: 8) {
                    Image(systemName: SharedStore.isAppGroupAvailable ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(SharedStore.isAppGroupAvailable ? Color.green : Color.orange)
                    Text(SharedStore.isAppGroupAvailable
                         ? "共享存储正常，保存后桌面立即生效"
                         : "共享存储不可用：桌面小组件将显示默认排班")
                        .font(.footnote)
                }
            } header: {
                Text("同步状态")
            } footer: {
                Text("若显示不可用，请使用本项目 Actions 产出的 WidgetStudio-trollstore.ipa（构建时已写入 App Group 权限），或用自己的描述文件签名并保留 App Group 能力。")
            }

            Section {
                Picker("日历风格", selection: Binding(
                    get: { config.style },
                    set: { config.style = $0 }
                )) {
                    ForEach(ShiftCalendarStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 8) {
                    styleSwatch(.aurora, title: "极光", gradient: [Color(hex: "#1B2B49"), Color(hex: "#17384A")])
                    styleSwatch(.editorial, title: "简约", gradient: [Color(hex: "#F3F0E9"), Color(hex: "#D6CBB8")])
                    styleSwatch(.soft, title: "柔和", gradient: [Color(hex: "#F7F0FF"), Color(hex: "#EEF6FF")])
                }
                .padding(.vertical, 4)
            } header: {
                Text("视觉风格")
            } footer: {
                Text("极光：深色渐变，夜间也清晰。简约：暖调纸感。柔和：浅色渐变，轻盈明亮。")
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                        Text("保存排班并刷新小组件")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
                .disabled(config.cycle.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
            } footer: {
                Text("保存后回到桌面：长按空白处 → 左上角「+」→ 搜索 Widget Studio → 选尺寸添加；再长按该小组件 →「编辑小组件」→ 模板选「倒班日历」。排班可以直接选内置排班制，或选「自定义」后把上面的两行填进去。")
            }

            Section {
                Button {
                    showDiagnostics = true
                } label: {
                    Label("桌面找不到小组件？点这里自查", systemImage: "stethoscope")
                }
            }
        }
        .navigationTitle("倒班日历")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showDiagnostics) {
            NavigationStack {
                DiagnosticsView()
                    .navigationTitle("诊断")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("关闭") { showDiagnostics = false }
                        }
                    }
            }
        }
        .alert("排班已保存", isPresented: $saved) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("小组件已刷新。若桌面仍未更新，试试重新添加一次小组件。")
        }
    }

    private func previewBlock(_ title: String, family: WidgetFamily, canvas: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ShiftCalendarView(config: config, date: previewDate, familyOverride: family)
                .frame(width: canvas.width, height: canvas.height)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
                .frame(maxWidth: .infinity)
        }
    }

    private func styleSwatch(_ style: ShiftCalendarStyle, title: String, gradient: [Color]) -> some View {
        Button {
            config.style = style
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 46)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 3) {
                            Circle().fill(Color(hex: "#5EDBC5")).frame(width: 7, height: 7)
                            Circle().fill(Color(hex: "#FF8B7B")).frame(width: 7, height: 7)
                            Circle().fill(Color(hex: "#739BFF")).frame(width: 7, height: 7)
                        }
                        .padding(7)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if config.style == style {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                                .padding(5)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(Color.accentColor, lineWidth: config.style == style ? 2 : 0)
                    )
                Text(title)
                    .font(.caption.weight(config.style == style ? .bold : .medium))
                    .foregroundStyle(config.style == style ? Color.accentColor : Color.primary)
            }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        var normalized = config
        normalized.cycle = config.cycle.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(8)) }
        SharedStore.saveShiftCalendar(normalized)
        config = normalized
        saved = true
    }
}

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
                    Text("系统里还没有已添加的 Widget Studio 小组件。")
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
                Text("全部功能都走小组件自身参数，不依赖 App Group。若小组件一直是占位图，多半是扩展没能启动，请查看「分析数据」里的 WidgetStudioWidget 崩溃日志。")
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
