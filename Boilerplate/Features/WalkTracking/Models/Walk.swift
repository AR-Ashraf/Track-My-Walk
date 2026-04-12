import Foundation
import SwiftData

struct Walk: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let distanceInKm: Double
    let caloriesBurned: Double
    let routePoints: [WalkPoint]
    let averagePace: Double
    let maxSpeed: Double
    var notes: String?
}

extension WalkModel {
    func toWalk() -> Walk {
        Walk(
            id: id,
            date: date,
            duration: duration,
            distanceInKm: distanceInKm,
            caloriesBurned: caloriesBurned,
            routePoints: decodedRoutePoints().map {
                WalkPoint(latitude: $0.latitude, longitude: $0.longitude, timestamp: $0.timestamp)
            },
            averagePace: averagePace,
            maxSpeed: maxSpeed,
            notes: notes
        )
    }
}
