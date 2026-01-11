//
//  BindAccountView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 1/10/26.
//


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
    @State private var showingEmailLogin = false
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.accent)
                
                Spacer()
                    .frame(minHeight: 24)
                
                // Title
                Text("Bind Your Account")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                    .frame(minHeight: 12)
                
                // Subtitle
                Text("Connect your account to activate\nyour subscription and sync your progress.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                
                Spacer()
                
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
                .padding(.horizontal, 32)
                .opacity(authManager.isLoading ? 0.6 : 1.0)
                
                Spacer()
                    .frame(minHeight: 24)
                
                // Login link (no skip button!)
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Button(action: {
                        showingEmailLogin = true
                    }) {
                        Text("Login here")
                            .font(.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .underline()
                    }
                }
                
                Spacer()
                    .frame(minHeight: 40)
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
                    showingEmailSignUp = false
                    showingEmailLogin = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingEmailLogin) {
            EmailLoginView(
                onComplete: {
                    showingEmailLogin = false
                    if authManager.isAuthenticated {
                        handleAuthComplete()
                    }
                },
                onShowSignUp: {
                    showingEmailLogin = false
                    showingEmailSignUp = true
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