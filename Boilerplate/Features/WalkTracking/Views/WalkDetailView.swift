import CoreLocation
import SwiftUI

struct WalkDetailView: View {
    @Bindable var viewModel: WalkDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showShareSheet = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @State private var showWorkoutOptions = false
    @State private var showEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MapViewRepresentable(
                    coordinates: viewModel.walk.routePoints.map(\.coordinate),
                    currentLocation: nil,
                    displayMode: .routePreview
                )
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                summarySection

                weatherSection

                if let notes = viewModel.walk.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        Text(notes)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(viewModel.walk.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: [viewModel.shareWalk()])
        }
        .confirmationDialog("Workout Options", isPresented: $showWorkoutOptions, titleVisibility: .visible) {
            Button("Edit") { showEdit = true }
            Button("Delete", role: .destructive) { deleteWalk() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Could not delete", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage)
        }
        .onAppear {
            viewModel.onDeleted = {
                dismiss()
            }
        }
        .navigationDestination(isPresented: $showEdit) {
            EditWalkView(viewModel: viewModel)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                Button {
                    showWorkoutOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                }
            }
        }
    }

    private var summarySection: some View {
        let w = viewModel.walk
        let maxKmh = w.maxSpeed * 3.6
        return VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.title3.weight(.bold))

            Text(w.date.formatted(date: .complete, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCell(title: "Distance", value: w.distanceInKm.formatDistance())
                statCell(title: "Duration", value: w.duration.formattedHMS)
                statCell(title: "Avg pace (min/km)", value: w.averagePaceMinPerKm.formatPaceMinutesPerKm())
                statCell(title: "Max speed (km/h)", value: maxKmh.formatSpeed())
                statCell(title: "Calories", value: w.caloriesBurned.formatCalories())
                statCell(title: "Avg speed (km/h)", value: viewModel.statistics.averageSpeedKmh.formatSpeed())
                statCell(title: "Steps", value: "\(w.displayStepCount)")
                statCell(title: "Avg cadence (spm)", value: String(format: "%.0f", w.displayCadenceSpm))
            }

            if w.isStepEstimate {
                Text("Estimate from distance when steps weren’t recorded.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var weatherSection: some View {
        let w = viewModel.walk
        return VStack(alignment: .leading, spacing: 14) {
            Text("Weather")
                .font(.title3.weight(.bold))

            if w.weatherCaptured, let snap = w.weather {
                HStack(alignment: .center, spacing: 16) {
                    WalkDetailWeatherArtwork.hero(for: snap.conditionKind)

                    Text(snap.displayName)
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .top, spacing: 0) {
                    weatherMetric(
                        icon: "thermometer.medium",
                        value: "\(Int(snap.temperatureCelsius.rounded()))°",
                        title: "Temperature"
                    )
                    weatherMetric(
                        icon: "humidity.fill",
                        value: "\(Int(snap.humidityPercent.rounded()))%",
                        title: "Humidity"
                    )
                    weatherMetric(
                        icon: "wind",
                        value: String(format: "%.1f", snap.windMph),
                        title: "Wind (mph)"
                    )
                }
            } else {
                Text("Weather wasn’t recorded for this walk.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func weatherMetric(icon: String, value: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(height: 28)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func deleteWalk() {
        do {
            try viewModel.deleteWalk()
            HapticService.shared.itemDeleted()
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteError = true
        }
    }
}
