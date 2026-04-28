import AuthenticationServices
import SwiftUI

#if canImport(GoogleSignInSwift)
import GoogleSignInSwift
#endif

struct SignInView: View {
    @Environment(FirebaseAuthService.self) private var auth
    @State private var loadingProvider: LoadingProvider?

    private enum LoadingProvider {
        case google
        case apple
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            Text("Track My Walk")
                .font(.largeTitle.weight(.bold))

            Text("Sign in to back up your walks and restore them on new devices.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                #if canImport(GoogleSignInSwift)
                Button {
                    loadingProvider = .google
                    Task {
                        await auth.signInWithGoogle()
                        loadingProvider = nil
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.white)

                        if auth.isLoading, loadingProvider == .google {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                        } else {
                            HStack(spacing: 10) {
                                Image("GoogleLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)

                                Text("Sign in with Google")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .frame(height: 52)
                .disabled(auth.isLoading)
                #else
                Button {
                    loadingProvider = .google
                    Task {
                        await auth.signInWithGoogle()
                        loadingProvider = nil
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                        if auth.isLoading, loadingProvider == .google {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.black)
                        } else {
                            HStack(spacing: 10) {
                                Image("GoogleLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)

                                Text("Sign in with Google")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .disabled(auth.isLoading)
                #endif

                Button {
                    loadingProvider = .apple
                    Task {
                        await auth.signInWithApple()
                        loadingProvider = nil
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.black)

                        if auth.isLoading, loadingProvider == .apple {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            HStack(spacing: 10) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)

                                Text("Sign in with Apple")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
                .frame(height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 0.5)
                )
                .disabled(auth.isLoading)
            }
            .padding(.horizontal)

            if let message = auth.lastErrorMessage, !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            Spacer(minLength: 24)
        }
        .padding()
    }
}

