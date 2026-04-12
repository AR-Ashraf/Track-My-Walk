import Foundation
import SwiftData

@Observable
@MainActor
final class TrackingViewModel {
    enum Phase: Equatable {
        case idle
        case tracking
        case paused
    }

    private(set) let locationManager: LocationManager
    private let modelContext: ModelContext

    var phase: Phase = .idle
    var elapsedTime: TimeInterval = 0

    /// Fires after a walk is persisted (e.g. refresh history).
    var onWalkSaved: (() -> Void)?

    private var tickTimer: Timer?

    init(locationManager: LocationManager, modelContext: ModelContext) {
        self.locationManager = locationManager
        self.modelContext = modelContext
    }

    var isTracking: Bool { phase == .tracking }
    var isPaused: Bool { phase == .paused }

    func startWalk() {
        guard phase == .idle else { return }
        phase = .tracking
        elapsedTime = 0
        locationManager.startTracking()
        startTimer()
        HapticService.shared.mediumImpact()
    }

    func pauseWalk() {
        guard phase == .tracking else { return }
        phase = .paused
        locationManager.pauseLocationUpdates()
        HapticService.shared.lightImpact()
    }

    func resumeWalk() {
        guard phase == .paused else { return }
        phase = .tracking
        locationManager.resumeLocationUpdates()
        HapticService.shared.mediumImpact()
    }

    func cancelWalk() {
        tickTimer?.invalidate()
        tickTimer = nil
        phase = .idle
        elapsedTime = 0
        locationManager.reset()
    }

    func stopWalk(notes: String? = nil) -> Walk? {
        guard phase == .tracking || phase == .paused else { return nil }

        tickTimer?.invalidate()
        tickTimer = nil

        let duration = elapsedTime
        let distanceKm = locationManager.distanceTraveled.metersToKm
        let route: [WalkPointData] = locationManager.locationPoints.map {
            WalkPointData(
                latitude: $0.coordinate.latitude,
                longitude: $0.coordinate.longitude,
                timestamp: $0.timestamp
            )
        }
        let avgPace = duration > 0 ? distanceKm / (duration / 3600) : 0
        let calories = distanceKm * WalkingConstants.defaultCalorieBurnRate * 100

        let model = WalkModel(
            duration: duration,
            distanceInKm: distanceKm,
            caloriesBurned: calories,
            routePoints: route,
            averagePace: avgPace,
            maxSpeed: locationManager.maxSpeedMps,
            notes: notes
        )

        modelContext.insert(model)
        modelContext.saveIfNeeded()

        let uiWalk = model.toWalk()

        phase = .idle
        elapsedTime = 0
        locationManager.reset()

        onWalkSaved?()
        return uiWalk
    }

    private func startTimer() {
        tickTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.phase == .tracking else { return }
                self.elapsedTime += 1
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }
}
