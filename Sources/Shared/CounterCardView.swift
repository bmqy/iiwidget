import SwiftUI
import WidgetKit

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

