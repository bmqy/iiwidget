import SwiftUI
import WidgetKit

struct ShiftCalendarEditorView: View {
    @State private var config = SharedStore.loadShiftCalendar()
    @State private var previewDate = Date()
    @State private var previewSize: PreviewSize = .small
    @State private var saved = false
    @State private var showDiagnostics = false

    enum PreviewSize: String, CaseIterable, Identifiable {
        case small = "小号"
        case medium = "中号"
        case large = "大号"

        var id: String { rawValue }

        var family: WidgetFamily {
            switch self {
            case .small: return .systemSmall
            case .medium: return .systemMedium
            case .large: return .systemLarge
            }
        }

        /// 与真机小组件近似的内容尺寸（pt），让预览排版与桌面一致。
        var canvas: CGSize {
            switch self {
            case .small: return CGSize(width: 158, height: 158)
            case .medium: return CGSize(width: 338, height: 158)
            case .large: return CGSize(width: 338, height: 338)
            }
        }
    }

    private var sizeSelector: some View {
        HStack(spacing: 3) {
            ForEach(PreviewSize.allCases) { size in
                Button {
                    previewSize = size
                } label: {
                    Text(size.rawValue)
                        .font(.system(size: 13, weight: previewSize == size ? .semibold : .regular))
                        .foregroundStyle(previewSize == size ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(previewSize == size ? Color(.secondarySystemGroupedBackground) : Color.clear)
                                .shadow(color: .black.opacity(previewSize == size ? 0.1 : 0), radius: 2, y: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        )
    }

    private var previewCaption: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: previewDate)
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    sizeSelector

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

                    ShiftCalendarView(config: config, date: previewDate, familyOverride: previewSize.family)
                        .frame(width: previewSize.canvas.width, height: previewSize.canvas.height)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.16), radius: 12, y: 6)
                        .frame(maxWidth: .infinity)
                        .id(previewSize)
                }
                .padding(.vertical, 6)
                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            } header: {
                Text("实时预览")
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
                Text("保存后回到桌面：长按空白处 → 左上角「+」→ 搜索 Widget Studio → 选尺寸添加；再长按该小组件 →「编辑小组件」→ 模板选「倒班日历」、排班制选「App 内自定义」。这一步需要 App Group 可用（付费开发者账号签名）；免费签名请直接在编辑小组件里选内置排班制。")
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
    private var appID: String { Bundle.main.bundleIdentifier ?? "未知" }

    private var extensions: [String] {
        let plugIns = Bundle.main.bundleURL.appendingPathComponent("PlugIns")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: plugIns.path)) ?? []
        return names.map { name in
            let bundlePath = plugIns.appendingPathComponent(name)
            let bundle = Bundle(url: bundlePath)
            let id = bundle?.bundleIdentifier ?? "读取失败"
            return "\(name) → \(id)"
        }
    }

    private var groupStatus: String {
        SharedStore.isAppGroupAvailable ? "可用" : "不可用（免费 Apple ID 签名常见，配置无法同步给小组件）"
    }

    var body: some View {
        Form {
            Section("宿主 App") {
                LabeledContent("Bundle ID", value: appID)
            }

            Section("内嵌小组件扩展") {
                if extensions.isEmpty {
                    Text("未检测到扩展，说明签名工具可能漏签了 Widget 扩展。")
                        .foregroundStyle(.red)
                } else {
                    ForEach(extensions, id: \.self) { item in
                        Text(item).font(.footnote.monospaced())
                    }
                }
            }

            Section("App Group") {
                Text(groupStatus).font(.footnote)
            }

            Section("已注册模板") {
                Text("Widget Studio（统一入口）：文字卡片 / 计数器 / 倒班日历").font(.footnote)
            }

            Section {
                Text("如果这里显示正常但桌面仍找不到「倒班日历」，通常是小部件缓存问题：\n1. 删除 App 重新签名安装\n2. 重启 iPhone\n3. 桌面长按空白 → 左上角「+」→ 搜索 Widget Studio")
                    .font(.footnote)
            }
        }
    }
}
