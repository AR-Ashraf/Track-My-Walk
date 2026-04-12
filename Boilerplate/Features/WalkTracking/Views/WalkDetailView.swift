import CoreLocation
import SwiftUI

struct WalkDetailView: View {
    @Bindable var viewModel: WalkDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                MapViewRepresentable(
                    coordinates: viewModel.walk.routePoints.map(\.coordinate),
                    currentLocation: nil
                )
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                statsGrid

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

                HStack(spacing: 12) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Walk details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            ActivityShareSheet(items: [viewModel.shareWalk()])
        }
        .confirmationDialog(
            "Delete this walk?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteWalk()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
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
    }

    private var statsGrid: some View {
        let w = viewModel.walk
        let maxKmh = w.maxSpeed * 3.6
        return VStack(alignment: .leading, spacing: 12) {
            Text(w.date.formatted(date: .complete, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCell(title: "Distance", value: w.distanceInKm.formatDistance())
                statCell(title: "Duration", value: w.duration.formattedHMS)
                statCell(title: "Avg pace", value: w.averagePace.formatPace())
                statCell(title: "Max speed", value: maxKmh.formatPace())
                statCell(title: "Calories", value: w.caloriesBurned.formatCalories())
                statCell(title: "Avg speed", value: viewModel.statistics.averageSpeed.formatPace())
            }
        }
    }

    private func statCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
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
