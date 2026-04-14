import CoreLocation
import Foundation

/// Captures a weather snapshot for the end of a walk.
///
/// - Preferred: **Open-Meteo** (free, no API key) using the walk's coordinate and timestamp.
/// - Fallback: a deterministic heuristic if the network is unavailable.
enum WalkWeatherService {
    static func fetchSnapshot(at coordinate: CLLocationCoordinate2D, date: Date) async -> WalkWeatherSnapshot {
        do {
            if let snapshot = try await fetchOpenMeteoSnapshot(at: coordinate, date: date) {
                return snapshot
            }
        } catch {
            // fall through to heuristic
        }
        return heuristicSnapshot(coordinate: coordinate, date: date)
    }

    // MARK: - Open-Meteo (no key)

    private struct OpenMeteoResponse: Decodable {
        struct Hourly: Decodable {
            let time: [String]
            let temperature_2m: [Double]?
            let relative_humidity_2m: [Double]?
            let wind_speed_10m: [Double]?
            let weather_code: [Int]?
        }

        let hourly: Hourly
    }

    private static func fetchOpenMeteoSnapshot(at coordinate: CLLocationCoordinate2D, date: Date) async throws -> WalkWeatherSnapshot? {
        // Query a small window around the walk time (previous + next day) and pick the closest hour.
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
        components?.queryItems = [
            .init(name: "latitude", value: String(coordinate.latitude)),
            .init(name: "longitude", value: String(coordinate.longitude)),
            .init(name: "hourly", value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
            .init(name: "temperature_unit", value: "celsius"),
            .init(name: "wind_speed_unit", value: "mph"),
            .init(name: "timezone", value: "auto"),
            .init(name: "past_days", value: "1"),
            .init(name: "forecast_days", value: "1")
        ]
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else { return nil }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let times = decoded.hourly.time
        guard !times.isEmpty else { return nil }

        // Parse ISO8601-like time strings Open-Meteo returns (e.g. "2026-04-14T13:00").
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]

        var bestIndex: Int?
        var bestDelta: TimeInterval = .greatestFiniteMagnitude
        for (idx, t) in times.enumerated() {
            guard let parsed = formatter.date(from: t) else { continue }
            let delta = abs(parsed.timeIntervalSince(date))
            if delta < bestDelta {
                bestDelta = delta
                bestIndex = idx
            }
        }
        guard let i = bestIndex else { return nil }

        let temp = decoded.hourly.temperature_2m?[safe: i]
        let humidity = decoded.hourly.relative_humidity_2m?[safe: i]
        let wind = decoded.hourly.wind_speed_10m?[safe: i]
        let code = decoded.hourly.weather_code?[safe: i]

        guard let temp, let humidity, let wind, let code else { return nil }
        let (kind, name) = classify(openMeteoWeatherCode: code)

        return WalkWeatherSnapshot(
            conditionKind: kind,
            displayName: name,
            temperatureCelsius: temp,
            humidityPercent: humidity,
            windMph: wind
        )
    }

    private static func classify(openMeteoWeatherCode code: Int) -> (kind: String, name: String) {
        // https://open-meteo.com/en/docs#weathercode
        switch code {
        case 0:
            return ("sunny", "Clear")
        case 1:
            return ("sunny", "Mainly clear")
        case 2:
            return ("sunny", "Partly cloudy")
        case 3:
            return ("sunny", "Overcast")
        case 45, 48:
            return ("sunny", "Fog")
        case 51, 53, 55:
            return ("rainy", "Drizzle")
        case 56, 57:
            return ("rainy", "Freezing drizzle")
        case 61, 63, 65:
            return ("rainy", "Rain")
        case 66, 67:
            return ("rainy", "Freezing rain")
        case 71, 73, 75:
            return ("winter", "Snow")
        case 77:
            return ("winter", "Snow grains")
        case 80, 81, 82:
            return ("rainy", "Rain showers")
        case 85, 86:
            return ("winter", "Snow showers")
        case 95:
            return ("rainy", "Thunderstorm")
        case 96, 99:
            return ("rainy", "Thunderstorm")
        default:
            return ("sunny", "Weather")
        }
    }

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

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
