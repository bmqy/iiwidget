import Foundation
import WidgetKit

// MARK: - 文字卡片

enum TextCardStyle: String, CaseIterable, Codable, Identifiable {
    case gradient
    case solid
    case glass

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gradient: return "渐变"
        case .solid: return "纯色"
        case .glass: return "毛玻璃"
        }
    }
}

struct TextCardConfig: Codable, Equatable {
    var title: String = "今天也要"
    var message: String = "好好生活"
    var symbol: String = "sparkles"
    var themeHex: String = "#5B8DEF"
    var styleRaw: String = TextCardStyle.gradient.rawValue

    var style: TextCardStyle {
        get { TextCardStyle(rawValue: styleRaw) ?? .gradient }
        set { styleRaw = newValue.rawValue }
    }

    static let placeholder = TextCardConfig()
}

// MARK: - 倒班日历

enum ShiftCalendarStyle: String, CaseIterable, Codable, Identifiable {
    case aurora
    case editorial
    case soft

    var id: String { rawValue }

    var label: String {
        switch self {
        case .aurora: return "极光"
        case .editorial: return "简约"
        case .soft: return "柔和"
        }
    }
}

struct ShiftCalendarConfig: Codable, Equatable {
    /// 循环班次顺序；例如「白班、夜班、休息、休息」。
    var cycle: [String] = ["白班", "夜班", "休息", "休息"]
    /// 锚点日期当天对应 cycle[0]，用自然日计算，避免时区/DST 偏移。
    var anchorDate: Date = Calendar.current.startOfDay(for: Date())
    var styleRaw: String = ShiftCalendarStyle.aurora.rawValue

    var style: ShiftCalendarStyle {
        get { ShiftCalendarStyle(rawValue: styleRaw) ?? .aurora }
        set { styleRaw = newValue.rawValue }
    }

    static let placeholder = ShiftCalendarConfig()

    func shift(on date: Date, calendar: Calendar = .current) -> String {
        guard !cycle.isEmpty else { return "休息" }
        let start = calendar.startOfDay(for: anchorDate)
        let target = calendar.startOfDay(for: date)
        let diff = calendar.dateComponents([.day], from: start, to: target).day ?? 0
        let index = ((diff % cycle.count) + cycle.count) % cycle.count
        return cycle[index]
    }

    func isRest(_ shift: String) -> Bool {
        let value = shift.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return ["休", "休息", "休班", "公休", "调休", "假"].contains(value)
    }

    func colorIndex(for shift: String) -> Int {
        if isRest(shift) { return -1 }
        return cycle.firstIndex(of: shift) ?? 0
    }
}

// MARK: - 小组件模板

enum StudioTemplate: String, CaseIterable, Codable, Identifiable {
    case shiftCalendar
    case textCard
    case counter

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shiftCalendar: return "倒班日历"
        case .textCard: return "文字卡片"
        case .counter: return "计数器"
        }
    }

    var symbolName: String {
        switch self {
        case .shiftCalendar: return "calendar.badge.clock"
        case .textCard: return "text.quote"
        case .counter: return "number.circle.fill"
        }
    }
}

struct StudioSettings: Codable, Equatable {
    var templateRaw: String = StudioTemplate.shiftCalendar.rawValue
    var counterTitle: String = "已坚持"
    var counterValue: Int = 7
    var counterUnit: String = "天"

    var template: StudioTemplate {
        get { StudioTemplate(rawValue: templateRaw) ?? .shiftCalendar }
        set { templateRaw = newValue.rawValue }
    }

    static let fallback = StudioSettings()
}

// MARK: - App Group 共享存储

enum SharedStore {
    /// 需要和开发者账号里注册的 App Group 完全一致。
    static let appGroupID = "group.com.miniwidgets.shared"
    private static let textCardKey = "textcard.config.v1"
    private static let shiftCalendarKey = "shiftcalendar.config.v1"
    private static let settingsKey = "studio.settings.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// App Group 容器是否真的可用（免费 Apple ID 签名通常拿不到）。
    static var isAppGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) != nil
    }

    static func load() -> TextCardConfig {
        guard let data = defaults.data(forKey: textCardKey),
              let config = try? JSONDecoder().decode(TextCardConfig.self, from: data)
        else { return TextCardConfig() }
        return config
    }

    static func save(_ config: TextCardConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: textCardKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 供小组件进程使用的纯默认值：不触碰共享容器，任何签名方式都安全。
    static func safeSettings() -> StudioSettings { .fallback }

    static func loadSettings() -> StudioSettings {
        guard let data = defaults.data(forKey: settingsKey),
              var settings = try? JSONDecoder().decode(StudioSettings.self, from: data)
        else { return .fallback }
        settings.counterTitle = String(settings.counterTitle.prefix(12))
        settings.counterUnit = String(settings.counterUnit.prefix(6))
        return settings
    }

    static func save(_ settings: StudioSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func loadShiftCalendar() -> ShiftCalendarConfig {
        guard let data = defaults.data(forKey: shiftCalendarKey),
              var config = try? JSONDecoder().decode(ShiftCalendarConfig.self, from: data)
        else { return .placeholder }
        config.cycle = Self.normalizedCycle(config.cycle)
        return config
    }

    static func saveShiftCalendar(_ config: ShiftCalendarConfig) {
        var safeConfig = config
        safeConfig.cycle = Self.normalizedCycle(config.cycle)
        guard let data = try? JSONEncoder().encode(safeConfig) else { return }
        defaults.set(data, forKey: shiftCalendarKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func normalizedCycle(_ cycle: [String]) -> [String] {
        let cleaned = cycle.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(8)) }
            .filter { !$0.isEmpty }
        return Array((cleaned.isEmpty ? ["白班", "夜班", "休息", "休息"] : cleaned).prefix(14))
    }
}
