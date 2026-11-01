import SwiftUI
import WidgetKit

private enum ShiftColors {
    static let ink = Color(hex: "#17263C")
    static let muted = Color(hex: "#8492A6")
    static let work: [Color] = [
        Color(hex: "#5EDBC5"), Color(hex: "#FF8B7B"), Color(hex: "#739BFF"),
        Color(hex: "#AD91FF"), Color(hex: "#F7BF67"), Color(hex: "#F18FC4")
    ]
    static let editorial: [Color] = [
        Color(hex: "#477D78"), Color(hex: "#CF755A"), Color(hex: "#6889B3"),
        Color(hex: "#9074AE"), Color(hex: "#B28B45"), Color(hex: "#B56788")
    ]
    static let soft: [Color] = [
        Color(hex: "#5AB7A8"), Color(hex: "#F18777"), Color(hex: "#7195E8"),
        Color(hex: "#9B7DD4"), Color(hex: "#E4A64F"), Color(hex: "#DF83AE")
    ]
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

    // MARK: 日期计算

    private var monthStart: Date {
        cal.dateInterval(of: .month, for: date)?.start ?? date
    }

    private var monthDays: [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: monthStart) else { return [] }
        let lead = (cal.component(.weekday, from: monthStart) - cal.firstWeekday + 7) % 7
        var values = Array<Date?>(repeating: nil, count: lead)
        for day in range {
            values.append(cal.date(byAdding: .day, value: day - 1, to: monthStart))
        }
        while values.count % 7 != 0 { values.append(nil) }
        return values
    }

    private var weekDays: [Date] {
        let today = cal.startOfDay(for: date)
        let offset = (cal.component(.weekday, from: today) - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -offset, to: today) ?? today
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    /// 固定 6 行 42 天：包含前后月的日期，当月为主，前后月淡化显示。
    private var gridDays: [Date] {
        guard let firstOfMonth = cal.dateInterval(of: .month, for: date)?.start else { return [] }
        let lead = (cal.component(.weekday, from: firstOfMonth) - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -lead, to: firstOfMonth) ?? firstOfMonth
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private var gridRows: [[Date]] {
        let days = gridDays
        guard !days.isEmpty else { return [] }
        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
    }

    private var monthRows: [[Date?]] {
        let days = monthDays
        guard !days.isEmpty else { return [] }
        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }

    private let weekdaySymbols = ["一", "二", "三", "四", "五", "六", "日"]

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月"
        return f.string(from: monthStart)
    }

    private var todayTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日·EEEE"
        return f.string(from: date)
    }

    private var tomorrowDate: Date {
        cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: date)) ?? date
    }

    private var tomorrowShift: String { config.shift(on: tomorrowDate, calendar: cal) }

    private func dateLabel(for day: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 · EEE"
        return f.string(from: day)
    }

    private func shortDay(for day: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M/d"
        return f.string(from: day)
    }

    private var todayShift: String { config.shift(on: date, calendar: cal) }

    private var accentToday: Color { shiftColor(todayShift) }
    private var isRestToday: Bool { config.isRest(todayShift) }

    // MARK: 配色

    private var isDark: Bool { config.style == .aurora }
    private var primaryText: Color { isDark ? .white : ShiftColors.ink }
    private var secondaryText: Color { isDark ? Color.white.opacity(0.6) : ShiftColors.muted }

    private func shiftColor(_ shift: String) -> Color {
        if config.isRest(shift) {
            return config.style == .editorial ? Color(hex: "#C8BDAA") : Color(hex: "#A9B6C6")
        }
        let index = config.colorIndex(for: shift)
        switch config.style {
        case .editorial: return ShiftColors.editorial[index % 6]
        case .soft: return ShiftColors.soft[index % 6]
        case .aurora: return ShiftColors.work[index % 6]
        }
    }

    private func weekdayIndex(_ day: Date) -> Int {
        let value = cal.component(.weekday, from: day)
        return value == 1 ? 6 : value - 2
    }

    // MARK: 背景

    @ViewBuilder
    private var backgroundView: some View {
        switch config.style {
        case .aurora:
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "#1B2B49"), Color(hex: "#263B58"), Color(hex: "#17384A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color(hex: "#5EDBC5").opacity(0.16))
                    .frame(width: 150, height: 150)
                    .blur(radius: 34)
                    .offset(x: 120, y: -110)
                Circle()
                    .fill(Color(hex: "#AD91FF").opacity(0.13))
                    .frame(width: 130, height: 130)
                    .blur(radius: 32)
                    .offset(x: -110, y: 110)
            }
        case .editorial:
            Color(hex: "#F3F0E9")
        case .soft:
            LinearGradient(
                colors: [Color(hex: "#F7F0FF"), Color(hex: "#EEF6FF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ZStack {
            backgroundView
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall: smallView
        case .systemMedium: mediumView
        default: largeView
        }
    }

    // MARK: 小尺寸 —— 今日 + 本周

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(dateLabel(for: date))
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 2)
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(accentToday)
            }

            Spacer(minLength: 8)

            HStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(accentToday)
                    .frame(width: 3, height: 12)
                Text("今天")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(secondaryText)
            }
            Text(todayShift)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .padding(.top, 3)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Circle()
                    .fill(shiftColor(tomorrowShift))
                    .frame(width: 7, height: 7)
                Text("明天")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(secondaryText)
                Text(tomorrowShift)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 0)
                Text(shortDay(for: tomorrowDate))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(secondaryText)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(isDark ? 0.09 : 0.55))
            }
        }
        .padding(13)
    }

    // MARK: 中尺寸 —— 今日 + 一周班次 + 图例

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(todayTitle)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                    Text(isRestToday ? "今日 · 休息日" : "今日 · \(todayShift)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 2)
                Text(monthTitle)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(secondaryText)
                    .lineLimit(1)
            }

            HStack(spacing: 5) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { _, day in
                    weekCell(day, compact: false)
                }
            }

            HStack(spacing: 5) {
                Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.system(size: 7.5, weight: .semibold))
                Text("\(config.cycle.count)天循环")
                    .font(.system(size: 8.5, weight: .medium))
                Spacer(minLength: 0)
                ForEach(Array(config.cycle.enumerated()), id: \.offset) { _, shift in
                    HStack(spacing: 2.5) {
                        Circle().fill(shiftColor(shift)).frame(width: 5, height: 5)
                        Text(shift)
                            .font(.system(size: 8, weight: .medium))
                            .lineLimit(1)
                    }
                }
            }
            .foregroundStyle(secondaryText)
        }
        .padding(13)
    }

    // MARK: 大尺寸 —— 整月日历

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(monthTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(primaryText)
                    Text(todayTitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(secondaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(isRestToday ? "今日休息" : "今日班次")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(secondaryText)
                    shiftPill(todayShift, fontSize: 14)
                }
            }

            HStack(spacing: 2) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundStyle(secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 4) {
                ForEach(Array(gridRows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 3) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, day in
                            monthCell(day, inMonth: cal.isDate(day, equalTo: monthStart, toGranularity: .month))
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 10) {
                ForEach(Array(config.cycle.enumerated()), id: \.offset) { _, shift in
                    HStack(spacing: 3.5) {
                        Circle().fill(shiftColor(shift)).frame(width: 6, height: 6)
                        Text(shift)
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundStyle(secondaryText)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(14)
    }

    // MARK: 组件

    private func shiftPill(_ shift: String, fontSize: CGFloat) -> some View {
        Text(shift)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundStyle(isDark ? Color(hex: "#0F2A34") : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(shiftColor(shift)))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private func weekCell(_ day: Date, compact: Bool) -> some View {
        let shift = config.shift(on: day, calendar: cal)
        let today = cal.isDate(day, inSameDayAs: date)
        let color = shiftColor(shift)
        return VStack(spacing: compact ? 3 : 5) {
            Text(weekdaySymbols[weekdayIndex(day)])
                .font(.system(size: compact ? 7.5 : 8.5, weight: .medium))
                .foregroundStyle(today ? primaryText : secondaryText)
            Text("\(cal.component(.day, from: day))")
                .font(.system(size: compact ? 11 : 14, weight: today ? .bold : .semibold, design: .rounded))
                .foregroundStyle(today ? (isDark ? Color(hex: "#0F2A34") : .white) : primaryText)
            Text(config.isRest(shift) ? "休" : (compact ? String(shift.prefix(2)) : shift))
                .font(.system(size: compact ? 6.5 : 8, weight: .bold))
                .foregroundStyle(today ? (isDark ? Color(hex: "#0F2A34") : .white) : (config.isRest(shift) ? secondaryText : color))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if !compact {
                Circle()
                    .fill(config.isRest(shift) ? Color.clear : color)
                    .frame(width: 4, height: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 42 : 64)
        .background {
            RoundedRectangle(cornerRadius: compact ? 8 : 12, style: .continuous)
                .fill(cellFill(shift: shift, today: today, color: color))
        }
    }

    @ViewBuilder
    private func monthCell(_ day: Date, inMonth: Bool) -> some View {
        let shift = config.shift(on: day, calendar: cal)
        let today = cal.isDate(day, inSameDayAs: date)
        let color = shiftColor(shift)
        let alpha: Double = inMonth ? 1 : 0.35
        return VStack(spacing: 2) {
            Text("\(cal.component(.day, from: day))")
                .font(.system(size: 13, weight: today ? .bold : .semibold, design: .rounded))
                .foregroundStyle(today ? (isDark ? Color(hex: "#0F2A34") : .white) : primaryText.opacity(alpha))
            Text(config.isRest(shift) ? "休" : String(shift.prefix(3)))
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(today
                                 ? (isDark ? Color(hex: "#0F2A34") : .white)
                                 : (config.isRest(shift) ? secondaryText.opacity(alpha) : color.opacity(alpha)))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(cellFill(shift: shift, today: today, color: color).opacity(inMonth ? 1 : 0.4))
        }
    }

    private func cellFill(shift: String, today: Bool, color: Color) -> Color {
        if today { return color }
        if config.isRest(shift) {
            return Color.white.opacity(isDark ? 0.06 : 0.55)
        }
        return color.opacity(isDark ? 0.18 : 0.14)
    }
}
