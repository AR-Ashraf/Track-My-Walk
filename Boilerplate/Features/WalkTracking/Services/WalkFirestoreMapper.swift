import FirebaseFirestore
import Foundation

enum WalkFirestoreMapper {
    struct CloudWalk: Sendable {
        var id: String
        var date: Date
        var name: String
        var duration: TimeInterval
        var distanceInKm: Double
        var caloriesBurned: Double
        var averagePace: Double
        var maxSpeed: Double
        var notes: String?

        var stepCount: Int?
        var averageCadenceSpm: Double?

        var weatherCaptured: Bool?
        var weatherConditionKind: String?
        var weatherDisplayName: String?
        var temperatureCelsius: Double?
        var humidityPercent: Double?
        var windMph: Double?

        var routePoints: [WalkPointData]
        var updatedAt: Date?
    }

    static func toDocument(_ model: WalkModel) -> [String: Any] {
        let points = model.decodedRoutePoints().map { p in
            [
                "lat": p.latitude,
                "lon": p.longitude,
                "timestamp": Timestamp(date: p.timestamp)
            ]
        }

        var doc: [String: Any] = [
            "id": model.id.uuidString,
            "date": Timestamp(date: model.date),
            "name": model.name,
            "duration": model.duration,
            "distanceInKm": model.distanceInKm,
            "caloriesBurned": model.caloriesBurned,
            "averagePace": model.averagePace,
            "maxSpeed": model.maxSpeed,
            "routePoints": points,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let notes = model.notes { doc["notes"] = notes }
        if let stepCount = model.stepCount { doc["stepCount"] = stepCount }
        if let cadence = model.averageCadenceSpm { doc["averageCadenceSpm"] = cadence }

        if let captured = model.weatherCaptured { doc["weatherCaptured"] = captured }
        if let v = model.weatherConditionKind { doc["weatherConditionKind"] = v }
        if let v = model.weatherDisplayName { doc["weatherDisplayName"] = v }
        if let v = model.temperatureCelsius { doc["temperatureCelsius"] = v }
        if let v = model.humidityPercent { doc["humidityPercent"] = v }
        if let v = model.windMph { doc["windMph"] = v }

        return doc
    }

    static func fromSnapshot(_ snapshot: DocumentSnapshot) throws -> CloudWalk {
        let data = snapshot.data() ?? [:]

        func date(_ key: String) -> Date {
            (data[key] as? Timestamp)?.dateValue() ?? Date()
        }
        func string(_ key: String) -> String? { data[key] as? String }
        func double(_ key: String) -> Double? {
            if let d = data[key] as? Double { return d }
            if let n = data[key] as? NSNumber { return n.doubleValue }
            return nil
        }
        func int(_ key: String) -> Int? {
            if let i = data[key] as? Int { return i }
            if let n = data[key] as? NSNumber { return n.intValue }
            return nil
        }
        func bool(_ key: String) -> Bool? { data[key] as? Bool }

        let id = string("id") ?? snapshot.documentID
        let routePoints: [WalkPointData] = (data["routePoints"] as? [[String: Any]] ?? []).compactMap { dict in
            guard
                let lat = dict["lat"] as? Double,
                let lon = dict["lon"] as? Double
            else { return nil }
            let ts = (dict["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            return WalkPointData(latitude: lat, longitude: lon, timestamp: ts)
        }

        return CloudWalk(
            id: id,
            date: date("date"),
            name: string("name") ?? "Walk",
            duration: double("duration") ?? 0,
            distanceInKm: double("distanceInKm") ?? 0,
            caloriesBurned: double("caloriesBurned") ?? 0,
            averagePace: double("averagePace") ?? 0,
            maxSpeed: double("maxSpeed") ?? 0,
            notes: string("notes"),
            stepCount: int("stepCount"),
            averageCadenceSpm: double("averageCadenceSpm"),
            weatherCaptured: bool("weatherCaptured"),
            weatherConditionKind: string("weatherConditionKind"),
            weatherDisplayName: string("weatherDisplayName"),
            temperatureCelsius: double("temperatureCelsius"),
            humidityPercent: double("humidityPercent"),
            windMph: double("windMph"),
            routePoints: routePoints,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
        )
    }
}

