import Foundation
import SwiftData

struct Walk: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let name: String
    let duration: TimeInterval
    let distanceInKm: Double
    let caloriesBurned: Double
    let routePoints: [WalkPoint]
    /// Stored as km/h for historical compatibility with earlier versions.
    let averagePace: Double
    let maxSpeed: Double
    var notes: String?

    let stepCount: Int
    let averageCadenceSpm: Double

    let weatherCaptured: Bool
    /// Present when `weatherCaptured` is true (saved walks with a snapshot).
    let weather: WalkWeatherSnapshot?

    /// Steps shown in UI: stored count, or an estimate from distance for older records.
    var displayStepCount: Int {
        if stepCount > 0 { return stepCount }
        return WalkingMetrics.estimatedStepCount(distanceKm: distanceInKm)
    }

    /// Cadence (spm) shown in UI: stored value, or derived from displayed steps.
    var displayCadenceSpm: Double {
        if averageCadenceSpm > 0 { return averageCadenceSpm }
        return WalkingMetrics.averageCadenceSpm(stepCount: displayStepCount, duration: duration)
    }

    var isStepEstimate: Bool { stepCount == 0 && distanceInKm > 0 }

    /// Preferred pace for UI: minutes per km.
    var averagePaceMinPerKm: Double {
        guard distanceInKm > 0, duration > 0 else { return 0 }
        return (duration / 60) / distanceInKm
    }
}

extension WalkModel {
    func toWalk() -> Walk {
        let captured = weatherCaptured ?? false
        let snapshot: WalkWeatherSnapshot? = captured
            ? WalkWeatherSnapshot(
                conditionKind: weatherConditionKind ?? "sunny",
                displayName: weatherDisplayName ?? "",
                temperatureCelsius: temperatureCelsius ?? 0,
                humidityPercent: humidityPercent ?? 0,
                windMph: windMph ?? 0
            )
            : nil

        return Walk(
            id: id,
            date: date,
            name: name,
            duration: duration,
            distanceInKm: distanceInKm,
            caloriesBurned: caloriesBurned,
            routePoints: decodedRoutePoints().map {
                WalkPoint(latitude: $0.latitude, longitude: $0.longitude, timestamp: $0.timestamp)
            },
            averagePace: averagePace,
            maxSpeed: maxSpeed,
            notes: notes,
            stepCount: stepCount ?? 0,
            averageCadenceSpm: averageCadenceSpm ?? 0,
            weatherCaptured: captured,
            weather: snapshot
        )
    }
}
