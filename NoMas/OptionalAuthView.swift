//
//  OptionalAuthView.swift
//  NoMas
//
//  Created by Claude on 12/11/25.
//

import SwiftUI

// MARK: - Optional Auth View

/// Early authentication screen shown before the quiz.
/// Users can sign in OR skip (and will be forced to auth after paywall).

struct OptionalAuthView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingEmailSignUp = false
    @State private var showingEmailLogin = false
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                Image("nomaslogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                
                Spacer()
                    .frame(minHeight: 24)
                
                // Title
                Text("Save Your Progress")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                    .frame(minHeight: 12)
                
                // Subtitle
                Text("Sign in to sync your data across devices\nand never lose your progress.")
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
                            handleAuthSuccess()
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
                
                // Skip button
                Button(action: handleSkip) {
                    Text("Skip for now")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .underline()
                }
                .disabled(authManager.isLoading)
                
                Spacer()
                    .frame(minHeight: 16)
                
                // Login link
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
                    handleAuthSuccess()
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
                    handleAuthSuccess()
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
                handleAuthSuccess()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleSkip() {
        // Mark that user skipped early auth
        userData.skippedEarlyAuth = true
        print("⏭️ User skipped early auth - skippedEarlyAuth set to: \(userData.skippedEarlyAuth)")
        onboardingState.advance()
    }
    
    private func handleAuthSuccess() {
        // User authenticated early - clear the skip flag
        userData.skippedEarlyAuth = false
        print("✅ User authenticated early - skippedEarlyAuth set to: \(userData.skippedEarlyAuth)")
        print("   isAuthenticated: \(authManager.isAuthenticated)")
        print("   email: \(authManager.currentUserEmail ?? "nil")")
        onboardingState.advance()
    }
}

// MARK: - Preview

#Preview {
    OptionalAuthView()
}
