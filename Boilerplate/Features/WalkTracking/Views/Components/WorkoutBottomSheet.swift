import SwiftUI

struct WorkoutBottomSheet: View {
    let locationManager: LocationManager
    @Bindable var viewModel: TrackingViewModel
    let onFinish: (Walk) -> Void

    @State private var isExpanded: Bool = false
    @GestureState private var dragOffset: CGFloat = 0

    private let collapsedHeight: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            let expandedHeight = geo.size.height
            let targetHeight = isExpanded ? expandedHeight : collapsedHeight
            let sheetHeight = max(collapsedHeight, targetHeight - dragOffset)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    handle
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }

                    if isExpanded {
                        expandedContent
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    } else {
                        collapsedContent
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .frame(height: sheetHeight, alignment: .top)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 20, y: -4)
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 80
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if value.translation.height < -threshold {
                                isExpanded = true
                            } else if value.translation.height > threshold {
                                isExpanded = false
                            }
                        }
                    }
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Handle

    private var handle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(.secondary.opacity(0.4))
            .frame(width: 40, height: 5)
    }

    // MARK: - Collapsed Content

    private var collapsedContent: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text(String(format: "%.0f cal", liveCalories))
                    .font(.title2.bold())
            }

            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 24) {
            statsGrid

            actionButtons
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var statsGrid: some View {
        VStack(spacing: 20) {
            HStack {
                statCell(label: "Duration", value: formattedElapsed)
                Divider().frame(height: 40)
                statCell(label: "Distance", value: String(format: "%.2f km", liveDistanceKm))
            }

            HStack {
                statCell(label: "Pace", value: String(format: "%.1f km/h", livePaceKmh))
                Divider().frame(height: 40)
                statCell(label: "Avg Pace", value: String(format: "%.1f km/h", livePaceKmh))
            }

            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text(String(format: "%.0f cal", liveCalories))
                    .font(.title3.bold())
            }
        }
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch viewModel.phase {
        case .idle:
            PrimaryButton(title: "Start Workout") {
                locationManager.requestLocationPermission()
                viewModel.startWalk()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }

        case .tracking:
            SecondaryButton(title: "Pause") {
                viewModel.pauseWalk()
            }

        case .paused:
            HStack(spacing: 12) {
                Button {
                    if let walk = viewModel.finishWalk() {
                        onFinish(walk)
                    }
                } label: {
                    Text("Finish")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }

                Button {
                    viewModel.resumeWalk()
                } label: {
                    Text("Resume")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    // MARK: - Live Computed Values

    private var liveDistanceKm: Double {
        locationManager.distanceTraveled.metersToKm
    }

    private var livePaceKmh: Double {
        guard viewModel.elapsedTime > 0, liveDistanceKm > 0 else { return 0 }
        return liveDistanceKm / (viewModel.elapsedTime / 3600)
    }

    private var liveCalories: Double {
        liveDistanceKm * WalkingConstants.defaultCalorieBurnRate * 100
    }

    private var formattedElapsed: String {
        let t = Int(viewModel.elapsedTime)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}
