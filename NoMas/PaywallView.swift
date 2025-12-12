//
//  PaywallView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI
import SuperwallKit

// MARK: - Paywall View

/// This view handles BOTH paywall AND conditional auth.
///
/// Flow:
/// 1. Show Superwall paywall
/// 2. If user purchases/restores → check if auth needed
/// 3. If skippedEarlyAuth == true → show forced auth
/// 4. Once both purchase AND auth (if needed) complete → advance to .complete
///
/// This is a hard paywall - user CANNOT proceed without paying.

struct PaywallView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var superwallManager = SuperwallManager.shared
    
    // MARK: - State Machine
    
    enum PaywallStep {
        case showingPaywall
        case showingForcedAuth
        case completing
    }
    
    @State private var currentStep: PaywallStep = .showingPaywall
    @State private var hasTriggeredPaywall = false
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
            switch currentStep {
            case .showingPaywall:
                PaywallLoadingView()
                
            case .showingForcedAuth:
                ForcedAuthView(onComplete: handleAuthComplete)
                
            case .completing:
                CompletingView()
            }
        }
        .onAppear {
            if !hasTriggeredPaywall {
                hasTriggeredPaywall = true
                triggerPaywall()
            }
        }
    }
    
    // MARK: - Paywall Logic
    
    private func triggerPaywall() {
        print("💰 Triggering paywall...")
        
        // Use SuperwallManager to show paywall
        superwallManager.triggerOnboardingPaywall { result in
            handlePaywallResult(purchased: result)
        }
    }
    
    private func handlePaywallResult(purchased: Bool) {
        // Debug logging - always show these values
        print("🔍 PaywallView checking auth state:")
        print("   skippedEarlyAuth: \(userData.skippedEarlyAuth)")
        print("   isAuthenticated: \(authManager.isAuthenticated)")
        print("   currentUserEmail: \(authManager.currentUserEmail ?? "nil")")
        
        let needsForcedAuth = userData.skippedEarlyAuth && !authManager.isAuthenticated
        print("   needsForcedAuth: \(needsForcedAuth)")
        
        if purchased {
            print("✅ User purchased/restored subscription")
            userData.hasActiveSubscription = true
            
            // Check if we need to force auth
            if needsForcedAuth {
                print("🔐 User skipped early auth - showing forced auth")
                withAnimation {
                    currentStep = .showingForcedAuth
                }
            } else {
                // Already authenticated or didn't skip - complete onboarding
                print("➡️ Skipping forced auth (already authenticated or didn't skip)")
                completeOnboarding()
            }
        } else {
            // User dismissed without purchasing
            // On a hard paywall, we should keep showing it
            // But for development, we'll allow progression with a debug flag
            #if DEBUG
            print("⚠️ DEBUG: Allowing progression without purchase")
            if needsForcedAuth {
                print("🔐 Showing forced auth (DEBUG mode)")
                withAnimation {
                    currentStep = .showingForcedAuth
                }
            } else {
                print("➡️ Skipping forced auth (DEBUG mode, already authenticated)")
                completeOnboarding()
            }
            #else
            // In production, re-show the paywall
            print("🚫 User dismissed paywall - re-showing")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                triggerPaywall()
            }
            #endif
        }
    }
    
    private func handleAuthComplete() {
        print("✅ Forced auth complete")
        userData.skippedEarlyAuth = false
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        withAnimation {
            currentStep = .completing
        }
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onboardingState.advance()
        }
    }
}

// MARK: - Paywall Loading View

private struct PaywallLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Preparing your plan...")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            Spacer()
        }
    }
}

// MARK: - Completing View

private struct CompletingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.accent)
            
            Text("You're all set!")
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Forced Auth View

/// Shown after paywall purchase if user skipped early auth.
/// NO skip button - auth is required to bind subscription to account.

private struct ForcedAuthView: View {
    let onComplete: () -> Void
    
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingEmailSignUp = false
    @State private var showingEmailLogin = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.accent)
            
            Spacer()
                .frame(minHeight: 24)
            
            // Title
            Text("Create Your Account")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Spacer()
                .frame(minHeight: 12)
            
            // Subtitle
            Text("Sign in to activate your subscription\nand sync across all your devices.")
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
                            onComplete()
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
            
            // Login link (no skip!)
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
        .fullScreenCover(isPresented: $showingEmailSignUp) {
            EmailSignUpView(
                onComplete: {
                    showingEmailSignUp = false
                    if authManager.isAuthenticated {
                        onComplete()
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
                        onComplete()
                    }
                },
                onShowSignUp: {
                    showingEmailLogin = false
                    showingEmailSignUp = true
                }
            )
        }
        // Listen for auth state changes (for OAuth callbacks)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                onComplete()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
