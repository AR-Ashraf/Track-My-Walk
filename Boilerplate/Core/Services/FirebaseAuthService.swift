import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseCore)
import FirebaseCore
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@Observable
@MainActor
final class FirebaseAuthService {
    private(set) var userId: String?
    private(set) var isLoading: Bool = false
    private(set) var lastErrorMessage: String?

    var isAuthenticated: Bool { userId != nil }

    #if canImport(FirebaseAuth)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    #endif

    init() {
        #if canImport(FirebaseAuth)
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.userId = user?.uid
            }
        }
        #else
        userId = nil
        #endif
    }

    // Note: We intentionally do not remove the auth state listener in deinit.
    // `deinit` is nonisolated, and this service is expected to live for the app lifetime anyway.

    func signOut() {
        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
            userId = nil
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #endif
    }

    func signInWithGoogle() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        #if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            lastErrorMessage = "Missing Firebase client ID. Check GoogleService-Info.plist."
            return
        }

        guard let presentingViewController = UIApplication.shared.topMostViewController else {
            lastErrorMessage = "Could not find a presenting view controller."
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        do {
            GIDSignIn.sharedInstance.configuration = config
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                lastErrorMessage = "Google sign-in failed to return an ID token."
                return
            }
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            let authResult = try await Auth.auth().signIn(with: credential)
            userId = authResult.user.uid
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #else
        lastErrorMessage = "Google sign-in is not available (missing SDKs)."
        #endif
    }

    func signInWithApple() async {
        isLoading = true
        lastErrorMessage = nil
        defer { isLoading = false }

        #if canImport(FirebaseAuth)
        do {
            let nonce = Self.randomNonceString()
            let appleCredential = try await AppleSignInCoordinator().authorize(nonce: nonce)

            guard let identityTokenData = appleCredential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8)
            else {
                lastErrorMessage = "Apple sign-in failed to return a valid identity token."
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: identityToken,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )

            let authResult = try await Auth.auth().signIn(with: credential)
            userId = authResult.user.uid
        } catch {
            lastErrorMessage = error.localizedDescription
        }
        #else
        lastErrorMessage = "Apple sign-in is not available (missing FirebaseAuth)."
        #endif
    }

    // MARK: - Nonce helpers (Firebase recommends SHA256 nonces for Apple sign-in)

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }

            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

@MainActor
private final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func authorize(nonce: String) async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            // Firebase requires a SHA256 nonce on the request.
            request.nonce = FirebaseAuthService.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: 0))
            continuation = nil
            return
        }
        continuation?.resume(returning: credential)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.activeWindow ?? ASPresentationAnchor()
    }
}

private extension UIApplication {
    var activeWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    var topMostViewController: UIViewController? {
        guard let root = activeWindow?.rootViewController else { return nil }
        return root.topMostPresented
    }
}

private extension UIViewController {
    var topMostPresented: UIViewController {
        if let presented = presentedViewController {
            return presented.topMostPresented
        }
        if let nav = self as? UINavigationController, let visible = nav.visibleViewController {
            return visible.topMostPresented
        }
        if let tab = self as? UITabBarController, let selected = tab.selectedViewController {
            return selected.topMostPresented
        }
        return self
    }
}

