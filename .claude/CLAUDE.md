# Track My Walk — iOS Project Instructions

## Tech Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI (declarative, functional components)
- **Architecture**: MVVM with `@Observable` macro (iOS 17+)
- **Persistence**: SwiftData (`@Model` classes, `ModelContext`)
- **Location**: Core Location + MapKit
- **Async**: Swift Concurrency (`async/await`, `Task`, `@MainActor`)
- **CI/CD**: Xcode Cloud
- **Testing**: XCTest

## Project Structure
```
Boilerplate/
├── App/                    # Entry point, environment setup
├── Features/
│   ├── Auth/               # Login, SignUp (Views, ViewModels, Models)
│   ├── WalkTracking/       # Core feature: tracking, history, detail
│   ├── Settings/           # Settings, DebugConsole
│   └── Example/            # Boilerplate example (can be removed)
├── Core/
│   ├── Location/           # LocationManager (CLLocationManager wrapper)
│   ├── Database/           # SwiftData models (WalkModel, WalkPointData)
│   ├── Networking/         # APIClient
│   ├── Navigation/         # Router, NavigationStack helpers
│   └── Services/           # HapticService, etc.
├── Shared/
│   ├── Components/         # Reusable UI (PrimaryButton, SecondaryButton)
│   ├── Extensions/         # Color+Extensions, etc.
│   ├── Types/              # LoadingState, shared enums
│   └── ViewModifiers/      # Custom SwiftUI modifiers
└── Resources/              # Constants, Info.plist
```

## Architecture Rules

### MVVM with @Observable
- ViewModels use `@Observable` (NOT `ObservableObject`/`@Published`)
- ViewModels are `@MainActor final class`
- Views own ViewModels via `@State` or receive via environment
- No business logic in Views — delegate to ViewModel

```swift
// Correct ViewModel pattern
@Observable
@MainActor
final class MyViewModel {
    var items: [Item] = []
    func loadItems() async { ... }
}

// Correct View pattern
struct MyView: View {
    @State private var viewModel = MyViewModel()
    var body: some View { ... }
}
```

### SwiftData (Persistence)
- Persistence models are `@Model` classes (e.g., `WalkModel`)
- UI models are plain Swift structs (e.g., `Walk`) — always convert via `.toWalk()`
- `ModelContext` is injected via init, never accessed as singleton
- Always call `modelContext.saveIfNeeded()` after insert

### Data Flow
- `Walk` (struct) = UI layer model — passed to Views
- `WalkModel` (@Model class) = SwiftData persistence layer
- `WalkPointData` = Codable route point stored as JSON blob in WalkModel

### Location
- `LocationManager` wraps `CLLocationManager`
- All location work happens off-main; results published via `@Observable`
- `distanceTraveled` is in metres; convert with `.metersToKm` extension

## Code Conventions
- **Naming**: `PascalCase` for types, `camelCase` for properties/functions
- **ViewModels**: Suffix with `ViewModel` (e.g., `TrackingViewModel`)
- **Views**: Suffix with `View` (e.g., `TrackingView`)
- **Models (SwiftData)**: Suffix with `Model` (e.g., `WalkModel`)
- **Models (UI)**: No suffix (e.g., `Walk`, `WalkPoint`)
- **Services**: Suffix with `Service` (e.g., `HapticService`)
- **Access control**: Use `private` aggressively; expose only what's needed
- Extensions grouped by type in `Extensions/` or feature folder

## SwiftUI Patterns
- Prefer `.task {}` over `onAppear` for async work
- Use `@Environment(\.modelContext)` for SwiftData context in Views
- Compose small focused views; extract sub-views as private computed vars or nested structs
- Never put `NavigationStack` inside a child view — own it at the feature root

## Testing
- Test files in `BoilerplateTests/Features/` and `BoilerplateTests/Core/`
- Mocks in `BoilerplateTests/Mocks/`
- Prefer protocol-based mocking (e.g., `MockAuthService`, `MockAPIClient`)
- Test ViewModels directly — no UI testing needed for logic

## Build & Run
- Open `Boilerplate.xcodeproj` in Xcode
- Target: `Boilerplate` (iOS 17+)
- CI: Xcode Cloud (see `docs/XCODE-CLOUD-WORKFLOW.md`)
- Location permission required for walk tracking (already in Info-Walking.plist)

## Before Committing
- Build succeeds with no warnings
- Relevant unit tests pass (Cmd+U)
- No force unwraps (!) added without justification
- No print() left in production code — use Logger
- Commit message: type(scope): description (e.g., feat(walk): add pause support)
