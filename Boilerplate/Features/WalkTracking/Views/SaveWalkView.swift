import CoreLocation
import SwiftData
import SwiftUI

struct SaveWalkView: View {
    let walk: Walk
    let onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @FocusState private var nameFieldFocused: Bool

    private var liveDistanceKm: Double { walk.distanceInKm }
    private var livePaceKmh: Double { walk.averagePace }
    private var liveCalories: Double { walk.caloriesBurned }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                mapSnapshot

                statsGrid
                    .padding(.horizontal)
                    .padding(.top, 20)

                nameSection
                    .padding(.horizontal)
                    .padding(.top, 24)

                saveButton
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Save Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { nameFieldFocused = true }
    }

    // MARK: - Map Snapshot

    private var mapSnapshot: some View {
        MapViewRepresentable(
            coordinates: walk.routePoints.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) },
            currentLocation: walk.routePoints.last.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) },
            isTracking: false
        )
        .frame(height: 220)
        .allowsHitTesting(false)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCell(title: "Distance", value: String(format: "%.2f km", liveDistanceKm))
            statCell(title: "Duration", value: formattedDuration(walk.duration))
            statCell(title: "Pace", value: String(format: "%.1f km/h", livePaceKmh))
            statCell(title: "Calories", value: String(format: "%.0f cal", liveCalories))
        }
        .padding(16)
        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Name Field

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Walk Name")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            TextField("e.g. Morning Walk", text: $name)
                .focused($nameFieldFocused)
                .padding(12)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            saveWalk()
        } label: {
            Text("Save")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Actions

    private func saveWalk() {
        let resolvedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = WalkModel(
            name: resolvedName.isEmpty ? "Walk" : resolvedName,
            duration: walk.duration,
            distanceInKm: walk.distanceInKm,
            caloriesBurned: walk.caloriesBurned,
            routePoints: walk.routePoints.map {
                WalkPointData(latitude: $0.latitude, longitude: $0.longitude, timestamp: $0.timestamp)
            },
            averagePace: walk.averagePace,
            maxSpeed: walk.maxSpeed,
            notes: walk.notes
        )
        modelContext.insert(model)
        modelContext.saveIfNeeded()
        HapticService.shared.success()
        onSaved()
        dismiss()
    }

    // MARK: - Helpers

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
