import CoreLocation
import Foundation

struct WalkPoint: Hashable, Sendable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date

    init(latitude: Double, longitude: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }

    init(from coordinate: CLLocationCoordinate2D, timestamp: Date = .init()) {
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        self.timestamp = timestamp
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
