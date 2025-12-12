//
//  SuperwallManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//


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
/// 1. Add SuperwallKit via SPM: https://github.com/superwall-me/Superwall-iOS
/// 2. Create account at superwall.com
/// 3. Get your API key from Settings â†’ Keys
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
        // TODO: Uncomment when SuperwallKit is added
        /*
        Superwall.configure(apiKey: AppConfig.superwallAPIKey)
        
        // Set the delegate to handle purchase events
        Superwall.shared.delegate = self
        
        // Set user attributes for targeting
        updateUserAttributes()
        
        isConfigured = true
        print("âœ… Superwall configured")
        */
        
        print("âš ï¸ Superwall SDK not yet integrated")
    }
    
    // MARK: - User Attributes
    
    /// Update user attributes for paywall targeting
    func updateUserAttributes() {
        let userData = UserData.shared
        
        // TODO: Uncomment when SuperwallKit is added
        /*
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
        */
    }
    
    /// Identify user after authentication
    func identifyUser(userId: String) {
        // TODO: Uncomment when SuperwallKit is added
        /*
        Superwall.shared.identify(userId: userId)
        updateUserAttributes()
        */
    }
    
    /// Reset user on sign out
    func resetUser() {
        // TODO: Uncomment when SuperwallKit is added
        /*
        Superwall.shared.reset()
        hasActiveSubscription = false
        */
    }
    
    // MARK: - Paywall Triggers
    
    /// Show paywall at a specific placement
    /// Placements are configured in the Superwall dashboard
    func triggerPaywall(placement: String, completion: ((Bool) -> Void)? = nil) {
        // TODO: Uncomment when SuperwallKit is added
        /*
        Superwall.shared.register(placement: placement) { result in
            switch result {
            case .purchased, .restored:
                self.hasActiveSubscription = true
                completion?(true)
            case .declined, .timeout:
                completion?(false)
            }
        }
        */
        
        // Temporary: Simulate paywall behavior for development
        // Shows a delay then returns true (simulating purchase)
        print("📱 Simulating paywall for placement: \(placement)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // For development, simulate a successful purchase
            self.hasActiveSubscription = true
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
        // TODO: Uncomment when SuperwallKit is added
        /*
        // Option 1: If using Superwall's built-in subscription status
        let status = await Superwall.shared.subscriptionStatus
        hasActiveSubscription = status == .active
        
        // Option 2: If using RevenueCat
        // let customerInfo = try? await Purchases.shared.customerInfo()
        // hasActiveSubscription = customerInfo?.entitlements["premium"]?.isActive ?? false
        */
        
        // Sync with AuthManager
        await AuthManager.shared.updateSubscriptionStatus(isActive: hasActiveSubscription)
    }
}

// MARK: - Superwall Delegate

/* TODO: Uncomment when SuperwallKit is added
extension SuperwallManager: SuperwallDelegate {
    
    // Called when a user completes a purchase
    func didCompletePurchase(for product: StoreProduct) {
        print("âœ… Purchase completed: \(product.productIdentifier)")
        
        Task {
            hasActiveSubscription = true
            await AuthManager.shared.updateSubscriptionStatus(isActive: true)
        }
    }
    
    // Called when a user restores purchases
    func didRestorePurchases() {
        print("âœ… Purchases restored")
        
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    // Called when a purchase fails
    func didFailToPurchase(for product: StoreProduct, with error: Error) {
        print("âŒ Purchase failed: \(error.localizedDescription)")
    }
    
    // Called when paywall is presented
    func willPresentPaywall(withInfo paywallInfo: PaywallInfo) {
        print("ðŸ“± Presenting paywall: \(paywallInfo.identifier)")
    }
    
    // Called when paywall is dismissed
    func willDismissPaywall(withInfo paywallInfo: PaywallInfo) {
        print("ðŸ“± Dismissing paywall: \(paywallInfo.identifier)")
    }
    
    // Called to check subscription status
    func subscriptionStatusDidChange(to status: SubscriptionStatus) {
        hasActiveSubscription = status == .active
        
        Task {
            await AuthManager.shared.updateSubscriptionStatus(isActive: hasActiveSubscription)
        }
    }
}
*/

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
            // Always advance regardless of purchase result
            // (user can still use the app with limited features)
            DispatchQueue.main.async {
                onboardingState.advance()
            }
        }
        
        // If Superwall isn't configured yet, just advance after a delay
        if !superwallManager.isConfigured {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onboardingState.advance()
            }
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
