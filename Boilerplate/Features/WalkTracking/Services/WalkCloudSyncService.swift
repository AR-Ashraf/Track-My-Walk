import FirebaseFirestore
import Foundation
import SwiftData

@Observable
@MainActor
final class WalkCloudSyncService {
    private let db = Firestore.firestore()

    func uploadWalk(model: WalkModel, uid: String) async throws {
        let doc = WalkFirestoreMapper.toDocument(model)
        try await db
            .collection("users")
            .document(uid)
            .collection("walks")
            .document(model.id.uuidString)
            .setData(doc, merge: true)
    }

    func deleteWalk(id: UUID, uid: String) async throws {
        try await db
            .collection("users")
            .document(uid)
            .collection("walks")
            .document(id.uuidString)
            .delete()
    }

    func fetchAllWalks(uid: String) async throws -> [WalkFirestoreMapper.CloudWalk] {
        let snapshot = try await db
            .collection("users")
            .document(uid)
            .collection("walks")
            .getDocuments()

        return try snapshot.documents.map { try WalkFirestoreMapper.fromSnapshot($0) }
    }

    /// Import from Firestore only if the local SwiftData store has zero walks.
    func importIfLocalEmpty(uid: String, modelContext: ModelContext) async throws -> Bool {
        let count = try modelContext.fetchCount(FetchDescriptor<WalkModel>())
        guard count == 0 else { return false }

        let cloudWalks = try await fetchAllWalks(uid: uid)
        for cw in cloudWalks {
            guard let uuid = UUID(uuidString: cw.id) else { continue }
            let model = WalkModel(
                id: uuid,
                date: cw.date,
                name: cw.name,
                duration: cw.duration,
                distanceInKm: cw.distanceInKm,
                caloriesBurned: cw.caloriesBurned,
                routePoints: cw.routePoints,
                averagePace: cw.averagePace,
                maxSpeed: cw.maxSpeed,
                notes: cw.notes,
                stepCount: cw.stepCount,
                averageCadenceSpm: cw.averageCadenceSpm,
                weatherCaptured: cw.weatherCaptured,
                weatherConditionKind: cw.weatherConditionKind,
                weatherDisplayName: cw.weatherDisplayName,
                temperatureCelsius: cw.temperatureCelsius,
                humidityPercent: cw.humidityPercent,
                windMph: cw.windMph
            )
            modelContext.insert(model)
        }
        modelContext.saveIfNeeded()
        return true
    }
}

