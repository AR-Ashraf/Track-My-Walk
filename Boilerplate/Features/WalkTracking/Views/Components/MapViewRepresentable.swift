import CoreLocation
import SwiftUI

#if canImport(GoogleMaps)
import GoogleMaps

struct MapViewRepresentable: UIViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]
    var currentLocation: CLLocationCoordinate2D?
    var isTracking: Bool = false

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 14)
        let map = GMSMapView(frame: .zero, camera: camera)
        map.isMyLocationEnabled = true
        map.settings.myLocationButton = true
        map.settings.myLocationButton = false
        map.settings.compassButton = false
        return map
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()

        // Route polyline
        if coordinates.count >= 2 {
            let path = GMSMutablePath()
            for c in coordinates {
                path.addLatitude(c.latitude, longitude: c.longitude)
            }
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = .systemBlue
            polyline.strokeWidth = 5
            polyline.map = mapView
        }

        // Default camera behavior: zoom into current location immediately (street-level),
        // then tight-follow while tracking.
        let myLocation = mapView.myLocation?.coordinate
        if let focus = (isTracking ? coordinates.last : nil) ?? currentLocation ?? myLocation ?? coordinates.last {
            let zoom: Float = isTracking ? 18 : 17
            mapView.animate(to: GMSCameraPosition(latitude: focus.latitude, longitude: focus.longitude, zoom: zoom))
            return
        }
    }
}

#else

import MapKit

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

        // Default camera behavior: zoom into current location, and tight-follow while tracking.
        let defaultZoomMeters: CLLocationDistance = isTracking ? 200 : 600
        if let focus = (isTracking ? coordinates.last : nil) ?? currentLocation ?? coordinates.last {
            let region = MKCoordinateRegion(center: focus, latitudinalMeters: defaultZoomMeters, longitudinalMeters: defaultZoomMeters)
            mapView.setRegion(region, animated: true)
            return
        }

        // Fit the full route when we have points but no current location.
        let padding = WalkingConstants.mapPadding
        let inset = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)

        guard let first = coordinates.first else { return }
        if coordinates.count == 1 {
            let region = MKCoordinateRegion(center: first, latitudinalMeters: 600, longitudinalMeters: 600)
            mapView.setRegion(region, animated: true)
            return
        }

        var rect = MKMapRect.null
        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            let tiny = MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1))
            rect = rect.union(tiny)
        }

        guard !rect.isNull else { return }
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

#endif
