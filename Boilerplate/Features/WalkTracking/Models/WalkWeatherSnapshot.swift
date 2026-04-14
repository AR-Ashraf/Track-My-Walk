import Foundation

struct WalkWeatherSnapshot: Hashable, Sendable {
    var conditionKind: String
    var displayName: String
    var temperatureCelsius: Double
    var humidityPercent: Double
    var windMph: Double
}
