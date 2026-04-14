import Foundation
import SwiftData

@Model
final class WalkModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var name: String
    var duration: TimeInterval
    var distanceInKm: Double
    var caloriesBurned: Double
    var routePointsData: Data
    var averagePace: Double
    var maxSpeed: Double
    var notes: String?

    // Optional so lightweight migration from older stores does not require back-filled values per row.
    var stepCount: Int?
    var averageCadenceSpm: Double?

    /// When true, `weather*` fields were captured at save time; otherwise show a legacy / unavailable state in UI.
    var weatherCaptured: Bool?
    var weatherConditionKind: String?
    var weatherDisplayName: String?
    var temperatureCelsius: Double?
    var humidityPercent: Double?
    var windMph: Double?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        name: String = "Walk",
        duration: TimeInterval,
        distanceInKm: Double,
        caloriesBurned: Double,
        routePoints: [WalkPointData],
        averagePace: Double,
        maxSpeed: Double,
        notes: String? = nil,
        stepCount: Int? = nil,
        averageCadenceSpm: Double? = nil,
        weatherCaptured: Bool? = nil,
        weatherConditionKind: String? = nil,
        weatherDisplayName: String? = nil,
        temperatureCelsius: Double? = nil,
        humidityPercent: Double? = nil,
        windMph: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.duration = duration
        self.distanceInKm = distanceInKm
        self.caloriesBurned = caloriesBurned
        self.routePointsData = (try? JSONEncoder().encode(routePoints)) ?? Data()
        self.averagePace = averagePace
        self.maxSpeed = maxSpeed
        self.notes = notes
        self.stepCount = stepCount
        self.averageCadenceSpm = averageCadenceSpm
        self.weatherCaptured = weatherCaptured
        self.weatherConditionKind = weatherConditionKind
        self.weatherDisplayName = weatherDisplayName
        self.temperatureCelsius = temperatureCelsius
        self.humidityPercent = humidityPercent
        self.windMph = windMph
    }

    func decodedRoutePoints() -> [WalkPointData] {
        (try? JSONDecoder().decode([WalkPointData].self, from: routePointsData)) ?? []
    }

    func setRoutePoints(_ points: [WalkPointData]) {
        routePointsData = (try? JSONEncoder().encode(points)) ?? Data()
    }
}

extension WalkModel: Equatable {
    static func == (lhs: WalkModel, rhs: WalkModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension WalkModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
