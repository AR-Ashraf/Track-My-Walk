import SwiftData
import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if viewModel.sortedWalks.isEmpty {
                ContentUnavailableView(
                    "No walks yet",
                    systemImage: "figure.walk",
                    description: Text("Start tracking from the Track tab to see your walks here.")
                )
            } else {
                List {
                    ForEach(viewModel.sortedWalks, id: \.id) { walk in
                        NavigationLink {
                            WalkDetailView(
                                viewModel: WalkDetailViewModel(walk: walk.toWalk(), modelContext: modelContext)
                            )
                        } label: {
                            WalkListItem(walk: walk)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteWalk(atOffsets: offsets, in: viewModel.sortedWalks)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .refreshable {
            await viewModel.refresh()
        }
        .onAppear {
            viewModel.loadWalks()
        }
    }
}
