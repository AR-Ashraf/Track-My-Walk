import CoreLocation
import MapKit
import SwiftData

enum WalkDetailError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "This walk could not be found."
        }
    }
}

@Observable
@MainActor
final class WalkDetailViewModel {
    var walk: Walk
    var mapRegion: MKCoordinateRegion
    let statistics: WalkStatistics

    private let modelContext: ModelContext

    var onDeleted: (() -> Void)?

    init(walk: Walk, modelContext: ModelContext) {
        self.walk = walk
        self.modelContext = modelContext
        statistics = WalkStatistics(walk: walk)
        mapRegion = Self.region(for: walk)
    }

    func shareWalk() -> String {
        let pace = walk.averagePaceMinPerKm.formatPaceMinutesPerKm()
        let speed = statistics.averageSpeedKmh.formatSpeed()
        var lines = """
        \(walk.name) — \(walk.date.formatted(date: .abbreviated, time: .shortened))
        Distance: \(walk.distanceInKm.formatDistance())
        Duration: \(walk.duration.formattedTime)
        Avg pace: \(pace)
        Avg speed: \(speed)
        Calories: \(walk.caloriesBurned.formatCalories())
        Steps: \(walk.displayStepCount)
        Avg cadence: \(String(format: "%.0f spm", walk.displayCadenceSpm))
        """
        if walk.weatherCaptured, let w = walk.weather {
            lines += "\nWeather: \(w.displayName)"
            lines += "\nTemp: \(Int(w.temperatureCelsius.rounded()))°C · Humidity: \(Int(w.humidityPercent.rounded()))% · Wind: \(String(format: "%.1f", w.windMph)) mph"
        }
        return lines
    }

    func updateMetadata(name: String, date: Date) throws {
        let walkId = walk.id
        let descriptor = FetchDescriptor<WalkModel>(
            predicate: #Predicate { $0.id == walkId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw WalkDetailError.notFound
        }
        model.name = name
        model.date = date
        modelContext.saveIfNeeded()
        walk = model.toWalk()
    }

    func deleteWalk() throws {
        let walkId = walk.id
        let descriptor = FetchDescriptor<WalkModel>(
            predicate: #Predicate { $0.id == walkId }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw WalkDetailError.notFound
        }
        modelContext.delete(model)
        modelContext.saveIfNeeded()
        onDeleted?()
    }

    private static func region(for walk: Walk) -> MKCoordinateRegion {
        let coords = walk.routePoints.map(\.coordinate)
        guard let first = coords.first else {
            return CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090).region(withMeters: 2_000)
        }
        if coords.count == 1 {
            return first.region(withMeters: 800)
        }
        let minLat = coords.map(\.latitude).min() ?? first.latitude
        let maxLat = coords.map(\.latitude).max() ?? first.latitude
        let minLon = coords.map(\.longitude).min() ?? first.longitude
        let maxLon = coords.map(\.longitude).max() ?? first.longitude
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.008),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.008)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
