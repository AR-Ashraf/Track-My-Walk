import CoreLocation
import SwiftUI

struct WalkListItem: View {
    let walk: WalkModel

    private var coordinates: [CLLocationCoordinate2D] {
        walk.decodedRoutePoints().map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(walk.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(walk.date, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(walk.distanceInKm.formatDistance())
                    .font(.headline)
                Text(walk.duration.formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(walk.averagePace.formatSpeed())
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            MapViewRepresentable(
                coordinates: coordinates,
                currentLocation: nil,
                displayMode: .routePreview
            )
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .allowsHitTesting(false)
        }
        .padding(.vertical, 4)
    }
}
