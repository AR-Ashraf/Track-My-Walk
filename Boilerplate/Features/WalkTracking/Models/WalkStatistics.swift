import Foundation

struct WalkStatistics: Sendable {
    let totalDistance: Double
    let totalDuration: TimeInterval
    let averagePace: Double
    let caloriesBurned: Double
    let averageSpeed: Double

    init(walk: Walk) {
        totalDistance = walk.distanceInKm
        totalDuration = walk.duration
        averagePace = walk.averagePace
        caloriesBurned = walk.caloriesBurned
        averageSpeed = walk.duration > 0 ? walk.distanceInKm / (walk.duration / 3600) : 0
    }
}
