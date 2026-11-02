import SwiftUI

struct TextCardEditorView: View {
    @State private var config: TextCardConfig = SharedStore.load()

    private let symbols = [
        "sparkles", "heart.fill", "flame.fill", "leaf.fill", "moon.stars.fill",
        "sun.max.fill", "bolt.fill", "star.fill", "drop.fill", "book.fill"
    ]

    private let palettes = [
        "#5B8DEF", "#FF6B6B", "#34C759", "#FF9F0A",
        "#AF52DE", "#00C7BE", "#FF375F", "#3A3A3C"
    ]

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer(minLength: 0)
                    TextCardView(config: config)
                        .frame(width: 338, height: 158)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                        .scaleEffect(0.94)
                        .frame(height: 152)
                    Spacer(minLength: 0)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 8))
            } header: {
                Text("预览")
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
                                .font(.system(size: 19))
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

            Section {
                Picker("样式", selection: $config.style) {
                    ForEach(TextCardStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("样式")
            }
        }
        .navigationTitle("文字卡片")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: config) { _, newValue in
            SharedStore.save(newValue)
        }
    }
}
