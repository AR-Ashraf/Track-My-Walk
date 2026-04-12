import Foundation
import SwiftData

@Observable
@MainActor
final class HistoryViewModel {
    private(set) var walks: [WalkModel] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var sortedWalks: [WalkModel] {
        walks.sorted { $0.date > $1.date }
    }

    var totalDistance: Double {
        sortedWalks.reduce(0) { $0 + $1.distanceInKm }
    }

    var totalDuration: TimeInterval {
        sortedWalks.reduce(0) { $0 + $1.duration }
    }

    var averagePace: Double {
        guard totalDuration > 0 else { return 0 }
        return totalDistance / (totalDuration / 3600)
    }

    func loadWalks() {
        do {
            let descriptor = FetchDescriptor<WalkModel>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            walks = try modelContext.fetch(descriptor)
        } catch {
            Logger.shared.data("Failed to load walks: \(error)", level: .error)
        }
    }

    func refresh() async {
        loadWalks()
    }

    func deleteWalk(_ walk: WalkModel) {
        modelContext.delete(walk)
        modelContext.saveIfNeeded()
        loadWalks()
        HapticService.shared.itemDeleted()
    }

    func deleteWalk(atOffsets offsets: IndexSet, in models: [WalkModel]) {
        for index in offsets {
            modelContext.delete(models[index])
        }
        modelContext.saveIfNeeded()
        loadWalks()
        HapticService.shared.itemDeleted()
    }

    func getWalk(id: UUID) -> WalkModel? {
        walks.first { $0.id == id }
    }

    func getWalksForDateRange(from start: Date, to end: Date) -> [WalkModel] {
        sortedWalks.filter { $0.date >= start && $0.date <= end }
    }
}
