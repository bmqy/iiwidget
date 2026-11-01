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

// MARK: - 数据快照

struct StudioEntry: TimelineEntry {
    let date: Date
    let family: WidgetFamily
    let template: StudioTemplate
    let textConfig: TextCardConfig
    let counterTitle: String
    let counterValue: Int
    let counterUnit: String
    let shiftConfig: ShiftCalendarConfig

    init(date: Date, family: WidgetFamily) {
        self.date = date
        self.family = family
        let settings = SharedStore.loadSettings()
        let text = SharedStore.load()
        let shift = SharedStore.loadShiftCalendar()
        self.template = settings.template
        self.textConfig = text
        self.counterTitle = settings.counterTitle
        self.counterValue = settings.counterValue
        self.counterUnit = settings.counterUnit
        self.shiftConfig = shift
    }
}

struct StudioProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudioEntry {
        StudioEntry(date: Date(), family: .systemMedium)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudioEntry) -> Void) {
        completion(StudioEntry(date: Date(), family: .systemMedium))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudioEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        var entries = [StudioEntry(date: now, family: context.family)]
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) {
            entries.append(StudioEntry(date: tomorrow, family: context.family))
        }
        let refresh = calendar.date(byAdding: .hour, value: 3, to: now) ?? now.addingTimeInterval(10_800)
        completion(Timeline(entries: entries, policy: .after(refresh)))
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
                hex: entry.textConfig.themeHex,
                family: entry.family
            )
        case .shiftCalendar:
            ShiftCalendarView(config: entry.shiftConfig, date: entry.date, familyOverride: entry.family)
        }
    }
}

// MARK: - Widget

struct StudioWidget: Widget {
    var body: some WidgetConfiguration {
        // 使用 StaticConfiguration：不依赖 AppIntents，
        // TrollStore / 免费签名 / 付费账号都能正常交付时间线。
        StaticConfiguration(kind: "StudioWidget", provider: StudioProvider()) { entry in
            StudioEntryView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Widget Studio")
        .description("先在 App 里选好要显示的模板，再添加这个小组件。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
