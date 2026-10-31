import SwiftUI

struct ContentView: View {
    @State private var config: TextCardConfig = SharedStore.load()
    @State private var showSaved = false

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
                Section("预览") {
                    TextCardView(config: config)
                        .frame(height: 172)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                Section("内容") {
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
                        Text("保存到桌面小组件")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                } footer: {
                    Text("保存后回到桌面，长按空白处 → 左上角「+」→ 搜索 Widget Studio，添加「文字卡片」即可。")
                }
            }
            .navigationTitle("Widget Studio")
            .alert("已保存", isPresented: $showSaved) {
                Button("好", role: .cancel) {}
            } message: {
                Text("小组件已刷新，如果没变化请等几秒或重新添加一次。")
            }
        }
    }

    private func save() {
        SharedStore.save(config)
        showSaved = true
    }
}

#Preview {
    ContentView()
}
