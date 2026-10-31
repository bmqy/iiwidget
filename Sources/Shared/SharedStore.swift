import Foundation
import WidgetKit

// MARK: - 小组件模板数据模型

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

// MARK: - App Group 共享存储

enum SharedStore {
    /// 需要和你的开发者账号里注册的 App Group 完全一致，否则两边各存各的（会退回默认内容）。
    static let appGroupID = "group.com.widgetstudio.shared"
    private static let key = "textcard.config.v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> TextCardConfig {
        guard let data = defaults.data(forKey: key),
              let config = try? JSONDecoder().decode(TextCardConfig.self, from: data)
        else { return TextCardConfig() }
        return config
    }

    static func save(_ config: TextCardConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
