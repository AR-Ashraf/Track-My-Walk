import SwiftUI

struct EditWalkView: View {
    @Bindable var viewModel: WalkDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var date: Date

    init(viewModel: WalkDetailViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.walk.name)
        _date = State(initialValue: viewModel.walk.date)
    }

    var body: some View {
        Form {
            Section("Editable") {
                LabeledContent("Name") {
                    TextField("Walk name", text: $name)
                        .multilineTextAlignment(.trailing)
                }
                DatePicker("Date & time", selection: $date)
            }

            Section("Read-only") {
                row("Distance", value: viewModel.walk.distanceInKm.formatDistance())
                row("Duration", value: viewModel.walk.duration.formattedHMS)
                row("Avg pace", value: viewModel.walk.averagePaceMinPerKm.formatPaceMinutesPerKm())
                row("Calories", value: viewModel.walk.caloriesBurned.formatCalories())
                row("Steps", value: "\(viewModel.walk.displayStepCount)")
                row("Avg cadence (spm)", value: String(format: "%.0f", viewModel.walk.displayCadenceSpm))
            }
        }
        .navigationTitle("Edit Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
                .fontWeight(.semibold)
            }
        }
    }

    private func row(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmed.isEmpty ? "Walk" : trimmed
        do {
            try viewModel.updateMetadata(name: resolvedName, date: date)
            dismiss()
        } catch {
            // If saving fails, just keep user on screen; WalkDetailView shows delete errors similarly.
        }
    }
}

