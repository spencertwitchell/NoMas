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
/// ROUTING LOGIC (in order):
/// 1. Show splash first (always)
/// 2. If !hasCompletedOnboarding → Onboarding flow (includes paywall)
/// 3. If !isAuthenticated → Returning user login (Auth Screen #2)
/// 4. If !hasActiveSubscription → Subscription required screen
/// 5. All conditions met → Main app
///
/// This ensures:
/// - New users complete full onboarding (with paywall)
/// - Returning users must be authenticated first
/// - Authenticated users without subscription see paywall
/// - Active subscribers go straight to main app

struct RootView: View {
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var onboardingState = OnboardingState.shared
    
    @State private var splashComplete = false
    @State private var contentReady = false
    
    // Debug flag - set to true to skip onboarding during development
    private let skipOnboarding = false
    
    var body: some View {
        ZStack {
            // PERSISTENT BACKGROUND - prevents white flash during transitions
            AppBackground()
            
            // Determine what to show
            if skipOnboarding {
                // Development mode - skip straight to main app
                MainView(splashComplete: .constant(true))
                    .onAppear { setupTestData() }
            } else {
                // Main content only renders once data is loaded (contentReady)
                // This prevents flash of wrong screen before splash appears
                if contentReady {
                    routedView
                        .transition(.opacity)
                }
                
                // Splash overlays on top and fades out
                if !splashComplete {
                    SplashView(isComplete: $splashComplete, contentReady: $contentReady)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: userData.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: userData.hasActiveSubscription)
        .animation(.easeInOut(duration: 0.35), value: authManager.isAuthenticated)
    }
    
    // MARK: - Routing Logic
    
    @ViewBuilder
    private var routedView: some View {
        // Debug logging
        let _ = debugPrintState()
        
        if !userData.hasCompletedOnboarding {
            // NEW USER: Show full onboarding flow
            // OnboardingFlowView handles: welcome → optionalAuth → quiz → ... → paywall → complete → bindAuth
            OnboardingFlowView()
        } else if !authManager.isAuthenticated {
            // RETURNING USER - NOT AUTHENTICATED:
            // Must sign in first (could be logged out, reinstalled, new device)
            ReturningUserLoginView()
        } else if !userData.hasActiveSubscription {
            // RETURNING USER - AUTHENTICATED BUT NO SUBSCRIPTION:
            // Subscription expired, cancelled, or never completed
            SubscriptionRequiredView()
        } else {
            // HAPPY PATH: Completed onboarding, authenticated, has subscription
            MainView(splashComplete: $splashComplete)
        }
    }
    
    // MARK: - Helpers
    
    private func debugPrintState() {
        #if DEBUG
        print("🧭 RootView State:")
        print("   splashComplete: \(splashComplete)")
        print("   hasCompletedOnboarding: \(userData.hasCompletedOnboarding)")
        print("   isAuthenticated: \(authManager.isAuthenticated)")
        print("   hasActiveSubscription: \(userData.hasActiveSubscription)")
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

// MARK: - Preview

#Preview("Root View") {
    RootView()
}
