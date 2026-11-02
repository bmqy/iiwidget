import SwiftUI
import WidgetKit

/// 不依赖 AppIntent / App Group 的最小实现，用来判断扩展能否交付时间线。
/// 如果这个能显示，说明问题出在 AppIntent 配置链路；如果它也是占位图，说明是签名/扩展注册问题。
struct StudioProbeEntry: TimelineEntry {
    let date: Date
}

struct StudioProbeProvider: TimelineProvider {
    func placeholder(in context: Context) -> StudioProbeEntry {
        StudioProbeEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (StudioProbeEntry) -> Void) {
        completion(StudioProbeEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StudioProbeEntry>) -> Void) {
        let now = Date()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [StudioProbeEntry(date: now)], policy: .after(next)))
    }
}

struct StudioProbeView: View {
    var entry: StudioProbeEntry

    private var cycle: [String] { ["白班", "白班", "休息", "休息"] }

    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }

    private var todayShift: String {
        let anchor = cal.startOfDay(for: Date())
        let epoch = cal.startOfDay(for: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? anchor)
        let diff = cal.dateComponents([.day], from: epoch, to: anchor).day ?? 0
        return cycle[((diff % cycle.count) + cycle.count) % cycle.count]
    }

        var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#1B2B49"), Color(hex: "#17384A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Circle().fill(Color(hex: "#5EDBC5")).frame(width: 8, height: 8)
                    Text("扩展自检 · 能看见我就说明时间线正常")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                Text(todayShift)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("probe · v1.9")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct StudioProbeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StudioProbeWidget", provider: StudioProbeProvider()) { entry in
            StudioProbeView(entry: entry)
        }
        .configurationDisplayName("扩展自检（无参数）")
        .description("不带任何配置项，用来确认小组件扩展是否真的在运行。")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
