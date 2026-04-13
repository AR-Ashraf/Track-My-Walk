# Track My Walk (iOS)

**Track My Walk** is an offline-first walking tracker for iOS (similar to “Map My Walk”, without social features). It records a walking route on a map, shows live stats (distance / time / pace / calories), and saves walks locally for later viewing.

## What the app does

- **Track a walk in real time**
  - Live map with a blue route polyline
  - Live stats: **distance**, **duration**, **pace**, **calories**
- **Save the walk locally**
  - Name your walk on the Save screen
  - Stored on-device using **SwiftData** (no backend)
- **History**
  - List of past walks (shows the walk **name** as the primary label)
  - Walk details view with a **static route preview** (fits the polyline; does not follow your current location)

## Tech stack

- **SwiftUI** (iOS 17+)
- **MVVM** with the iOS 17 **`@Observable`** macro
- **CoreLocation** for GPS tracking
- **SwiftData** for local persistence
- **Google Maps SDK for iOS** (preferred) with a MapKit fallback if the SDK isn’t linked

## Architecture (high level)

- **Views**: Pure SwiftUI UI composition (screens + reusable components)
- **ViewModels**: State + business logic, declared with `@Observable`
- **Core services**:
  - `LocationManager` (CoreLocation delegate + route accumulation + distance computation)
  - SwiftData container setup for persistence
- **Data**
  - `WalkModel` is the SwiftData `@Model` persisted to disk
  - `Walk` is a UI-layer model used by the screens and view models

## Data model / storage

Walks are stored locally in SwiftData:

- `WalkModel`
  - `id`, `date`, `name`
  - `duration`, `distanceInKm`, `averagePace`, `maxSpeed`, `caloriesBurned`
  - `routePointsData` (route points stored as JSON-encoded `Data`)

No network calls are required for the tracking feature set.

## Project layout (relevant parts)

```
Boilerplate/
├── App/                          # App entry + onboarding
├── Core/
│   ├── Location/                 # CoreLocation manager + permissions
│   └── Persistence/              # SwiftData container
├── Features/
│   └── WalkTracking/
│       ├── Models/               # Walk (UI model), WalkPoint, WalkStatistics
│       ├── ViewModels/           # Tracking / History / WalkDetail
│       └── Views/                # Dashboard, Save, History, Detail, components
└── Assets.xcassets/              # App icon + in-app logo
```

## Getting started (step-by-step)

### Requirements

- macOS with **Xcode 15+** (recommended: Xcode 16 if you have it)
- iOS 17+ simulator or an iPhone running iOS 17+
- A **Google Maps API key** (recommended) if you want Google Maps rendering

### 1) Clone the repo

```bash
git clone https://github.com/AR-Ashraf/Track-My-Walk.git
cd "Track My Walk"
```

### 2) Open the project in Xcode

```bash
open Boilerplate.xcodeproj
```

### 3) Configure signing (for running on your iPhone)

In Xcode:

- Select the project (blue icon) → select the **`Boilerplate`** target
- **Signing & Capabilities**
  - Check **Automatically manage signing**
  - Choose your **Team**
  - Set a unique **Bundle Identifier** (e.g. `com.yourname.trackmywalk`)

### 4) Add Google Maps SDK (only if it isn’t already linked)

If the app is showing Apple Maps and you want Google Maps:

- Xcode → **File → Add Package Dependencies**
- Add the Google Maps package used by this repo (already referenced by the project)
- Ensure the app target links **GoogleMaps** in “Frameworks, Libraries, and Embedded Content”

### 5) Set your Google Maps API key

This app reads the key from `Boilerplate/Resources/Info.plist` under `GMSApiKey`.

Steps:
- Create an API key in Google Cloud Console (enable **Maps SDK for iOS**)
- In Xcode, open `Boilerplate/Resources/Info.plist`
- Set:
  - `GMSApiKey` = `YOUR_API_KEY_HERE`

> Tip: If you commit this repo publicly, do **not** commit real API keys.

### 6) Run on Simulator

- Select a simulator device (e.g. iPhone 15/16)
- Press **⌘R**
- To simulate movement: Simulator → **Features → Location →** choose a preset route (or create a custom GPX)

### 7) Run on your iPhone

- Plug in your iPhone via USB (or enable Wireless Debugging)
- Select your iPhone in the Xcode device picker
- Press **⌘R**
- On the device, if prompted: Settings → Privacy & Security → Location Services → allow location access

## App icon & logo

- **App icon (home screen)**: `Boilerplate/Assets.xcassets/AppIcon.appiconset/trackmywalklogo.png`
- **In-app logo (Onboarding)**: `Boilerplate/Assets.xcassets/AppLogo.imageset/trackmywalklogo.png`

If the icon doesn’t update on a device immediately, delete the app from the iPhone and reinstall (iOS sometimes caches icons).

## Notes / common troubleshooting

- **Location updates crash on device**: ensure the project has the **Location updates** background capability if you want background tracking.
- **Map in walk details moves**: the details screen uses a route preview mode (static, fits route). The dashboard is live by design.

## License

See [LICENSE](LICENSE).
