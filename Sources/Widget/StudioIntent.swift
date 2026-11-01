import AppIntents
import Foundation

// MARK: - 模板

enum StudioTemplate: String, AppEnum, CaseIterable {
    case textCard
    case counter
    case shiftCalendar

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "模板"
    static var caseDisplayRepresentations: [StudioTemplate: DisplayRepresentation] = [
        .textCard: "文字卡片",
        .counter: "计数器",
        .shiftCalendar: "倒班日历"
    ]
}

enum StudioTextSource: String, AppEnum, CaseIterable {
    case intent
    case app

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "文字内容来源"
    static var caseDisplayRepresentations: [StudioTextSource: DisplayRepresentation] = [
        .intent: "在这里直接填",
        .app: "用 App 里编辑的"
    ]
}

enum StudioSymbol: String, AppEnum, CaseIterable {
    case sparkles
    case heart
    case flame
    case leaf
    case moon
    case sun
    case bolt
    case star

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "图标"
    static var caseDisplayRepresentations: [StudioSymbol: DisplayRepresentation] = [
        .sparkles: "星光",
        .heart: "爱心",
        .flame: "火焰",
        .leaf: "叶子",
        .moon: "月亮",
        .sun: "太阳",
        .bolt: "闪电",
        .star: "星星"
    ]

    var name: String {
        switch self {
        case .sparkles: return "sparkles"
        case .heart: return "heart.fill"
        case .flame: return "flame.fill"
        case .leaf: return "leaf.fill"
        case .moon: return "moon.stars.fill"
        case .sun: return "sun.max.fill"
        case .bolt: return "bolt.fill"
        case .star: return "star.fill"
        }
    }
}

enum StudioTheme: String, AppEnum, CaseIterable {
    case blue
    case coral
    case green
    case amber
    case violet
    case teal
    case ink
    case rose

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "主题色"
    static var caseDisplayRepresentations: [StudioTheme: DisplayRepresentation] = [
        .blue: "海蓝",
        .coral: "珊瑚",
        .green: "常春藤",
        .amber: "琥珀",
        .violet: "紫罗兰",
        .teal: "青碧",
        .ink: "墨黑",
        .rose: "玫红"
    ]

    var hex: String {
        switch self {
        case .blue: return "#5B8DEF"
        case .coral: return "#FF6B6B"
        case .green: return "#34C759"
        case .amber: return "#FF9F0A"
        case .violet: return "#AF52DE"
        case .teal: return "#00C7BE"
        case .ink: return "#3A3A3C"
        case .rose: return "#FF375F"
        }
    }
}

// MARK: - 排班制预设

enum StudioRotation: String, AppEnum, CaseIterable {
    case appCustom
    case twoOnTwoOff
    case oneOnOneOff
    case twoShift
    case threeShift
    case fourThree

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "排班制"
    static var caseDisplayRepresentations: [StudioRotation: DisplayRepresentation] = [
        .appCustom: "App 内自定义",
        .twoOnTwoOff: "上二休二",
        .oneOnOneOff: "做一休一",
        .twoShift: "两班倒（白/夜）",
        .threeShift: "三班倒（早/中/夜）",
        .fourThree: "四班三运转"
    ]

    var cycle: [String] {
        switch self {
        case .appCustom: return ["白班", "夜班", "休息", "休息"]
        case .twoOnTwoOff: return ["白班", "白班", "休息", "休息"]
        case .oneOnOneOff: return ["白班", "休息"]
        case .twoShift: return ["白班", "夜班"]
        case .threeShift: return ["早班", "中班", "夜班"]
        case .fourThree: return ["早班", "中班", "夜班", "休息"]
        }
    }
}

enum StudioCalendarStyle: String, AppEnum, CaseIterable {
    case aurora
    case editorial
    case soft

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "日历风格"
    static var caseDisplayRepresentations: [StudioCalendarStyle: DisplayRepresentation] = [
        .aurora: "极光",
        .editorial: "简约",
        .soft: "柔和"
    ]

    var value: ShiftCalendarStyle {
        switch self {
        case .aurora: return .aurora
        case .editorial: return .editorial
        case .soft: return .soft
        }
    }
}

// MARK: - 小组件配置参数

struct StudioIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Studio 设置"

    @Parameter(title: "模板", default: .textCard)
    var template: StudioTemplate

    @Parameter(title: "文字来源", default: .intent)
    var textSource: StudioTextSource

    @Parameter(title: "标题", default: "今天也要")
    var title: String

    @Parameter(title: "正文", default: "好好生活")
    var detail: String

    @Parameter(title: "图标", default: .sparkles)
    var symbol: StudioSymbol

    @Parameter(title: "数值", default: 7)
    var count: Int

    @Parameter(title: "单位", default: "天")
    var unit: String

    @Parameter(title: "排班制", default: .twoOnTwoOff)
    var rotation: StudioRotation

    @Parameter(title: "日历风格", default: .aurora)
    var calendarStyle: StudioCalendarStyle

    @Parameter(title: "主题色", default: .blue)
    var theme: StudioTheme

    init() {}
}

// MARK: - 由配置推导渲染数据

enum StudioResolver {
    static func textConfig(for intent: StudioIntent) -> TextCardConfig {
        if intent.textSource == .app, SharedStore.isAppGroupAvailable {
            return SharedStore.load()
        }
        var config = TextCardConfig()
        config.title = intent.title
        config.message = intent.detail
        config.symbol = intent.symbol.name
        config.themeHex = intent.theme.hex
        config.style = .gradient
        return config
    }

    static func shiftConfig(for intent: StudioIntent) -> ShiftCalendarConfig {
        var config = SharedStore.loadShiftCalendar()
        config.style = intent.calendarStyle.value
        if intent.rotation != .appCustom {
            config.cycle = intent.rotation.cycle
            config.anchorDate = stableAnchor()
        }
        return config
    }

    /// 没有 App Group 时，用扩展自己的存储记住一个固定起点，保证「今天上什么班」不会天天漂移。
    private static func stableAnchor() -> Date {
        let store = UserDefaults.standard
        if let saved = store.object(forKey: "shiftAnchorEpoch") as? Date {
            return Calendar.current.startOfDay(for: saved)
        }
        let today = Calendar.current.startOfDay(for: Date())
        store.set(today, forKey: "shiftAnchorEpoch")
        return today
    }
}
