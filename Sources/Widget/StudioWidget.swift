import SwiftUI
import WidgetKit

// MARK: - 计数器卡片

struct CounterCardView: View {
    var title: String
    var value: Int
    var unit: String
    var hex: String
    var family: WidgetFamily = .systemSmall

    var body: some View {
        let tint = Color(hex: hex)
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: family == .systemSmall ? 38 : 30, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.system(size: 13, weight: .medium))
                    .opacity(0.9)
            }
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
        .background(
            LinearGradient(colors: [tint, tint.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}

// MARK: - Timeline（条目只存纯数据，不把 AppIntent 塞进 TimelineEntry）

struct StudioEntry: TimelineEntry {
    let date: Date
    let family: WidgetFamily
    let template: StudioTemplate
    let textConfig: TextCardConfig
    let counterTitle: String
    let counterValue: Int
    let counterUnit: String
    let themeHex: String
    let shiftConfig: ShiftCalendarConfig

    init(date: Date, intent: StudioIntent, family: WidgetFamily) {
        self.date = date
        self.family = family
        self.template = intent.template
        self.textConfig = StudioResolver.textConfig(for: intent)
        self.counterTitle = intent.title
        self.counterValue = intent.count
        self.counterUnit = intent.unit
        self.themeHex = intent.theme.hex
        self.shiftConfig = StudioResolver.shiftConfig(for: intent)
    }

    static var fallback: StudioEntry {
        StudioEntry(date: Date(), intent: StudioIntent(), family: .systemSmall)
    }
}

struct StudioEntryView: View {
    let entry: StudioEntry

    var body: some View {
        switch entry.template {
        case .textCard:
            TextCardView(config: entry.textConfig)
        case .counter:
            CounterCardView(
                title: entry.counterTitle,
                value: entry.counterValue,
                unit: entry.counterUnit,
                hex: entry.themeHex,
                family: entry.family
            )
        case .shiftCalendar:
            ShiftCalendarView(config: entry.shiftConfig, date: entry.date, familyOverride: entry.family)
        }
    }
}

struct StudioProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StudioEntry {
        StudioEntry.fallback
    }

    func snapshot(for configuration: StudioIntent, in context: Context) async -> StudioEntry {
        StudioEntry(date: Date(), intent: configuration, family: context.family)
    }

    func timeline(for configuration: StudioIntent, in context: Context) async -> Timeline<StudioEntry> {
        let now = Date()
        let calendar = Calendar.current
        var entries = [StudioEntry(date: now, intent: configuration, family: context.family)]
        if configuration.template == .shiftCalendar,
           let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            entries.append(StudioEntry(date: tomorrow, intent: configuration, family: context.family))
        }
        let refresh = calendar.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(21_600)
        return Timeline(entries: entries, policy: .after(refresh))
    }
}

// MARK: - Widget

struct StudioWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "StudioWidget", intent: StudioIntent.self, provider: StudioProvider()) { entry in
            StudioEntryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Widget Studio")
        .description("添加后长按小组件 → 编辑小组件，可选文字卡片 / 计数器 / 倒班日历。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
