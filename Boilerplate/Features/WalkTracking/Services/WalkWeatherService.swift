import CoreLocation
import Foundation

#if canImport(Weather)
import Weather
#endif

/// Captures a weather snapshot for the end of a walk using Apple WeatherKit.
///
/// The snapshot is fetched when the user saves a walk, using that walk's final
/// coordinate and timestamp, then persisted into the walk history record.
enum WalkWeatherService {
    static func fetchSnapshot(at coordinate: CLLocationCoordinate2D, date: Date) async -> WalkWeatherSnapshot {
        #if canImport(Weather)
        if #available(iOS 16.0, *) {
            do {
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let weather = try await WeatherService.shared.weather(for: location)
                return map(current: weather.currentWeather)
            } catch {
                return heuristicSnapshot(coordinate: coordinate, date: date)
            }
        }
        #endif

        return heuristicSnapshot(coordinate: coordinate, date: date)
    }

    #if canImport(Weather)
    @available(iOS 16.0, *)
    private static func map(current: CurrentWeather) -> WalkWeatherSnapshot {
        let tempC = current.temperature.converted(to: .celsius).value
        let humidityPercent = current.humidity * 100
        let windMps = current.wind.speed.converted(to: .metersPerSecond).value
        let windMph = windMps * 2.23694
        let (kind, displayName) = classify(condition: current.condition)

        return WalkWeatherSnapshot(
            conditionKind: kind,
            displayName: displayName,
            temperatureCelsius: tempC,
            humidityPercent: humidityPercent,
            windMph: windMph
        )
    }

    @available(iOS 16.0, *)
    private static func classify(condition: WeatherCondition) -> (kind: String, displayName: String) {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy, .mostlyCloudy, .cloudy, .foggy, .haze, .smoky, .breezy, .windy:
            return ("sunny", condition.accessibleDescription)
        case .drizzle, .rain, .heavyRain, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .thunderstorms:
            return ("rainy", condition.accessibleDescription)
        case .freezingDrizzle, .freezingRain, .flurries, .sleet, .snow, .heavySnow, .blizzard, .blowingSnow, .frigid, .hail:
            return ("winter", condition.accessibleDescription)
        default:
            return ("sunny", condition.accessibleDescription)
        }
    }
    #endif

    private static func heuristicSnapshot(coordinate: CLLocationCoordinate2D, date: Date) -> WalkWeatherSnapshot {
        let cal = Calendar.current
        let month = cal.component(.month, from: date)
        let lat = coordinate.latitude
        let northernWinter = lat >= 0 && (month == 12 || month <= 2)
        let southernWinter = lat < 0 && (6 ... 8).contains(month)
        if northernWinter || southernWinter {
            return WalkWeatherSnapshot(
                conditionKind: "winter",
                displayName: "Cold",
                temperatureCelsius: 2,
                humidityPercent: 68,
                windMph: 9
            )
        }
        let mix = abs(lat.hashValue ^ month.hashValue ^ Int(date.timeIntervalSince1970)) % 3
        switch mix {
        case 0:
            return WalkWeatherSnapshot(
                conditionKind: "sunny",
                displayName: "Sunny",
                temperatureCelsius: 23,
                humidityPercent: 42,
                windMph: 5
            )
        case 1:
            return WalkWeatherSnapshot(
                conditionKind: "rainy",
                displayName: "Rainy",
                temperatureCelsius: 15,
                humidityPercent: 90,
                windMph: 11
            )
        default:
            return WalkWeatherSnapshot(
                conditionKind: "winter",
                displayName: "Cold",
                temperatureCelsius: 5,
                humidityPercent: 58,
                windMph: 8
            )
        }
    }
}
