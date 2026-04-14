import SwiftUI

enum WalkDetailWeatherArtwork {
    /// Large visual for the walk condition (sunny / rainy / winter).
    @ViewBuilder
    static func hero(for conditionKind: String) -> some View {
        let (symbol, colors): (String, [Color]) = {
            switch conditionKind.lowercased() {
            case "rainy":
                return ("cloud.rain.fill", [.blue.opacity(0.85), .cyan.opacity(0.6)])
            case "winter":
                return ("snowflake", [.cyan.opacity(0.6), .blue.opacity(0.75)])
            default:
                return ("sun.max.fill", [.orange.opacity(0.9), .yellow.opacity(0.75)])
            }
        }()

        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            Image(systemName: symbol)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityHidden(true)
    }
}
