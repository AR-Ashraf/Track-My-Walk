# Track My Walk — Dashboard Redesign Plan

## What We're Building

Replace the current tab-based TrackingView with a full-screen Dashboard:
- Live map fills the entire screen
- Custom bottom sheet snaps between 1/3 height (collapsed) and full height (expanded)
- Bottom sheet content changes based on walk phase (idle → tracking → paused)
- Finish flow navigates to a SaveWalkView (named save, not an alert)
- History accessed via top-right icon (NavigationLink), not a tab

---

## Current State (what already exists and is kept)

| Existing | Status |
|---|---|
| `TrackingViewModel` (start/pause/resume/stop/cancel) | ✅ Keep as-is |
| `LocationManager` (GPS, distanceTraveled, locationPoints) | ✅ Keep as-is |
| `MapViewRepresentable` (polyline + user location) | ✅ Keep, small tweak |
| `Walk` struct + `WalkModel` (@Model) | ✅ Keep as-is |
| `HistoryView` + `WalkDetailView` | ✅ Keep as-is |
| `WalkListItem`, `WalkStatsCard` | ✅ Keep as-is |
| `WalkMainTabView` (TabView) | ❌ Replace with DashboardView |
| `TrackingView` (current layout) | ❌ Replace with DashboardView |
| Alert-based save flow in TrackingView | ❌ Replace with SaveWalkView |

---

## Navigation Structure (new)

```
BoilerplateApp
└── NavigationStack
    └── DashboardView                  ← new root screen
        ├── [toolbar] HistoryButton    → push HistoryView
        ├── MapViewRepresentable       ← full screen, ignoresSafeArea
        ├── WorkoutBottomSheet         ← new component, overlays map
        └── [navigate on finish]       → push SaveWalkView
            └── SaveWalkView           ← new screen
                └── [after save]       → pop to DashboardView
```

No TabView. Settings can remain accessible later via a gear icon in the toolbar if needed (out of scope for this plan).

---

## Phase 1 — DashboardView Shell & Navigation Wiring

**Goal:** App launches directly into DashboardView with the map visible and history accessible.

### Files to create
- `Boilerplate/Features/WalkTracking/Views/DashboardView.swift`

### Files to modify
- `Boilerplate/App/BoilerplateApp.swift` — swap `WalkMainTabView` for `NavigationStack { DashboardView(...) }`
- `Boilerplate/Features/WalkTracking/Views/ContentView.swift` — update to wrap DashboardView

### DashboardView responsibilities
- Owns `@State private var locationManager = LocationManager()`
- Owns `@State private var trackingViewModel: TrackingViewModel`
- Owns `@State private var navigateToSave: Walk? = nil` (drives NavigationLink to SaveWalkView)
- Toolbar: trailing history icon → NavigationLink to HistoryView
- Body: ZStack with MapViewRepresentable + WorkoutBottomSheet overlay
- On appear: request location permission

### Key wiring
```swift
// In DashboardView toolbar
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        NavigationLink { HistoryView(viewModel: historyViewModel) } label: {
            Image(systemName: "clock.arrow.circlepath")
        }
    }
}

// Navigation to SaveWalkView after finish
.navigationDestination(item: $navigateToSave) { walk in
    SaveWalkView(walk: walk, onSaved: {
        historyViewModel.loadWalks()
    })
}
```

---

## Phase 2 — WorkoutBottomSheet Component

**Goal:** Draggable sheet snapping to 1/3 height (collapsed) or full height (expanded). Content changes per walk phase.

### Files to create
- `Boilerplate/Features/WalkTracking/Views/Components/WorkoutBottomSheet.swift`

### Snap behaviour
- **Collapsed** = sheet peek height of ~280pt (shows calories + button)
- **Expanded** = sheet fills full screen (shows all stats + button)
- Drag up/down snaps between positions
- A drag handle at top of sheet

### Implementation approach
Custom overlay sheet (NOT native `.sheet`) — overlaid on the map using a ZStack in DashboardView, positioned with offset/geometry.

```swift
struct WorkoutBottomSheet: View {
    // inputs
    let locationManager: LocationManager
    @Bindable var viewModel: TrackingViewModel
    let onFinish: (Walk) -> Void     // called with completed Walk when user taps Finish

    // local state
    @State private var isExpanded: Bool = false
    @GestureState private var dragOffset: CGFloat = 0

    private let collapsedHeight: CGFloat = 280
    // expanded height = full screen (use GeometryReader from parent)
}
```

### Collapsed content (1/3 view)
```
┌─────────────────────────────┐
│        ─── (handle)         │
│                             │
│   🔥  342 cal               │
│                             │
│   [ Start Workout ]         │
│                             │
└─────────────────────────────┘
```

### Expanded content (full view)
```
┌─────────────────────────────┐
│        ─── (handle)         │
│                             │
│  00:00      0.00 km         │
│  Duration   Distance        │
│                             │
│  0.0 km/h   0.0 km/h        │
│  Pace       Avg Pace        │
│                             │
│  🔥 0 cal                   │
│                             │
│   [ Start Workout ]         │
│                             │
└─────────────────────────────┘
```

### Button states by phase
| Phase | Button(s) shown |
|---|---|
| `.idle` | "Start Workout" (green) |
| `.tracking` | "Pause" (orange) |
| `.paused` | "Finish" (red) + "Resume" (green) side by side |

### Tap to expand
Tapping the handle or collapsed area also expands the sheet.

---

## Phase 3 — Real-time Map Auto-follow

**Goal:** Map centers on user's current location as they walk and shows the growing route.

### Files to modify
- `Boilerplate/Features/WalkTracking/Views/Components/MapViewRepresentable.swift`

### Changes
- Add `var isTracking: Bool` parameter
- When `isTracking == true` and a new coordinate arrives: center map on latest coordinate with a tight zoom region (~200m span) instead of fitting the full route
- When `isTracking == false` (idle / after finish): fit full route as it does today
- Add `userTrackingMode = .follow` when tracking starts, `.none` when stopped

```swift
// In updateUIView:
if isTracking, let last = coordinates.last {
    let region = MKCoordinateRegion(center: last, latitudinalMeters: 200, longitudinalMeters: 200)
    mapView.setRegion(region, animated: true)
} else {
    // existing fit-all-coordinates logic
}
```

---

## Phase 4 — SaveWalkView (Finish Flow)

**Goal:** After tapping Finish, user lands on a screen that shows walk summary, enters a name, and taps Save.

### Files to create
- `Boilerplate/Features/WalkTracking/Views/SaveWalkView.swift`

### Files to modify
- `Boilerplate/Features/WalkTracking/ViewModels/TrackingViewModel.swift`
  - Change `stopWalk(notes:)` to NOT auto-insert into modelContext — return the `Walk` data and let SaveWalkView handle persistence after the user enters a name
  - OR: keep `stopWalk` as-is but add `stopWalkForReview()` that returns a `Walk` without saving
  - Decision: add `finishWalk() -> Walk?` that captures route data and resets state but does NOT persist. SaveWalkView calls its own save function.

### SaveWalkView layout
```
NavigationStack title: "Save Workout"

┌─────────────────────────────┐
│  Map snapshot (static)      │  ← MapViewRepresentable with walk route, non-interactive
│  (height: 200pt)            │
├─────────────────────────────┤
│  Stats grid (2 col)         │
│  Distance | Duration        │
│  Pace     | Calories        │
├─────────────────────────────┤
│  Walk Name                  │
│  [ ________________________]│  ← TextField, focused on appear
├─────────────────────────────┤
│  [ Save ]   ← full-width    │
└─────────────────────────────┘
```

### SaveWalkView logic
```swift
struct SaveWalkView: View {
    let walk: Walk
    let onSaved: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    func save() {
        let model = WalkModel(from: walk, name: name.isEmpty ? "Walk" : name)
        modelContext.insert(model)
        modelContext.saveIfNeeded()
        onSaved()
        dismiss()
    }
}
```

### TrackingViewModel — new finishWalk method
```swift
// Returns the walk data without persisting. SaveWalkView handles persistence.
func finishWalk() -> Walk? {
    guard phase == .tracking || phase == .paused else { return nil }
    tickTimer?.invalidate()
    tickTimer = nil
    // build Walk struct from current data (same as stopWalk but no modelContext.insert)
    let walk = buildWalk()
    phase = .idle
    elapsedTime = 0
    locationManager.reset()
    return walk
}
```

### WalkModel — add name property
```swift
@Model
final class WalkModel {
    var name: String = "Walk"    // ← add this
    // ... existing properties
}
```

---

## Phase 5 — History Icon & Full History Flow

**Goal:** History is accessible from DashboardView toolbar, not a tab.

### Already works
- `HistoryView` + `WalkDetailView` + `WalkListItem` all exist and work correctly
- `HistoryViewModel` loads/deletes walks from SwiftData

### Changes needed
- `DashboardView` owns `@State private var historyViewModel: HistoryViewModel`
- Toolbar trailing: `NavigationLink { HistoryView(viewModel: historyViewModel) } label: { Image(systemName: "clock.arrow.circlepath") }`
- `HistoryView` already uses `NavigationLink` to `WalkDetailView` — this works inside the NavigationStack

### Result
Top-right icon → pushes HistoryView → tap walk → pushes WalkDetailView → back button returns to Dashboard

---

## Implementation Order

1. Phase 4 first (TrackingViewModel.finishWalk + WalkModel.name) — purely logic, no UI risk
2. Phase 1 (DashboardView shell + navigation wiring) — establishes the new root
3. Phase 2 (WorkoutBottomSheet) — core new UI component
4. Phase 3 (Map auto-follow tweak) — small change to MapViewRepresentable
5. Phase 5 (history toolbar button) — simple wiring, last

---

## Files Summary

| Action | File |
|---|---|
| Create | `DashboardView.swift` |
| Create | `WorkoutBottomSheet.swift` |
| Create | `SaveWalkView.swift` |
| Modify | `BoilerplateApp.swift` (swap root) |
| Modify | `ContentView.swift` (optional, thin wrapper) |
| Modify | `TrackingViewModel.swift` (add finishWalk) |
| Modify | `WalkModel` in Core/Database (add name field) |
| Modify | `MapViewRepresentable.swift` (add isTracking param) |
| Delete | `TrackingView.swift` (replaced by DashboardView) |
| Delete | `WalkMainTabView.swift` (replaced by DashboardView) |
