import CoreLocation
import SwiftUI

struct TrackingView: View {
    @Bindable var viewModel: TrackingViewModel
    @Bindable var locationManager: LocationManager

    @State private var showStopConfirmation = false
    @State private var notesDraft = ""
    @State private var showSavedToast = false
    @State private var isSaving = false
    @State private var permissionMessage: String?

    #if DEBUG
    @State private var simulationTask: Task<Void, Never>?
    #endif

    var body: some View {
        ZStack(alignment: .top) {
            MapViewRepresentable(
                coordinates: locationManager.locationPoints.map(\.coordinate),
                currentLocation: locationManager.currentLocation?.coordinate
            )
            .ignoresSafeArea()

            statusPill

            VStack {
                Spacer()
                WalkStatsCard(
                    distanceKm: liveDistanceKm,
                    elapsed: viewModel.elapsedTime,
                    paceKmh: livePaceKmh,
                    calories: liveCalories
                )
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.25), value: liveDistanceKm)

                controlBar
                    .padding()
            }

            if showSavedToast {
                Text("Saved!")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.green.gradient, in: Capsule())
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, 100)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showSavedToast)
        .onAppear {
            syncPermissionMessage()
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            syncPermissionMessage()
        }
        .alert("Stop walk?", isPresented: $showStopConfirmation) {
            TextField("Notes (optional)", text: $notesDraft)
            Button("Save walk", role: .none) {
                saveWalk()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your route and stats will be saved on this device.")
        }
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Saving…")
                        .padding(24)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        #if DEBUG
        .onDisappear {
            simulationTask?.cancel()
        }
        #endif
    }

    private var liveDistanceKm: Double {
        locationManager.distanceTraveled.metersToKm
    }

    private var livePaceKmh: Double {
        guard viewModel.elapsedTime > 0, liveDistanceKm > 0 else { return 0 }
        return liveDistanceKm / (viewModel.elapsedTime / 3600)
    }

    private var liveCalories: Double {
        liveDistanceKm * WalkingConstants.defaultCalorieBurnRate * 100
    }

    private var statusPill: some View {
        VStack(spacing: 8) {
            if let permissionMessage {
                Text(permissionMessage)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                if LocationPermissionHandler.canOpenSettings(for: locationManager.authorizationStatus) {
                    Button("Open Settings") {
                        LocationPermissionHandler.openSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            Text(statusLabel)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 56)
        }
    }

    private var statusLabel: String {
        switch viewModel.phase {
        case .idle:
            return "Ready"
        case .tracking:
            return "Tracking"
        case .paused:
            return "Paused"
        }
    }

    private var controlBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button {
                    if viewModel.phase == .idle {
                        locationManager.requestLocationPermission()
                        viewModel.startWalk()
                    } else if viewModel.phase == .tracking || viewModel.phase == .paused {
                        HapticService.shared.heavyImpact()
                        showStopConfirmation = true
                    }
                } label: {
                    Text(viewModel.phase == .idle ? "Start" : "Stop")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.phase == .idle ? Color.green : Color.red, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .disabled(isSaving)

                if viewModel.phase == .tracking {
                    Button {
                        viewModel.pauseWalk()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                } else if viewModel.phase == .paused {
                    Button {
                        viewModel.resumeWalk()
                    } label: {
                        Label("Resume", systemImage: "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
            }

            if viewModel.phase != .idle {
                Button("Cancel walk", role: .destructive) {
                    viewModel.cancelWalk()
                }
                .font(.subheadline)
            }

            #if DEBUG
            Button("Simulate Walk") {
                if viewModel.phase == .idle {
                    viewModel.startWalk()
                }
                runSimulation()
            }
            .font(.caption)
            .buttonStyle(.bordered)
            #endif
        }
    }

    private func saveWalk() {
        isSaving = true
        let notes = notesDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesOpt = notes.isEmpty ? nil : notes
        if viewModel.stopWalk(notes: notesOpt) != nil {
            HapticService.shared.success()
            showSavedToast = true
            notesDraft = ""
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    showSavedToast = false
                }
            }
        }
        isSaving = false
    }

    private func syncPermissionMessage() {
        let status = locationManager.authorizationStatus
        if status == .denied || status == .restricted {
            permissionMessage = LocationPermissionHandler.statusMessage(for: status)
        } else {
            permissionMessage = nil
        }
    }

    #if DEBUG
    private func runSimulation() {
        simulationTask?.cancel()
        simulationTask = Task {
            let base = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
            for index in 0..<28 {
                let nanos = UInt64(WalkingConstants.locationUpdateTimeInterval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                guard !Task.isCancelled else { return }
                let angle = Double(index) / 28.0 * 2 * .pi
                let dLat = cos(angle) * 0.0008
                let dLon = sin(angle) * 0.0008
                let coordinate = CLLocationCoordinate2D(
                    latitude: base.latitude + dLat,
                    longitude: base.longitude + dLon
                )
                let location = CLLocation(
                    coordinate: coordinate,
                    altitude: 0,
                    horizontalAccuracy: 5,
                    verticalAccuracy: 5,
                    course: 0,
                    speed: 1.2 + Double(index) * 0.02,
                    timestamp: Date()
                )
                await MainActor.run {
                    locationManager.appendSimulatedLocation(location)
                }
            }
        }
    }
    #endif
}
