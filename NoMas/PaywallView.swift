//
//  PaywallView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//


//
//  PaywallView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
// import SuperwallKit  // Uncomment when Superwall is integrated

// MARK: - Paywall View

/// This view triggers the Superwall paywall.
/// Superwall handles its own UI, so this is primarily a pass-through.
/// Once purchase is complete or dismissed, it advances to auth.

struct PaywallView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var authManager: AuthManager { AuthManager.shared }
    
    @State private var hasShownPaywall = false
    
    var body: some View {
        ZStack {
            // Background while paywall loads
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("Loading...")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                
                Spacer()
            }
        }
        .onAppear {
            if !hasShownPaywall {
                hasShownPaywall = true
                triggerPaywall()
            }
        }
    }
    
    private func triggerPaywall() {
        // TODO: Integrate Superwall
        // Superwall.shared.register(placement: "onboarding_paywall") { result in
        //     switch result.state {
        //     case .purchased, .restored:
        //         // User subscribed
        //         Task {
        //             await authManager.updateSubscriptionStatus(isActive: true)
        //         }
        //         onboardingState.advance()
        //     case .skipped:
        //         // User skipped/dismissed paywall
        //         onboardingState.advance()
        //     }
        // }
        
        // Temporary: Auto-advance after short delay (remove when Superwall is integrated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onboardingState.advance()
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}