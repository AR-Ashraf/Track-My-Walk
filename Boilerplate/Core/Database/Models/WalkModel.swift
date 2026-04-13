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
        notes: String? = nil
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
