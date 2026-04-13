import CoreLocation
import Foundation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    @ObservationIgnored private let manager = CLLocationManager()

    private(set) var currentLocation: CLLocation?
    private(set) var locationPoints: [CLLocation] = []
    private(set) var isTracking = false
    private(set) var isPaused = false
    private(set) var distanceTraveled: CLLocationDistance = 0
    private(set) var startTime: Date?
    private(set) var maxSpeedMps: Double = 0

    private(set) var authorizationStatus: CLAuthorizationStatus

    override init() {
        authorizationStatus = .notDetermined
        super.init()
        authorizationStatus = manager.authorizationStatus
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = WalkingConstants.locationUpdateDistance
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestLocationPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
            requestOneShotLocation()
        default:
            requestOneShotLocation()
            break
        }
    }

    func requestOneShotLocation() {
        guard manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways else {
            return
        }
        // If CoreLocation already has a cached fix, surface it immediately for UI centering.
        if let cached = manager.location {
            currentLocation = cached
        }
        // Ask CoreLocation for a single fix so the UI can center immediately.
        manager.requestLocation()
    }

    func startTracking() {
        guard !isTracking else { return }
        resetSession()
        isTracking = true
        isPaused = false
        startTime = Date()
        manager.startUpdatingLocation()
        // Enable background updates only when the app declares it supports background location.
        if shouldAllowBackgroundLocationUpdates, manager.authorizationStatus == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
        }
    }

    func pauseLocationUpdates() {
        guard isTracking, !isPaused else { return }
        isPaused = true
        manager.stopUpdatingLocation()
    }

    func resumeLocationUpdates() {
        guard isTracking, isPaused else { return }
        isPaused = false
        manager.startUpdatingLocation()
        if shouldAllowBackgroundLocationUpdates, manager.authorizationStatus == .authorizedAlways {
            manager.allowsBackgroundLocationUpdates = true
        }
    }

    func stopTracking() {
        guard isTracking else { return }
        isTracking = false
        isPaused = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    func reset() {
        stopTracking()
        resetSession()
    }

    private func resetSession() {
        locationPoints.removeAll()
        currentLocation = nil
        distanceTraveled = 0
        startTime = nil
        maxSpeedMps = 0
        isPaused = false
    }

    func appendSimulatedLocation(_ location: CLLocation) {
        guard isTracking, !isPaused else { return }
        processLocation(location)
    }

    private func processLocation(_ location: CLLocation) {
        currentLocation = location

        if let last = locationPoints.last {
            let segment = location.distance(from: last)
            if segment > 0 {
                distanceTraveled += segment
            }
        }
        locationPoints.append(location)

        let speed = location.speed
        if speed >= 0, speed > maxSpeedMps {
            maxSpeedMps = speed
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = self.manager.authorizationStatus
            if self.isTracking, self.shouldAllowBackgroundLocationUpdates, self.manager.authorizationStatus == .authorizedAlways {
                self.manager.allowsBackgroundLocationUpdates = true
            }
            if !self.isTracking {
                self.requestOneShotLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            guard self.isTracking else { return }
            self.processLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.shared.app("Location error: \(error.localizedDescription)", level: .error)
    }

    private var shouldAllowBackgroundLocationUpdates: Bool {
        // CoreLocation will assert/crash if this is enabled without background mode support.
        guard let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else {
            return false
        }
        return modes.contains("location")
    }
}
