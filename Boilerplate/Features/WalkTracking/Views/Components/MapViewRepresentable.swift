import MapKit
import SwiftUI

struct MapViewRepresentable: UIViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]
    var currentLocation: CLLocationCoordinate2D?
    var isTracking: Bool = false

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .none
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        if coordinates.count >= 2 {
            let poly = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(poly)
        }

        // Auto-follow: center tightly on latest coordinate while tracking
        if isTracking, let last = coordinates.last {
            let region = MKCoordinateRegion(center: last, latitudinalMeters: 200, longitudinalMeters: 200)
            mapView.setRegion(region, animated: true)
            return
        }

        let padding = WalkingConstants.mapPadding
        let inset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)

        var all = coordinates
        if let currentLocation {
            all.append(currentLocation)
        }

        guard let first = all.first else { return }

        if all.count == 1 {
            let region = MKCoordinateRegion(
                center: first,
                latitudinalMeters: 600,
                longitudinalMeters: 600
            )
            mapView.setRegion(region, animated: true)
            return
        }

        var rect = MKMapRect.null
        for coordinate in all {
            let point = MKMapPoint(coordinate)
            let tiny = MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1))
            rect = rect.union(tiny)
        }

        if rect.isNull {
            mapView.setRegion(MKCoordinateRegion(center: first, latitudinalMeters: 600, longitudinalMeters: 600), animated: true)
            return
        }

        mapView.setVisibleMapRect(rect, edgePadding: inset, animated: true)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
    }
}
