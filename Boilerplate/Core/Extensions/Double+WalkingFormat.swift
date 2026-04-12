import Foundation

extension Double {
    var metersToKm: Double { self / 1000 }

    func formatDistance(unit: String = "km") -> String {
        String(format: "%.2f %@", self, unit)
    }

    func formatPace(unit: String = "km/h") -> String {
        String(format: "%.2f %@", self, unit)
    }

    func formatCalories() -> String {
        String(format: "%.0f cal", self)
    }
}
