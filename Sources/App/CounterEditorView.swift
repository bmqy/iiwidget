import SwiftUI

struct CounterEditorView: View {
    @State private var settings: StudioSettings = SharedStore.loadSettings()
    @State private var textConfig: TextCardConfig = SharedStore.load()

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer(minLength: 0)
                    CounterCardView(
                        title: settings.counterTitle,
                        value: settings.counterValue,
                        unit: settings.counterUnit,
                        hex: textConfig.themeHex,
                        family: .systemMedium
                    )
                    .frame(width: 300, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                    Spacer(minLength: 0)
                }
                .listRowInsets(EdgeInsets(top: 14, leading: 8, bottom: 14, trailing: 8))
            } header: {
                Text("预览")
            }

            Section {
                TextField("标题", text: $settings.counterTitle)
                Stepper(value: $settings.counterValue, in: -9999...99999) {
                    HStack {
                        Text("数值")
                        Spacer()
                        Text("\(settings.counterValue)").foregroundStyle(.secondary)
                    }
                }
                TextField("单位", text: $settings.counterUnit)
            } header: {
                Text("内容")
            } footer: {
                Text("配色取自「文字卡片」设置里的主题色，改那边即可。")
            }
        }
        .navigationTitle("计数器")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings) { _, newValue in
            SharedStore.save(newValue)
        }
    }
}
