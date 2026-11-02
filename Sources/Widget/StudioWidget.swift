import SwiftUI
import WidgetKit

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
    let sharedAvailable: Bool

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
        // 必须用 context.family，否则组件图库里大号预览会画成中号布局。
        StudioEntry(date: Date(), family: context.family)
    }

    func getSnapshot(in context: Context, completion: @escaping (StudioEntry) -> Void) {
        completion(StudioEntry(date: Date(), family: context.family))
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
        content
            .overlay(alignment: .topTrailing) {
                if !entry.sharedAvailable {
                    Text("共享未启用")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color(hex: "#FF3B30")))
                        .padding(6)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
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
        .configurationDisplayName("Mini Widgets")
        .description("先在 App 里选好要显示的模板，再添加这个小组件。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
