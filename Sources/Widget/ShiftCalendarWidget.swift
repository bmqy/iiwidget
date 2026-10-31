import SwiftUI
import WidgetKit

private enum ShiftColors {
    static let ink = Color(hex: "#17263C")
    static let muted = Color(hex: "#8492A6")
    static let work: [Color] = [Color(hex: "#5EDBC5"), Color(hex: "#FF8B7B"), Color(hex: "#739BFF"), Color(hex: "#AD91FF"), Color(hex: "#F7BF67"), Color(hex: "#F18FC4")]
}

struct ShiftCalendarView: View {
    var config: ShiftCalendarConfig
    var date: Date = Date()
    var familyOverride: WidgetFamily? = nil
    @Environment(\.calendar) private var envCalendar
    @Environment(\.widgetFamily) private var widgetFamily

    private var family: WidgetFamily { familyOverride ?? widgetFamily }
    private var cal: Calendar {
        var c = envCalendar
        c.firstWeekday = 2
        return c
    }
    private var monthStart: Date { cal.dateInterval(of: .month, for: date)?.start ?? date }
    private var days: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }
        let lead = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7
        var result = Array<Date?>(repeating: nil, count: lead)
        for day in range {
            result.append(cal.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }
    private var week: [Date] {
        let today = cal.startOfDay(for: date)
        let offset = (cal.component(.weekday, from: today) - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -offset, to: today) ?? today
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
    private let weekdays = ["一", "二", "三", "四", "五", "六", "日"]
    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "yyyy年 M月"
        return f.string(from: monthStart)
    }
    private var todayTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "M月d日 · EEEE"
        return f.string(from: date)
    }
    private var todayShift: String { config.shift(on: date, calendar: cal) }
    private var isRest: Bool { config.isRest(todayShift) }
    private var dark: Bool { config.style == .aurora }
    private var fg: Color { dark ? .white : ShiftColors.ink }
    private var secondary: Color { dark ? .white.opacity(0.58) : ShiftColors.muted }

    var body: some View {
        Group {
            if family == .systemSmall { smallView }
            else if family == .systemMedium { mediumView }
            else { largeView }
        }
        .containerBackground(for: .widget) { background }
    }

    @ViewBuilder private var background: some View {
        switch config.style {
        case .aurora:
            ZStack {
                LinearGradient(colors: [Color(hex: "#1B2B49"), Color(hex: "#263B58"), Color(hex: "#183B4B")], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(Color(hex: "#5EDBC5").opacity(0.15)).frame(width: 150).blur(radius: 32).offset(x: 120, y: -100)
                Circle().fill(Color(hex: "#AD91FF").opacity(0.12)).frame(width: 130).blur(radius: 30).offset(x: -110, y: 100)
            }
        case .editorial: Color(hex: "#F3F0E9")
        case .soft: LinearGradient(colors: [Color(hex: "#F7F0FF"), Color(hex: "#EEF6FF")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func shiftColor(_ shift: String) -> Color {
        if config.isRest(shift) { return config.style == .editorial ? Color(hex: "#C8BDAA") : Color(hex: "#AAB8C8") }
        let index = config.colorIndex(for: shift)
        if config.style == .editorial {
            return [Color(hex: "#477D78"), Color(hex: "#CF755A"), Color(hex: "#6889B3"), Color(hex: "#9074AE"), Color(hex: "#B28B45"), Color(hex: "#B56788")][index % 6]
        }
        if config.style == .soft {
            return [Color(hex: "#5AB7A8"), Color(hex: "#F18777"), Color(hex: "#7195E8"), Color(hex: "#9B7DD4"), Color(hex: "#E4A64F"), Color(hex: "#DF83AE")][index % 6]
        }
        return ShiftColors.work[index % 6]
    }
    private func weekdayIndex(_ day: Date) -> Int {
        let value = cal.component(.weekday, from: day)
        return value == 1 ? 6 : value - 2
    }
    private func dayTextColor(_ shift: String, today: Bool) -> Color {
        if today { return dark ? Color(hex: "#102C38") : .white }
        return config.isRest(shift) ? secondary : (dark ? .white.opacity(0.9) : shiftColor(shift))
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(monthTitle).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(fg)
                Spacer()
                Image(systemName: "calendar.badge.clock").font(.system(size: 12, weight: .semibold)).foregroundStyle(shiftColor(todayShift))
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(todayTitle).font(.system(size: 9, weight: .medium)).foregroundStyle(secondary).lineLimit(1)
                    Text(isRest ? "好好休息" : "今天上班").font(.system(size: 11, weight: .semibold)).foregroundStyle(fg)
                }
                Spacer(minLength: 2)
                shiftBadge(todayShift, size: 16)
            }
            HStack(spacing: 4) {
                ForEach(Array(week.enumerated()), id: \.offset) { _, day in weekCell(day, compact: true) }
            }
        }
        .padding(12)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(todayTitle).font(.system(size: 10, weight: .medium)).foregroundStyle(secondary)
                    Text(isRest ? "今日 · 休息日" : "今日 · \(todayShift)").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(fg)
                }
                Spacer()
                Text(monthTitle).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(secondary)
            }
            HStack(spacing: 6) {
                ForEach(Array(week.enumerated()), id: \.offset) { _, day in weekCell(day, compact: false) }
            }
            HStack(spacing: 5) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90").font(.system(size: 8, weight: .semibold))
                Text("\(config.cycle.count) 天循环").font(.system(size: 9, weight: .medium))
                Spacer()
                ForEach(Array(config.cycle.enumerated()), id: \.offset) { _, shift in
                    HStack(spacing: 3) { Circle().fill(shiftColor(shift)).frame(width: 5, height: 5); Text(shift).font(.system(size: 8, weight: .medium)).lineLimit(1) }
                }
            }.foregroundStyle(secondary)
        }
        .padding(14)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(monthTitle).font(.system(size: 19, weight: .bold, design: .rounded)).foregroundStyle(fg)
                    Text(todayTitle).font(.system(size: 10, weight: .medium)).foregroundStyle(secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(isRest ? "今日休息" : "今日班次").font(.system(size: 9, weight: .medium)).foregroundStyle(secondary)
                    shiftBadge(todayShift, size: 15)
                }
            }
            HStack(spacing: 3) {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                    Text(day).font(.system(size: 9, weight: .semibold)).foregroundStyle(secondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in monthCell(day) }
            }
            HStack(spacing: 10) {
                ForEach(Array(config.cycle.enumerated()), id: \.offset) { _, shift in
                    HStack(spacing: 4) { Circle().fill(shiftColor(shift)).frame(width: 6, height: 6); Text(shift).font(.system(size: 8, weight: .medium)).foregroundStyle(secondary).lineLimit(1) }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
    }

    private func shiftBadge(_ shift: String, size: CGFloat) -> some View {
        Text(shift).font(.system(size: size, weight: .bold, design: .rounded))
            .foregroundStyle(dark ? Color(hex: "#102C38") : fg)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(shiftColor(shift))).lineLimit(1).minimumScaleFactor(0.65)
    }

    private func weekCell(_ day: Date, compact: Bool) -> some View {
        let shift = config.shift(on: day, calendar: cal)
        let today = cal.isDate(day, inSameDayAs: date)
        return VStack(spacing: compact ? 3 : 5) {
            Text(weekdays[weekdayIndex(day)]).font(.system(size: compact ? 7 : 8, weight: .medium)).foregroundStyle(today ? fg : secondary)
            Text(compact ? "\(cal.component(.day, from: day))" : String(format: "%02d", cal.component(.day, from: day)))
                .font(.system(size: compact ? 10 : 13, weight: today ? .bold : .semibold, design: .rounded)).foregroundStyle(fg)
            Text(config.isRest(shift) ? "休" : (compact ? String(shift.prefix(2)) : shift))
                .font(.system(size: compact ? 6 : 8, weight: .bold)).foregroundStyle(dayTextColor(shift, today: today)).lineLimit(1).minimumScaleFactor(0.55)
            if !compact { Circle().fill(config.isRest(shift) ? Color.clear : shiftColor(shift)).frame(width: 4, height: 4) }
        }
        .frame(maxWidth: .infinity, minHeight: compact ? 43 : 70)
        .background(RoundedRectangle(cornerRadius: compact ? 9 : 13, style: .continuous)
            .fill(today ? shiftColor(shift) : (config.isRest(shift) ? Color.white.opacity(dark ? 0.06 : 0.55) : shiftColor(shift).opacity(dark ? 0.16 : 0.12))))
    }

    @ViewBuilder private func monthCell(_ day: Date?) -> some View {
        if let day {
            let shift = config.shift(on: day, calendar: cal)
            let today = cal.isDate(day, inSameDayAs: date)
            VStack(spacing: 2) {
                Text("\(cal.component(.day, from: day))").font(.system(size: 10, weight: today ? .bold : .medium, design: .rounded)).foregroundStyle(today && dark ? Color(hex: "#102C38") : fg)
                Text(config.isRest(shift) ? "休" : String(shift.prefix(3))).font(.system(size: 7, weight: .semibold)).foregroundStyle(dayTextColor(shift, today: today)).lineLimit(1).minimumScaleFactor(0.55)
            }
            .frame(maxWidth: .infinity, minHeight: 25)
            .background {
                if today { RoundedRectangle(cornerRadius: 8, style: .continuous).fill(shiftColor(shift)) }
                else if !config.isRest(shift) { RoundedRectangle(cornerRadius: 8, style: .continuous).fill(shiftColor(shift).opacity(dark ? 0.16 : 0.17)) }
            }
        } else { Color.clear.frame(maxWidth: .infinity, minHeight: 25) }
    }
}

struct ShiftCalendarEntry: TimelineEntry {
    let date: Date
    let config: ShiftCalendarConfig
}

struct ShiftCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShiftCalendarEntry { .init(date: Date(), config: .placeholder) }
    func getSnapshot(in context: Context, completion: @escaping (ShiftCalendarEntry) -> Void) {
        completion(.init(date: Date(), config: SharedStore.loadShiftCalendar()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ShiftCalendarEntry>) -> Void) {
        let now = Date()
        let config = SharedStore.loadShiftCalendar()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) ?? now.addingTimeInterval(86400)
        completion(Timeline(entries: [.init(date: now, config: config), .init(date: tomorrow, config: config)], policy: .after(Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(21600))))
    }
}

struct ShiftCalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ShiftCalendarWidget", provider: ShiftCalendarProvider()) { entry in
            ShiftCalendarView(config: entry.config, date: entry.date)
        }
        .configurationDisplayName("倒班日历")
        .description("自定义循环班次，周视图与月历风格随心选。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
