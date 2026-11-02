import SwiftUI

struct ContentView: View {
    @State private var settings = SharedStore.loadSettings()
    @State private var textConfig = SharedStore.load()
    @State private var shiftConfig = SharedStore.loadShiftCalendar()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    previewCanvas
                        .listRowInsets(EdgeInsets(top: 16, leading: 10, bottom: 8, trailing: 10))
                        .listRowBackground(Color.clear)

                    templatePicker
                        .listRowInsets(EdgeInsets(top: 10, leading: 12, bottom: 14, trailing: 12))
                } header: {
                    Text("桌面显示")
                } footer: {
                    Text("小、中、大三种尺寸都显示这里选中的模板，改动会自动同步到桌面。")
                }

                Section("设置") {
                    NavigationLink {
                        ShiftCalendarEditorView()
                    } label: {
                        entryRow(
                            symbol: "calendar.badge.clock",
                            tint: [Color(hex: "#5EDBC5"), Color(hex: "#739BFF")],
                            title: "倒班日历",
                            subtitle: "\(shiftConfig.cycle.count) 天循环 · \(shiftConfig.style.label)"
                        )
                    }

                    NavigationLink {
                        TextCardEditorView()
                    } label: {
                        entryRow(
                            symbol: "text.quote",
                            tint: [Color(hex: "#FF9F0A"), Color(hex: "#FF6B6B")],
                            title: "文字卡片",
                            subtitle: textConfig.title + " · " + textConfig.message
                        )
                    }

                    NavigationLink {
                        CounterEditorView()
                    } label: {
                        entryRow(
                            symbol: "number.circle.fill",
                            tint: [Color(hex: "#AF52DE"), Color(hex: "#5B8DEF")],
                            title: "计数器",
                            subtitle: "\(settings.counterTitle) \(settings.counterValue) \(settings.counterUnit)"
                        )
                    }
                }

                Section("其他") {
                    NavigationLink {
                        DiagnosticsView()
                    } label: {
                        entryRow(
                            symbol: "stethoscope",
                            tint: [Color(hex: "#8E8E93"), Color(hex: "#48484A")],
                            title: "诊断",
                            subtitle: "扩展状态 · 共享存储 · 版本信息"
                        )
                    }
                }
            }
            .navigationTitle("Widget Studio")
            .onAppear(perform: reload)
            .onChange(of: settings) { _, _ in SharedStore.save(settings) }
            .onChange(of: textConfig) { _, _ in SharedStore.save(textConfig) }
        }
    }

    // MARK: - 预览

    private var previewCanvas: some View {
        GeometryReader { geo in
            let scale = min(1, geo.size.width / 338)

            HStack {
                Spacer(minLength: 0)
                widgetPreview
                    .frame(width: 338, height: 158)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                    .scaleEffect(scale)
                    .frame(width: 338 * scale, height: 158 * scale)
                Spacer(minLength: 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: 158)
    }

    @ViewBuilder
    private var widgetPreview: some View {
        switch settings.template {
        case .shiftCalendar:
            ShiftCalendarView(config: shiftConfig, date: Date(), familyOverride: .systemMedium)
        case .textCard:
            TextCardView(config: textConfig)
        case .counter:
            CounterCardView(
                title: settings.counterTitle,
                value: settings.counterValue,
                unit: settings.counterUnit,
                hex: textConfig.themeHex,
                family: .systemMedium
            )
        }
    }

    // MARK: - 模板选择

    private var templatePicker: some View {
        HStack(spacing: 8) {
            ForEach(StudioTemplate.allCases) { template in
                Button {
                    settings.template = template
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: template.symbolName)
                            .font(.system(size: 17, weight: .semibold))
                        Text(template.label)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundStyle(settings.template == template ? Color.white : Color.primary)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(settings.template == template
                                  ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "#5B8DEF"), Color(hex: "#AF52DE")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                  : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.primary.opacity(settings.template == template ? 0 : 0.06), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - 列表行

    private func entryRow(symbol: String, tint: [Color], title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(LinearGradient(colors: tint, startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func reload() {
        settings = SharedStore.loadSettings()
        textConfig = SharedStore.load()
        shiftConfig = SharedStore.loadShiftCalendar()
    }
}

#Preview {
    ContentView()
}
