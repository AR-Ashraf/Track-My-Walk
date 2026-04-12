import CoreLocation
import MapKit

extension CLLocationCoordinate2D {
    /// Haversine distance between two coordinates (meters).
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let earthRadius = 6_371_000.0
        let lat1 = latitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let dLat = (other.latitude - latitude) * .pi / 180
        let dLon = (other.longitude - longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
            + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }

    func midpoint(to other: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (latitude + other.latitude) / 2,
            longitude: (longitude + other.longitude) / 2
        )
    }

    func region(withMeters meters: CLLocationDistance) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: self,
            latitudinalMeters: meters,
            longitudinalMeters: meters
        )
    }
}
