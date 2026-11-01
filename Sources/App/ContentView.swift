import SwiftUI

struct ContentView: View {
    @State private var settings = SharedStore.loadSettings()
    @State private var config: TextCardConfig = SharedStore.load()
    @State private var showSaved = false
    @State private var showShiftCalendar = false

    private let symbols = [
        "sparkles", "heart.fill", "flame.fill", "leaf.fill", "moon.stars.fill",
        "sun.max.fill", "bolt.fill", "star.fill", "drop.fill", "book.fill"
    ]

    private let palettes = [
        "#5B8DEF", "#FF6B6B", "#34C759", "#FF9F0A",
        "#AF52DE", "#00C7BE", "#FF375F", "#3A3A3C"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("桌面显示", selection: $settings.template) {
                        ForEach(StudioTemplate.allCases) { template in
                            Label(template.label, systemImage: template.symbolName).tag(template)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    if settings.template == .counter {
                        TextField("标题", text: $settings.counterTitle)
                        Stepper(value: $settings.counterValue, in: -9999...99999) {
                            HStack {
                                Text("数值")
                                Spacer()
                                Text("\(settings.counterValue)").foregroundStyle(.secondary)
                            }
                        }
                        TextField("单位", text: $settings.counterUnit)
                    }
                } header: {
                    Text("桌面小组件显示")
                } footer: {
                    Text("小、中、大三种尺寸都显示这里选中的模板，改完自动刷新桌面。")
                }

                Section("小组件模板") {
                    Button {
                        showShiftCalendar = true
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(LinearGradient(colors: [Color(hex: "#5EDBC5"), Color(hex: "#739BFF")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("倒班日历设置")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("排班循环 · 日历风格 · 三尺寸预览")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                }

                Section("文字卡片预览") {
                    TextCardView(config: config)
                        .frame(height: 172)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                Section("文字内容") {
                    TextField("标题", text: $config.title)
                    TextField("正文", text: $config.message, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("图标") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                        ForEach(symbols, id: \.self) { name in
                            Button {
                                config.symbol = name
                            } label: {
                                Image(systemName: name)
                                    .font(.system(size: 20))
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .foregroundStyle(config.symbol == name ? Color.white : Color.primary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(config.symbol == name ? Color.accentColor : Color.secondary.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("配色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 8), spacing: 12) {
                        ForEach(palettes, id: \.self) { hex in
                            Button {
                                config.themeHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(height: 30)
                                    .overlay(
                                        Circle().strokeBorder(Color.primary.opacity(config.themeHex == hex ? 0.6 : 0), lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("样式") {
                    Picker("样式", selection: Binding(
                        get: { config.style },
                        set: { config.style = $0 }
                    )) {
                        ForEach(TextCardStyle.allCases) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        save()
                    } label: {
                        Text("保存全部设置")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                } footer: {
                    Text("保存后回到桌面：长按空白处 → 左上角「+」→ 搜索 Widget Studio → 选尺寸添加。")
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"))
                        Text("build " + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"))
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } footer: {
                    Text("若这里的版本不是最新的，说明装的是旧包，请重新签名安装。")
                }
            }
            .navigationTitle("Widget Studio")
            .navigationDestination(isPresented: $showShiftCalendar) {
                ShiftCalendarEditorView()
            }
            .alert("已保存", isPresented: $showSaved) {
                Button("好", role: .cancel) {}
            } message: {
                Text("小组件已刷新，如果没变化请等几秒。")
            }
            .onChange(of: settings) { _, _ in
                SharedStore.save(settings)
            }
            .onChange(of: config) { _, _ in
                SharedStore.save(config)
            }
        }
    }

    private func save() {
        SharedStore.save(settings)
        SharedStore.save(config)
        showSaved = true
    }
}

#Preview {
    ContentView()
}
