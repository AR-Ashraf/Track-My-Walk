import SwiftUI

/// Main walk-tracking shell (Track + History tabs). Listed as `ContentView` in the build checklist.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            DashboardView()
        }
    }
}
