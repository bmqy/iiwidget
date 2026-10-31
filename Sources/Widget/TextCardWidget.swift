import WidgetKit
import SwiftUI

struct TextCardEntry: TimelineEntry {
    let date: Date
    let config: TextCardConfig
}

struct TextCardProvider: TimelineProvider {
    func placeholder(in context: Context) -> TextCardEntry {
        TextCardEntry(date: Date(), config: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TextCardEntry) -> Void) {
        completion(TextCardEntry(date: Date(), config: SharedStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TextCardEntry>) -> Void) {
        let entry = TextCardEntry(date: Date(), config: SharedStore.load())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct TextCardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TextCardWidget", provider: TextCardProvider()) { entry in
            TextCardView(config: entry.config)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("文字卡片")
        .description("在 App 里编辑标题、正文、图标与配色。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
