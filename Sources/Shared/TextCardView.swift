import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r: Double
        let g: Double
        let b: Double
        let a: Double
        if cleaned.count == 8 {
            a = Double((value >> 24) & 0xFF) / 255
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
        } else {
            a = 1
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// App 和小组件共用同一个渲染视图，保证预览即所得。
struct TextCardView: View {
    var config: TextCardConfig

    private var tint: Color { Color(hex: config.themeHex) }

    var body: some View {
        ZStack {
            cardBackground
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: config.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                Spacer(minLength: 0)
                Text(config.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                Text(config.message)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.55)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch config.style {
        case .solid:
            tint
        case .gradient:
            LinearGradient(
                colors: [tint, tint.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .glass:
            ZStack {
                tint.opacity(0.45)
                Color.white.opacity(0.08)
            }
        }
    }
}
