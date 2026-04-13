import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var locationManager = LocationManager()
    @State private var trackingViewModel: TrackingViewModel?
    @State private var historyViewModel: HistoryViewModel?
    @State private var navigateToSave: Walk?

    var body: some View {
        Group {
            if let trackingViewModel, let historyViewModel {
                ZStack(alignment: .bottom) {
                    MapViewRepresentable(
                        coordinates: locationManager.locationPoints.map(\.coordinate),
                        currentLocation: locationManager.currentLocation?.coordinate,
                        isTracking: trackingViewModel.phase == .tracking
                    )
                    .ignoresSafeArea()

                    WorkoutBottomSheet(
                        locationManager: locationManager,
                        viewModel: trackingViewModel,
                        onFinish: { walk in
                            navigateToSave = walk
                        }
                    )
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            HistoryView(viewModel: historyViewModel)
                        } label: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
                .navigationDestination(item: $navigateToSave) { walk in
                    SaveWalkView(walk: walk) {
                        historyViewModel.loadWalks()
                    }
                }
            }
        }
        .onAppear {
            if trackingViewModel == nil {
                let tracking = TrackingViewModel(locationManager: locationManager, modelContext: modelContext)
                let history = HistoryViewModel(modelContext: modelContext)
                trackingViewModel = tracking
                historyViewModel = history
                history.loadWalks()
            }
            locationManager.requestLocationPermission()
        }
    }
}

