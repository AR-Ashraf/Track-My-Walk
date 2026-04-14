import CoreLocation
import SwiftUI
import UIKit

enum MapDisplayMode: Sendable {
    /// Live map that can follow the user/current location.
    case live
    /// Static map that fits the provided route and does not follow the user.
    case routePreview
}

private enum RouteMapVisual {
    static let polylineWidth: CGFloat = 5
    /// Matches polyline thickness — small endpoint dots, not map pins.
    static let endpointDotDiameter: CGFloat = polylineWidth
}

#if canImport(GoogleMaps)
import GoogleMaps

struct MapViewRepresentable: UIViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]
    var currentLocation: CLLocationCoordinate2D?
    var isTracking: Bool = false
    var displayMode: MapDisplayMode = .live

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition(latitude: 0, longitude: 0, zoom: 14)
        let map = GMSMapView(frame: .zero, camera: camera)
        map.isMyLocationEnabled = (displayMode == .live)
        map.settings.myLocationButton = false
        map.settings.compassButton = false
        map.settings.rotateGestures = (displayMode == .live)
        map.settings.tiltGestures = (displayMode == .live)
        return map
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        mapView.isMyLocationEnabled = (displayMode == .live)

        // Route polyline
        if coordinates.count >= 2 {
            let path = GMSMutablePath()
            for c in coordinates {
                path.addLatitude(c.latitude, longitude: c.longitude)
            }
            let polyline = GMSPolyline(path: path)
            polyline.strokeColor = .systemBlue
            polyline.strokeWidth = RouteMapVisual.polylineWidth
            polyline.map = mapView
        }

        addRouteEndpointMarkers(to: mapView)

        if displayMode == .routePreview {
            guard !coordinates.isEmpty else { return }

            let cameraKey = Self.cameraKey(for: coordinates)
            if context.coordinator.lastCameraKey == cameraKey { return }
            context.coordinator.lastCameraKey = cameraKey

            if coordinates.count == 1, let first = coordinates.first {
                mapView.animate(to: GMSCameraPosition(latitude: first.latitude, longitude: first.longitude, zoom: 17))
                return
            }

            var bounds = GMSCoordinateBounds()
            for c in coordinates {
                bounds = bounds.includingCoordinate(c)
            }
            mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: WalkingConstants.mapPadding))
            return
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

    private func addRouteEndpointMarkers(to mapView: GMSMapView) {
        guard let start = coordinates.first else { return }
        let startMarker = GMSMarker(position: start)
        startMarker.icon = Self.routeEndpointDot(diameter: RouteMapVisual.endpointDotDiameter, color: .systemGreen)
        startMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        startMarker.zIndex = 1
        startMarker.map = mapView

        if coordinates.count >= 2, let end = coordinates.last {
            let endMarker = GMSMarker(position: end)
            endMarker.icon = Self.routeEndpointDot(diameter: RouteMapVisual.endpointDotDiameter, color: .systemRed)
            endMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            endMarker.zIndex = 2
            endMarker.map = mapView
        }
    }

    private static func routeEndpointDot(diameter: CGFloat, color: UIColor) -> UIImage {
        let scale = UIScreen.main.scale
        let px = diameter * scale
        let size = CGSize(width: px, height: px)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        return image.withRenderingMode(.alwaysOriginal)
    }

    private static func cameraKey(for coords: [CLLocationCoordinate2D]) -> Int {
        guard let first = coords.first, let last = coords.last else { return 0 }
        func q(_ x: CLLocationDegrees) -> Int { Int((x * 10_000).rounded()) }
        var hasher = Hasher()
        hasher.combine(coords.count)
        hasher.combine(q(first.latitude))
        hasher.combine(q(first.longitude))
        hasher.combine(q(last.latitude))
        hasher.combine(q(last.longitude))
        return hasher.finalize()
    }

    final class Coordinator: NSObject {
        var lastCameraKey: Int?
    }
}

#else

import MapKit

private final class RouteEndpointAnnotation: NSObject, MKAnnotation {
    enum Kind {
        case start
        case end
    }

    let kind: Kind
    var coordinate: CLLocationCoordinate2D

    init(kind: Kind, coordinate: CLLocationCoordinate2D) {
        self.kind = kind
        self.coordinate = coordinate
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    var coordinates: [CLLocationCoordinate2D]
    var currentLocation: CLLocationCoordinate2D?
    var isTracking: Bool = false
    var displayMode: MapDisplayMode = .live

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = (displayMode == .live)
        map.userTrackingMode = .none
        map.isRotateEnabled = (displayMode == .live)
        map.isPitchEnabled = (displayMode == .live)
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        let endpointAnnotations = mapView.annotations.compactMap { $0 as? RouteEndpointAnnotation }
        mapView.removeAnnotations(endpointAnnotations)
        mapView.showsUserLocation = (displayMode == .live)
        if coordinates.count >= 2 {
            let poly = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(poly)
        }

        if let start = coordinates.first {
            mapView.addAnnotation(RouteEndpointAnnotation(kind: .start, coordinate: start))
        }
        if coordinates.count >= 2, let end = coordinates.last {
            mapView.addAnnotation(RouteEndpointAnnotation(kind: .end, coordinate: end))
        }

        if displayMode == .routePreview {
            // Fit the full route (or single point) and never follow the user's live location.
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
            return
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
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            guard let endpoint = annotation as? RouteEndpointAnnotation else { return nil }
            let id = endpoint.kind == .start ? "routeStart" : "routeEnd"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            let color: UIColor = endpoint.kind == .start ? .systemGreen : .systemRed
            view.image = Self.routeEndpointDot(diameter: RouteMapVisual.endpointDotDiameter, color: color)
            view.centerOffset = .zero
            view.canShowCallout = false
            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = RouteMapVisual.polylineWidth
            return renderer
        }

        private static func routeEndpointDot(diameter: CGFloat, color: UIColor) -> UIImage {
            let scale = UIScreen.main.scale
            let px = diameter * scale
            let size = CGSize(width: px, height: px)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                color.setFill()
                ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            }
            return image.withRenderingMode(.alwaysOriginal)
        }
    }
}

#endif
