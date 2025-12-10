//
//  AuthManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import Foundation
import SwiftUI
import Supabase
import AuthenticationServices
import Combine

// MARK: - Auth Manager

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    // MARK: - Dependencies
    
    private let deviceManager = DeviceManager.shared
    private let database = DatabaseService.shared
    
    // MARK: - Published State
    
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUserId: UUID? = nil
    @Published private(set) var currentUserEmail: String? = nil
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var authError: String? = nil
    
    // MARK: - Subscription State
    
    @Published var subscriptionStatus: Bool = false
    @Published var subscriptionExpiry: Date? = nil
    
    /// Combines actual subscription with any bypass flags (for testing)
    var effectiveSubscriptionStatus: Bool {
        return subscriptionStatus || UserData.shared.subscriptionStatus
    }
    
    // MARK: - Init
    
    private init() {
        // Check initial auth state
        Task {
            await checkAuthStatus()
        }
        
        // Listen for auth state changes
        setupAuthListener()
    }
    
    // MARK: - Auth State Listener
    
    private func setupAuthListener() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                print("🔐 Auth state changed: \(event)")
                
                switch event {
                case .initialSession:
                    await handleSessionChange(session)
                case .signedIn:
                    await handleSessionChange(session)
                case .signedOut:
                    handleSignOut()
                case .tokenRefreshed:
                    await handleSessionChange(session)
                case .userUpdated:
                    await handleSessionChange(session)
                default:
                    break
                }
            }
        }
    }
    
    private func handleSessionChange(_ session: Session?) async {
        if let session = session {
            isAuthenticated = true
            currentUserId = session.user.id
            currentUserEmail = session.user.email
            
            // Link anonymous data to authenticated account
            await linkAnonymousData(authId: session.user.id)
            
            print("✅ User authenticated: \(session.user.email ?? "no email")")
        } else {
            isAuthenticated = false
            currentUserId = nil
            currentUserEmail = nil
        }
    }
    
    private func handleSignOut() {
        isAuthenticated = false
        currentUserId = nil
        currentUserEmail = nil
        subscriptionStatus = false
        subscriptionExpiry = nil
        print("👋 User signed out")
    }
    
    // MARK: - Check Current Auth Status
    
    func checkAuthStatus() async {
        do {
            let session = try await supabase.auth.session
            await handleSessionChange(session)
        } catch {
            print("ℹ️ No active session: \(error.localizedDescription)")
            isAuthenticated = false
        }
    }
    
    // MARK: - Sign In Methods
    
    /// Sign in with Apple (native)
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            authError = "Failed to get identity token from Apple"
            throw AuthError.missingToken
        }
        
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )
            
            await handleSessionChange(session)
            print("✅ Signed in with Apple")
        } catch {
            authError = error.localizedDescription
            print("❌ Apple sign in failed: \(error)")
            throw error
        }
    }
    
    /// Sign in with Google (via Supabase OAuth - opens Safari)
    /// No GoogleSignIn SDK needed!
    func signInWithGoogle() async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: AppConfig.authRedirectURL)
            )
            print("🌐 Opened Google sign in...")
            // Note: The actual sign-in completion is handled by the auth state listener
            // when the app receives the callback URL
        } catch {
            authError = error.localizedDescription
            print("❌ Google sign in failed: \(error)")
            throw error
        }
    }
    
    /// Sign in with email and password
    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            await handleSessionChange(session)
            print("✅ Signed in with email")
        } catch {
            authError = error.localizedDescription
            print("❌ Email sign in failed: \(error)")
            throw error
        }
    }
    
    /// Sign up with email and password
    func signUpWithEmail(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            if let session = response.session {
                await handleSessionChange(session)
                print("✅ Signed up and logged in")
            } else {
                // Email confirmation required
                print("📧 Confirmation email sent")
            }
        } catch {
            authError = error.localizedDescription
            print("❌ Email sign up failed: \(error)")
            throw error
        }
    }
    
    /// Sign in with magic link (passwordless)
    func signInWithMagicLink(email: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: AppConfig.authRedirectURL)
            )
            print("📧 Magic link sent to \(email)")
        } catch {
            authError = error.localizedDescription
            print("❌ Magic link failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Handle OAuth Callback
    
    /// Call this when the app receives a deep link callback
    func handleOAuthCallback(url: URL) async {
        do {
            let session = try await supabase.auth.session(from: url)
            await handleSessionChange(session)
            print("✅ OAuth callback handled successfully")
        } catch {
            print("❌ Failed to handle OAuth callback: \(error)")
            authError = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            handleSignOut()
        } catch {
            print("❌ Sign out failed: \(error)")
            // Force local sign out anyway
            handleSignOut()
        }
    }
    
    // MARK: - Link Anonymous Data
    
    /// Links the anonymous device data to the authenticated user account
    private func linkAnonymousData(authId: UUID) async {
        let deviceId = deviceManager.deviceId
        
        do {
            try await database.linkToAuthAccount(deviceId: deviceId, authId: authId)
            print("✅ Anonymous data linked to auth account")
        } catch {
            print("⚠️ Failed to link anonymous data: \(error)")
            // Non-fatal - user can still use the app
        }
    }
    
    // MARK: - Subscription Management
    
    /// Check subscription status (call after Superwall purchase)
    func checkSubscriptionStatus() async {
        guard let userId = UserData.shared.supabaseUserId else { return }
        
        do {
            if let progress = try await database.fetchProgress(userId: userId) {
                subscriptionStatus = progress.subscriptionStatus ?? false
                subscriptionExpiry = progress.subscriptionExpiry
            }
        } catch {
            print("❌ Failed to check subscription: \(error)")
        }
    }
    
    /// Update subscription status (call from Superwall delegate)
    func updateSubscriptionStatus(isActive: Bool, expiry: Date? = nil) async {
        subscriptionStatus = isActive
        subscriptionExpiry = expiry
        
        // Also update UserData
        UserData.shared.subscriptionStatus = isActive
        
        // Sync to Supabase
        guard let userId = UserData.shared.supabaseUserId else { return }
        
        do {
            var progress = ProgressInput()
            progress.subscriptionStatus = isActive
            try await database.updateProgress(userId: userId, progress: progress)
            print("✅ Subscription status updated: \(isActive)")
        } catch {
            print("❌ Failed to update subscription status: \(error)")
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("📧 Password reset email sent")
        } catch {
            authError = error.localizedDescription
            print("❌ Password reset failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount() async throws {
        isLoading = true
        authError = nil
        
        defer { isLoading = false }
        
        // Clear local data
        UserData.shared.resetAllData()
        
        // Sign out
        await signOut()
        
        print("🗑️ Account deleted (local data cleared)")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case missingToken
    case invalidCredentials
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Failed to get authentication token"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please check your connection."
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Apple Sign In Coordinator

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?
    
    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: AuthError.invalidCredentials)
        }
        continuation = nil
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

// MARK: - Sign In With Apple Button (SwiftUI)

struct SignInWithAppleButton: View {
    let onSuccess: () -> Void
    let onError: (Error) -> Void
    
    @State private var coordinator = AppleSignInCoordinator()
    
    var body: some View {
        Button(action: performSignIn) {
            HStack(spacing: 12) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                Text("Continue with Apple")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
    
    private func performSignIn() {
        Task {
            do {
                let credential = try await coordinator.signIn()
                try await AuthManager.shared.signInWithApple(credential: credential)
                onSuccess()
            } catch {
                onError(error)
            }
        }
    }
}

// MARK: - Sign In With Google Button (SwiftUI)

struct SignInWithGoogleButton: View {
    let onSuccess: () -> Void
    let onError: (Error) -> Void
    
    var body: some View {
        Button(action: performSignIn) {
            HStack(spacing: 12) {
                // Google "G" logo - you can replace with actual Google logo image
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("Continue with Google")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(16)
        }
    }
    
    private func performSignIn() {
        Task {
            do {
                try await AuthManager.shared.signInWithGoogle()
                // Note: onSuccess will be called when the OAuth callback completes
                // The auth state listener handles this automatically
            } catch {
                onError(error)
            }
        }
    }
}

// MARK: - Email Auth View Model

@MainActor
class EmailAuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSignUp: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showConfirmationMessage: Bool = false
    
    private let authManager = AuthManager.shared
    
    var isValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    func submit() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                try await authManager.signUpWithEmail(email: email, password: password)
                showConfirmationMessage = true
            } else {
                try await authManager.signInWithEmail(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authManager.resetPassword(email: email)
            showConfirmationMessage = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
