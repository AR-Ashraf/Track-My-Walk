import Foundation

struct WalkStatistics: Sendable {
    let totalDistance: Double
    let totalDuration: TimeInterval
    let caloriesBurned: Double
    let averageSpeedKmh: Double
    let averagePaceMinPerKm: Double

    init(walk: Walk) {
        totalDistance = walk.distanceInKm
        totalDuration = walk.duration
        caloriesBurned = walk.caloriesBurned
        averageSpeedKmh = walk.duration > 0 ? walk.distanceInKm / (walk.duration / 3600) : 0
        averagePaceMinPerKm = walk.averagePaceMinPerKm
    }
}
