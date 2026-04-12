import SwiftData
import SwiftUI

/// Root tab experience: track walks, history, and settings.
struct WalkMainTabView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var locationManager = LocationManager()
    @State private var trackingViewModel: TrackingViewModel?
    @State private var historyViewModel: HistoryViewModel?

    var body: some View {
        Group {
            if let trackingViewModel, let historyViewModel {
                TabView {
                    NavigationStack {
                        TrackingView(viewModel: trackingViewModel, locationManager: locationManager)
                            .navigationTitle("Track")
                    }
                    .tabItem {
                        Label("Track", systemImage: "figure.walk")
                    }

                    NavigationStack {
                        HistoryView(viewModel: historyViewModel)
                    }
                    .tabItem {
                        Label("History", systemImage: "clock")
                    }

                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
                .tint(.blue)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: trackingViewModel != nil)
        .onAppear {
            if trackingViewModel == nil {
                let tracking = TrackingViewModel(locationManager: locationManager, modelContext: modelContext)
                let history = HistoryViewModel(modelContext: modelContext)
                tracking.onWalkSaved = {
                    history.loadWalks()
                }
                trackingViewModel = tracking
                historyViewModel = history
                history.loadWalks()
            }
            locationManager.requestLocationPermission()
        }
    }
}
