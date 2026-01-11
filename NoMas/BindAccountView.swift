//
//  BindAccountView.swift
//  NoMas
//
//  Auth Screen #3: Required account binding after subscription.
//  Shown to users who skipped early auth and need to connect their account.
//

import SwiftUI

// MARK: - Bind Account View

/// Required authentication screen shown after subscription purchase.
/// NO skip button - auth is required to bind subscription to account.
/// After auth completes, marks onboarding as complete.

struct BindAccountView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingEmailSignUp = false
    
    var body: some View {
        ZStack {
            // Image background
            Image("bg7")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Dark overlay
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo at top
                Image("nomaslogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                    .padding(.vertical, 80)
                
                // Title
                Text("Bind Your Account")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                
                // Subtitle - directly under header
                Text("Connect your account to activate\nyour subscription and sync your progress.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 40)
                
                // Error message
                if let error = authManager.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
                
                // Auth buttons
                VStack(spacing: 16) {
                    // Google Sign In
                    AuthButton(
                        title: "Continue with Google",
                        icon: "g.circle.fill",
                        style: .google,
                        isLoading: authManager.isLoading,
                        action: {
                            Task {
                                do {
                                    try await AuthManager.shared.signInWithGoogle()
                                } catch {
                                    print("❌ Google Sign In error: \(error)")
                                }
                            }
                        }
                    )
                    
                    // Apple Sign In
                    SignInWithAppleButton(
                        onSuccess: {
                            if authManager.isAuthenticated {
                                handleAuthComplete()
                            }
                        },
                        onError: { error in
                            print("Apple Sign In error: \(error)")
                        }
                    )
                    
                    // Email Sign Up
                    AuthButton(
                        title: "Sign up with Email",
                        icon: "envelope.fill",
                        style: .accent,
                        isLoading: authManager.isLoading,
                        action: {
                            showingEmailSignUp = true
                        }
                    )
                }
                .padding(.horizontal, 48)
                .opacity(authManager.isLoading ? 0.6 : 1.0)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showingEmailSignUp) {
            EmailSignUpView(
                onComplete: {
                    showingEmailSignUp = false
                    if authManager.isAuthenticated {
                        handleAuthComplete()
                    }
                },
                onShowLogin: {
                    // Just dismiss - no login option on this screen
                    showingEmailSignUp = false
                }
            )
        }
        // Listen for auth state changes (for OAuth callbacks like Google)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                handleAuthComplete()
            }
        }
    }
    
    // MARK: - Auth Complete
    
    private func handleAuthComplete() {
        print("✅ Account bound successfully")
        
        // Clear the skipped flag
        userData.skippedEarlyAuth = false
        
        // Mark onboarding as complete - this triggers navigation to MainView
        onboardingState.completeOnboarding()
    }
}

// MARK: - Preview

#Preview {
    BindAccountView()
}
