import SwiftUI

struct WalkStatsCard: View {
    let distanceKm: Double
    let elapsed: TimeInterval
    let paceKmh: Double
    let calories: Double
    var showCalories: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(distanceKm.formatDistance())
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(elapsed.formattedHMS)
                .font(.title2.monospacedDigit())
                .foregroundStyle(.secondary)

            Text(paceKmh.formatSpeed())
                .font(.title3.weight(.medium))
                .foregroundStyle(.blue)

            if showCalories {
                Text(calories.formatCalories())
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
