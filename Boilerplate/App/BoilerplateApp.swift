import SwiftData
import SwiftUI

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(GoogleMaps)
import GoogleMaps
#endif

@main
struct BoilerplateApp: App {
    // MARK: - Dependencies

    private let router = Router.shared
    private let apiClient = APIClient()
    private let authService: AuthService
    private let firebaseAuthService: FirebaseAuthService
    private let walkCloudSyncService: WalkCloudSyncService
    private let analyticsService = AnalyticsService()

    // MARK: - Initialization

    init() {
        Self.configureFirebase()
        authService = AuthService(apiClient: apiClient)
        firebaseAuthService = FirebaseAuthService()
        walkCloudSyncService = WalkCloudSyncService()
        configureMaps()
        configureAppearance()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(apiClient)
                .environment(authService)
                .environment(firebaseAuthService)
                .environment(walkCloudSyncService)
                .environment(analyticsService)
        }
        .modelContainer(SwiftDataContainer.shared)
    }

    // MARK: - Private Methods

    private func configureAppearance() {
        // Configure global appearance settings
        #if DEBUG
        Logger.shared.app("App launched in \(AppEnvironment.current.rawValue) mode")
        #endif
    }

    private func configureMaps() {
        #if canImport(GoogleMaps)
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            GMSServices.provideAPIKey(apiKey)
        } else {
            Logger.shared.app("Google Maps API key missing (Info.plist key: GMSApiKey)", level: .error)
        }
        #endif
    }

    private static func configureFirebase() {
        #if canImport(FirebaseCore)
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        #endif
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(Router.self) private var router
    @Environment(FirebaseAuthService.self) private var firebaseAuth
    @Environment(WalkCloudSyncService.self) private var cloudSync
    @Environment(\.modelContext) private var modelContext
    @State private var hasAttemptedRestore = false

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            Group {
                if firebaseAuth.isAuthenticated {
                    ContentView()
                } else {
                    SignInView()
                }
            }
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .sheet(item: $router.presentedSheet) { sheet in
            sheetView(for: sheet)
        }
        .task(id: firebaseAuth.userId) {
            // Local-first: only restore from Firestore when local store has zero walks.
            guard let uid = firebaseAuth.userId else { return }
            guard !hasAttemptedRestore else { return }
            hasAttemptedRestore = true
            _ = try? await cloudSync.importIfLocalEmpty(uid: uid, modelContext: modelContext)
        }
    }

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView()
        case .exampleList:
            ExampleListView()
        case .exampleDetail(let id):
            ExampleDetailView(itemId: id)
        case .exampleForm(let item):
            ExampleFormView(existingItem: item)
        case .settings:
            SettingsView()
        case .profile:
            ProfileView()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: Sheet) -> some View {
        switch sheet {
        case .login:
            LoginView()
        case .signUp:
            SignUpView()
        }
    }
}

// MARK: - Home View (Placeholder)

struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        List {
            Section("Features") {
                Button("Example Feature") {
                    router.navigate(to: .exampleList)
                }
            }

            Section("Account") {
                Button("Settings") {
                    router.navigate(to: .settings)
                }
            }
        }
        .navigationTitle("Home")
    }
}

// MARK: - Profile View (Placeholder)

struct ProfileView: View {
    @Environment(AuthService.self) private var authService

    var body: some View {
        List {
            if let user = authService.currentUser {
                Section {
                    LabeledContent("Name", value: user.name)
                    LabeledContent("Email", value: user.email)
                }
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authService.signOut()
                    }
                }
            }
        }
        .navigationTitle("Profile")
    }
}
