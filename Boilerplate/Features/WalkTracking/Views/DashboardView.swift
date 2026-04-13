import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var locationManager = LocationManager()
    @State private var trackingViewModel: TrackingViewModel?
    @State private var historyViewModel: HistoryViewModel?
    @State private var navigateToSave: Walk?

    var body: some View {
        ZStack(alignment: .bottom) {
            if let trackingViewModel {
                MapViewRepresentable(
                    coordinates: locationManager.locationPoints.map(\.coordinate),
                    currentLocation: locationManager.currentLocation?.coordinate,
                    isTracking: trackingViewModel.phase == .tracking
                )
            } else {
                // Placeholder so the view always occupies the screen.
                Color.black
            }
        }
        .overlay(alignment: .bottom) {
            if let trackingViewModel {
                WorkoutBottomSheet(
                    locationManager: locationManager,
                    viewModel: trackingViewModel,
                    onFinish: { walk in
                        navigateToSave = walk
                    }
                )
            }
        }
        .overlay {
            if trackingViewModel == nil || historyViewModel == nil {
                ProgressView()
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .overlay(alignment: .topTrailing) {
            if let historyViewModel {
                NavigationLink {
                    HistoryView(viewModel: historyViewModel)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.trailing, 16)
                .padding(.top, 32)
                .safeAreaPadding(.top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $navigateToSave) { walk in
            SaveWalkView(walk: walk) {
                historyViewModel?.loadWalks()
            }
        }
        .task {
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
