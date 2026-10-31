import WidgetKit
import SwiftUI
import AppIntents

/// 无需 App Group 也能用的模板：内容通过系统小组件配置界面设置。
struct CounterConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "计数器设置"

    @Parameter(title: "标题", default: "已坚持")
    var title: String

    @Parameter(title: "数值", default: 7)
    var value: Int

    @Parameter(title: "单位", default: "天")
    var unit: String

    @Parameter(title: "配色", default: "#FF6B6B")
    var colorHex: String

    init() {}
}

struct CounterEntry: TimelineEntry {
    let date: Date
    let config: CounterConfigIntent
}

struct CounterProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CounterEntry {
        CounterEntry(date: Date(), config: CounterConfigIntent())
    }

    func snapshot(for configuration: CounterConfigIntent, in context: Context) async -> CounterEntry {
        CounterEntry(date: Date(), config: configuration)
    }

    func timeline(for configuration: CounterConfigIntent, in context: Context) async -> Timeline<CounterEntry> {
        Timeline(entries: [CounterEntry(date: Date(), config: configuration)], policy: .never)
    }
}

struct CounterView: View {
    var config: CounterConfigIntent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(config.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(config.value)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text(config.unit)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
    }
}

struct CounterWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CounterWidget",
            intent: CounterConfigIntent.self,
            provider: CounterProvider()
        ) { entry in
            CounterView(config: entry.config)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(hex: entry.config.colorHex), Color(hex: entry.config.colorHex).opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("计数器")
        .description("显示天数 / 次数，长按小组件可直接修改内容。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
