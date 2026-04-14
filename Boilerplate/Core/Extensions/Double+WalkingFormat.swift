import Foundation

extension Double {
    var metersToKm: Double { self / 1000 }

    func formatDistance(unit: String = "km") -> String {
        String(format: "%.2f %@", self, unit)
    }

    /// Speed formatting (e.g. km/h).
    func formatSpeed(unit: String = "km/h") -> String {
        String(format: "%.2f %@", self, unit)
    }

    /// Pace formatting where `self` is minutes per kilometer.
    func formatPaceMinutesPerKm() -> String {
        guard self.isFinite, self > 0 else { return "—" }
        let totalSeconds = Int((self * 60).rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d min/km", minutes, seconds)
    }

    func formatCalories() -> String {
        String(format: "%.0f cal", self)
    }
}
