//
//  RootView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI

// MARK: - Root View (Main App Router)

/// The root view that determines what to show based on app state:
/// - Splash screen (loading)
/// - Onboarding flow (new users)
/// - Main app (returning users)

struct RootView: View {
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var onboardingState = OnboardingState.shared
    
    @State private var splashComplete = false
    @State private var isLoadingUserData = false
    
    // Debug flag - set to true to skip onboarding during development
    private let skipOnboarding = false
    
    var body: some View {
        ZStack {
            // PERSISTENT BACKGROUND - prevents white flash during transitions
            // This stays visible while child views animate in/out
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
            } else if isLoadingUserData {
                // Loading state after OAuth redirect
                LoadingView()
                    .transition(.opacity)
            } else {
                // Step 2: Route based on state
                routedView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: splashComplete)
        .animation(.easeInOut(duration: 0.35), value: userData.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: authManager.isAuthenticated)
    }
    
    // MARK: - Routing Logic
    
    @ViewBuilder
    private var routedView: some View {
        // Debug logging
        let _ = debugPrintState()
        
        if userData.hasCompletedOnboarding {
            // User has completed onboarding before
            if authManager.isAuthenticated {
                // Authenticated - go to main app
                // (Superwall will handle paywall if no subscription)
                MainAppPlaceholder()
                    .onAppear { checkSubscriptionAndShowPaywall() }
            } else {
                // Not authenticated but completed onboarding
                // This happens if user logged out or reinstalled
                // Show auth flow then go to main app
                ReturningUserAuthView()
            }
        } else {
            // New user - show full onboarding flow
            // OnboardingFlowView handles ALL onboarding phases internally
            OnboardingFlowView()
        }
    }
    
    // MARK: - Helpers
    
    private func debugPrintState() {
        #if DEBUG
        print("🔍 RootView State:")
        print("   splashComplete: \(splashComplete)")
        print("   hasCompletedOnboarding: \(userData.hasCompletedOnboarding)")
        print("   isAuthenticated: \(authManager.isAuthenticated)")
        print("   effectiveSubscriptionStatus: \(authManager.effectiveSubscriptionStatus)")
        #endif
    }
    
    private func checkSubscriptionAndShowPaywall() {
        // Check subscription and show paywall if needed
        if !authManager.effectiveSubscriptionStatus {
            print("🚫 No subscription - triggering paywall")
            // TODO: Superwall.shared.register(placement: "subscription_required")
        }
    }
    
    private func setupTestData() {
        #if DEBUG
        if userData.displayName.isEmpty {
            userData.hasCompletedOnboarding = true
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
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading your data...")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
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
                VStack(spacing: 4) {
                    Text("Main App Placeholder")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                    
                    Text("Build your MainView here")
                        .font(.captionSmall)
                        .foregroundColor(.textTertiary)
                }
                
                // Reset onboarding button (debug only)
                Button(action: {
                    onboardingState.resetOnboarding()
                }) {
                    Text("Reset Onboarding (Debug)")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
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
