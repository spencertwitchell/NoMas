//
//  RootView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI

// MARK: - Root View (Main App Router)

/// The root view that determines what to show based on app state:
///
/// ROUTING LOGIC:
/// 1. Show splash first (always)
/// 2. If !hasCompletedOnboarding → Onboarding flow
/// 3. If hasCompletedOnboarding but !hasActiveSubscription → Paywall (subscription_required)
/// 4. If hasCompletedOnboarding and hasActiveSubscription → Main app
///
/// This ensures:
/// - New users complete full onboarding
/// - Returning users who abandoned at paywall see paywall immediately
/// - Expired subscriptions get sent back to paywall
/// - Active subscribers go straight to main app

struct RootView: View {
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var onboardingState = OnboardingState.shared
    @StateObject private var superwallManager = SuperwallManager.shared
    
    @State private var splashComplete = false
    @State private var isVerifyingSubscription = false
    
    // Debug flag - set to true to skip onboarding during development
    private let skipOnboarding = false
    
    var body: some View {
        ZStack {
            // PERSISTENT BACKGROUND - prevents white flash during transitions
            AppBackground()
            
            // Determine what to show
            if skipOnboarding {
                // Development mode - skip straight to main app
                MainAppPlaceholder()
                    .onAppear { setupTestData() }
            } else if !splashComplete {
                // Step 1: Always show splash first
                SplashView(isComplete: $splashComplete)
                    .transition(.opacity)
            } else if isVerifyingSubscription {
                // Verifying subscription status
                LoadingView(message: "Checking subscription...")
                    .transition(.opacity)
            } else {
                // Step 2: Route based on state
                routedView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: splashComplete)
        .animation(.easeInOut(duration: 0.35), value: userData.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: userData.hasActiveSubscription)
        .animation(.easeInOut(duration: 0.35), value: authManager.isAuthenticated)
        .onChange(of: splashComplete) { _, complete in
            if complete {
                verifySubscriptionStatus()
            }
        }
    }
    
    // MARK: - Routing Logic
    
    @ViewBuilder
    private var routedView: some View {
        // Debug logging
        let _ = debugPrintState()
        
        if !userData.hasCompletedOnboarding {
            // NEW USER: Show full onboarding flow
            // OnboardingFlowView handles: welcome → optionalAuth → quiz → ... → paywall → complete
            OnboardingFlowView()
        } else if !userData.hasActiveSubscription {
            // RETURNING USER WITHOUT SUBSCRIPTION:
            // Either abandoned at paywall, subscription expired, or was on free trial that ended
            ReturningUserPaywallView()
        } else if !authManager.isAuthenticated {
            // HAS SUBSCRIPTION BUT NOT AUTHENTICATED:
            // This shouldn't happen in normal flow, but handle it
            // (e.g., logged out, reinstalled, new device)
            ReturningUserAuthView()
        } else {
            // HAPPY PATH: Completed onboarding, has subscription, is authenticated
            MainAppPlaceholder()
        }
    }
    
    // MARK: - Subscription Verification
    
    private func verifySubscriptionStatus() {
        // Only verify if user has completed onboarding
        guard userData.hasCompletedOnboarding else { return }
        
        isVerifyingSubscription = true
        
        Task {
            // Check subscription status with Superwall/StoreKit
            await superwallManager.checkSubscriptionStatus()
            
            // Sync the result
            userData.hasActiveSubscription = superwallManager.hasActiveSubscription
            
            await MainActor.run {
                isVerifyingSubscription = false
            }
            
            print("✅ Subscription verified: \(userData.hasActiveSubscription)")
        }
    }
    
    // MARK: - Helpers
    
    private func debugPrintState() {
        #if DEBUG
        print("🔍 RootView State:")
        print("   splashComplete: \(splashComplete)")
        print("   hasCompletedOnboarding: \(userData.hasCompletedOnboarding)")
        print("   hasActiveSubscription: \(userData.hasActiveSubscription)")
        print("   isAuthenticated: \(authManager.isAuthenticated)")
        print("   skippedEarlyAuth: \(userData.skippedEarlyAuth)")
        #endif
    }
    
    private func setupTestData() {
        #if DEBUG
        if userData.displayName.isEmpty {
            userData.hasCompletedOnboarding = true
            userData.hasActiveSubscription = true
            userData.displayName = "Test User"
            userData.lastRelapseDate = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
            userData.dependencyScore = 72.0
            userData.appJoinDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            userData.streakStartDate = userData.lastRelapseDate
            userData.calculateProjectedRecoveryDate()
        }
        #endif
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var message: String = "Loading your data..."
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Returning User Paywall View

/// Shown when a user has completed onboarding but doesn't have an active subscription.
/// This handles: abandoned at paywall, expired subscription, ended free trial

struct ReturningUserPaywallView: View {
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var superwallManager = SuperwallManager.shared
    
    @State private var hasTriggeredPaywall = false
    @State private var showingAuth = false
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            if showingAuth {
                // Need to authenticate to restore purchases
                ReturningAuthContent(onComplete: {
                    showingAuth = false
                    // After auth, check subscription again
                    triggerPaywall()
                })
            } else {
                // Show welcome back + paywall
                WelcomeBackPaywallContent(
                    onRestoreTapped: {
                        // Need to authenticate first to restore
                        if !authManager.isAuthenticated {
                            showingAuth = true
                        } else {
                            restorePurchases()
                        }
                    }
                )
            }
        }
        .onAppear {
            if !hasTriggeredPaywall {
                hasTriggeredPaywall = true
                // Small delay to show the welcome back screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    triggerPaywall()
                }
            }
        }
    }
    
    private func triggerPaywall() {
        superwallManager.triggerSubscriptionRequiredPaywall { purchased in
            if purchased {
                userData.hasActiveSubscription = true
                // View will automatically update via published property
            }
            // If not purchased, they stay on this screen (hard paywall)
        }
    }
    
    private func restorePurchases() {
        Task {
            await superwallManager.checkSubscriptionStatus()
            userData.hasActiveSubscription = superwallManager.hasActiveSubscription
        }
    }
}

// MARK: - Welcome Back Paywall Content

private struct WelcomeBackPaywallContent: View {
    let onRestoreTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo
            Image("nomaslogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
            
            Spacer()
                .frame(height: 32)
            
            // Welcome back message
            Text("Welcome Back")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
            
            Spacer()
                .frame(height: 12)
            
            Text("Your subscription has expired.\nSubscribe to continue your journey.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
            
            // Restore purchases link
            Button(action: onRestoreTapped) {
                Text("Restore Purchases")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .underline()
            }
            
            Spacer()
                .frame(height: 40)
        }
    }
}

// MARK: - Returning Auth Content

private struct ReturningAuthContent: View {
    let onComplete: () -> Void
    
    @StateObject private var authManager = AuthManager.shared
    @State private var showingEmailSignUp = false
    @State private var showingEmailLogin = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Title
            Text("Sign In to Restore")
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
            
            Spacer()
                .frame(height: 12)
            
            Text("Sign in to restore your purchases\nfrom a previous account.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Spacer()
            
            // Auth buttons
            VStack(spacing: 16) {
                AuthButton(
                    title: "Continue with Google",
                    icon: "g.circle.fill",
                    style: .google,
                    isLoading: authManager.isLoading,
                    action: {
                        Task {
                            try? await AuthManager.shared.signInWithGoogle()
                        }
                    }
                )
                
                SignInWithAppleButton(
                    onSuccess: { onComplete() },
                    onError: { _ in }
                )
                
                AuthButton(
                    title: "Sign in with Email",
                    icon: "envelope.fill",
                    style: .accent,
                    isLoading: authManager.isLoading,
                    action: { showingEmailLogin = true }
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 24)
            
            // Cancel
            Button(action: onComplete) {
                Text("Cancel")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
                .frame(height: 40)
        }
        .fullScreenCover(isPresented: $showingEmailLogin) {
            EmailLoginView(
                onComplete: {
                    showingEmailLogin = false
                    onComplete()
                },
                onShowSignUp: {
                    showingEmailLogin = false
                    showingEmailSignUp = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingEmailSignUp) {
            EmailSignUpView(
                onComplete: {
                    showingEmailSignUp = false
                    onComplete()
                },
                onShowLogin: {
                    showingEmailSignUp = false
                    showingEmailLogin = true
                }
            )
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuth in
            if isAuth { onComplete() }
        }
    }
}

// MARK: - Returning User Auth View

/// Shown when a user has completed onboarding but is not authenticated
/// (e.g., logged out, reinstalled app, or using new device)

struct ReturningUserAuthView: View {
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingAuth = false
    
    var body: some View {
        ZStack {
            if !showingAuth {
                // Welcome back screen
                WelcomeBackView(onContinue: {
                    withAnimation {
                        showingAuth = true
                    }
                })
            } else {
                // Auth screen
                AuthView()
            }
        }
    }
}

// MARK: - Welcome Back View

struct WelcomeBackView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
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
                    .frame(height: 32)
                
                // Welcome back message
                Text("Welcome Back")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                    .frame(height: 12)
                
                Text("Sign in to continue your\nrecovery journey")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Main App Placeholder

/// Placeholder for the main app view
/// Replace this with your actual MainView when built

struct MainAppPlaceholder: View {
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var onboardingState = OnboardingState.shared
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Streak display
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60))
                        .foregroundColor(userData.currentMilestone.color)
                    
                    Text("\(userData.daysSinceRelapse)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.textPrimary)
                    
                    Text(userData.daysSinceRelapse == 1 ? "Day Clean" : "Days Clean")
                        .font(.titleMedium)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Current milestone
                VStack(spacing: 8) {
                    Text(userData.currentMilestone.title)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                    
                    Text(userData.currentMilestone.description)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Debug info
                #if DEBUG
                VStack(spacing: 8) {
                    Text("Main App Placeholder")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                    
                    // Debug state info
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auth: \(authManager.isAuthenticated ? "✅" : "❌") \(authManager.currentUserEmail ?? "not signed in")")
                        Text("Subscription: \(userData.hasActiveSubscription ? "✅" : "❌")")
                        Text("Completed Onboarding: \(userData.hasCompletedOnboarding ? "✅" : "❌")")
                        Text("Skipped Early Auth: \(userData.skippedEarlyAuth ? "✅" : "❌")")
                        Text("Device ID: \(String(userData.deviceId.prefix(8)))...")
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.textTertiary)
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                
                // Debug buttons
                VStack(spacing: 8) {
                    // Reset onboarding button (keeps auth)
                    Button(action: {
                        onboardingState.resetOnboarding()
                    }) {
                        Text("Reset Onboarding Only")
                            .font(.caption)
                            .foregroundColor(.orange.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                    }
                    
                    // Full reset button (clears everything including auth & keychain)
                    Button(action: {
                        Task {
                            await userData.nukeEverything()
                        }
                    }) {
                        Text("☢️ Nuke Everything (Fresh Install)")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
                #endif
                
                Spacer()
                    .frame(height: 40)
            }
        }
    }
}

// MARK: - Preview

#Preview("Root View") {
    RootView()
}

#Preview("Welcome Back") {
    WelcomeBackView(onContinue: {})
}

#Preview("Main App Placeholder") {
    MainAppPlaceholder()
}
