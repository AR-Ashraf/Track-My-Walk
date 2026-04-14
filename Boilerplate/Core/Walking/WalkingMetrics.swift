import Foundation

enum WalkingMetrics {
    /// Typical adult walking cadence implies roughly 1,200–1,350 steps/km; use a mid estimate when hardware step count is unavailable.
    static func estimatedStepCount(distanceKm: Double) -> Int {
        max(0, Int((distanceKm * 1275).rounded()))
    }

    /// Steps per minute (spm).
    static func averageCadenceSpm(stepCount: Int, duration: TimeInterval) -> Double {
        guard duration > 0, stepCount > 0 else { return 0 }
        let minutes = duration / 60
        return Double(stepCount) / minutes
    }
}
