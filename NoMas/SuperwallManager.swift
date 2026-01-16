//
//  SuperwallManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import Foundation
import SwiftUI
import SuperwallKit
import Combine

// MARK: - Superwall Manager

/// Manages Superwall paywall integration
///
/// Setup steps:
/// 1. Add SuperwallKit via SPM: https://github.com/superwall/Superwall-iOS
/// 2. Create account at superwall.com
/// 3. Get your API key from Settings → Keys
/// 4. Update AppConfig.superwallAPIKey
/// 5. Create paywalls in the Superwall dashboard
/// 6. Configure placements (triggers) in the dashboard

@MainActor
class SuperwallManager: ObservableObject {
    static let shared = SuperwallManager()
    
    @Published private(set) var isConfigured: Bool = false
    @Published private(set) var hasActiveSubscription: Bool = false
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Call this in NoMasApp.init()
    func configure() {
        Superwall.configure(apiKey: AppConfig.superwallAPIKey)
        
        // Set the delegate to handle purchase events
        Superwall.shared.delegate = self
        
        // Set user attributes for targeting
        updateUserAttributes()
        
        // Check initial subscription status
        updateSubscriptionFromSuperwall()
        
        isConfigured = true
        print("✅ Superwall configured")
    }
    
    // MARK: - User Attributes
    
    /// Update user attributes for paywall targeting
    func updateUserAttributes() {
        let userData = UserData.shared
        
        var attributes: [String: Any] = [
            "device_id": userData.deviceId,
            "days_since_relapse": userData.daysSinceRelapse,
            "dependency_score": userData.dependencyScore,
            "current_milestone": userData.currentMilestone.rawValue,
            "has_completed_onboarding": userData.hasCompletedOnboarding
        ]
        
        if let gender = userData.gender {
            attributes["gender"] = gender.rawValue
        }
        
        if let age = userData.age {
            attributes["age"] = age
        }
        
        Superwall.shared.setUserAttributes(attributes)
    }
    
    /// Identify user after authentication
    func identifyUser(userId: String) {
        Superwall.shared.identify(userId: userId)
        updateUserAttributes()
    }
    
    /// Reset user on sign out
    func resetUser() {
        Superwall.shared.reset()
        hasActiveSubscription = false
    }
    
    // MARK: - Paywall Triggers
    
    /// Show paywall at a specific placement
    /// Placements are configured in the Superwall dashboard
    func triggerPaywall(placement: String, completion: ((Bool) -> Void)? = nil) {
        print("📱 Triggering paywall for placement: \(placement)")
        
        let handler = PaywallPresentationHandler()
        
        handler.onPresent { paywallInfo in
            print("📱 Paywall presented: \(paywallInfo.identifier)")
        }
        
        handler.onDismiss { paywallInfo, result in
            print("📱 Paywall dismissed: \(paywallInfo.identifier), result: \(result)")
            // Note: If purchased/restored, the feature block handles the completion
            // This is called for all dismiss cases including declined
            if case .declined = result {
                completion?(false)
            }
        }
        
        handler.onSkip { reason in
            print("⏭️ Paywall skipped: \(reason)")
            
            switch reason {
            case .holdout, .noAudienceMatch, .placementNotFound:
                // Paywall was skipped for non-subscription reasons
                completion?(false)
            @unknown default:
                completion?(false)
            }
        }
        
        handler.onError { error in
            print("❌ Paywall error: \(error.localizedDescription)")
            completion?(false)
        }
        
        // Register with feature block - this runs when user has access
        // (either already subscribed, or just purchased)
        Superwall.shared.register(placement: placement, handler: handler) {
            // Feature block - called when user should get access
            print("✅ User has access - feature block executed")
            self.hasActiveSubscription = true
            UserData.shared.hasActiveSubscription = true
            completion?(true)
        }
    }
    
    /// Trigger the onboarding paywall (after completing onboarding content)
    /// This is a HARD paywall - user must subscribe to continue
    func triggerOnboardingPaywall(completion: ((Bool) -> Void)? = nil) {
        triggerPaywall(placement: "onboarding_complete", completion: completion)
    }
    
    /// Common placement triggers
    func triggerOnboardingCompletePaywall(completion: ((Bool) -> Void)? = nil) {
        triggerPaywall(placement: "onboarding_complete", completion: completion)
    }
    
    func triggerSubscriptionRequiredPaywall(completion: ((Bool) -> Void)? = nil) {
        triggerPaywall(placement: "subscription_required", completion: completion)
    }
    
    func triggerFeatureLockedPaywall(feature: String, completion: ((Bool) -> Void)? = nil) {
        triggerPaywall(placement: "feature_\(feature)", completion: completion)
    }
    
    // MARK: - Subscription Check
    
    /// Check if user has active subscription
    /// This should be called on app launch and after purchases
    func checkSubscriptionStatus() async {
        updateSubscriptionFromSuperwall()
        
        // Sync with AuthManager
        await AuthManager.shared.updateSubscriptionStatus(isActive: hasActiveSubscription)
    }
    
    /// Update local subscription state from Superwall
    private func updateSubscriptionFromSuperwall() {
        // Superwall tracks subscription status automatically
        let isActive = Superwall.shared.subscriptionStatus.isActive
        hasActiveSubscription = isActive
        UserData.shared.hasActiveSubscription = isActive
    }
}

// MARK: - Superwall Delegate

extension SuperwallManager: SuperwallDelegate {
    
    nonisolated func subscriptionStatusDidChange(to newValue: SubscriptionStatus) {
        Task { @MainActor in
            let isActive = newValue.isActive
            self.hasActiveSubscription = isActive
            UserData.shared.hasActiveSubscription = isActive
            
            await AuthManager.shared.updateSubscriptionStatus(isActive: isActive)
            print("🔄 Subscription status changed: \(newValue), isActive: \(isActive)")
        }
    }
    
    nonisolated func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        // Log events for debugging
        print("📊 Superwall event: \(eventInfo.event)")
    }
}

// MARK: - PaywallView Integration

/// Updated PaywallView that uses SuperwallManager
struct SuperwallPaywallView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var superwallManager: SuperwallManager { SuperwallManager.shared }
    
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            AppBackground()
            
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Loading...")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .onAppear {
            triggerPaywall()
        }
    }
    
    private func triggerPaywall() {
        superwallManager.triggerOnboardingCompletePaywall { purchased in
            if purchased {
                DispatchQueue.main.async {
                    onboardingState.advance()
                }
            }
            // If not purchased, paywall stays - user must subscribe (hard paywall)
        }
    }
}

// MARK: - Subscription Gate Modifier

/// Use this modifier to gate premium features
struct SubscriptionGateModifier: ViewModifier {
    let feature: String
    @ObservedObject var superwallManager = SuperwallManager.shared
    @ObservedObject var authManager = AuthManager.shared
    
    func body(content: Content) -> some View {
        if authManager.effectiveSubscriptionStatus {
            content
        } else {
            Button(action: showPaywall) {
                content
                    .overlay(
                        ZStack {
                            Color.black.opacity(0.5)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title)
                                Text("Premium Feature")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                    )
            }
        }
    }
    
    private func showPaywall() {
        superwallManager.triggerFeatureLockedPaywall(feature: feature)
    }
}

extension View {
    /// Gate a view behind subscription
    /// Usage: someView.subscriptionGated(feature: "journal")
    func subscriptionGated(feature: String) -> some View {
        modifier(SubscriptionGateModifier(feature: feature))
    }
}
