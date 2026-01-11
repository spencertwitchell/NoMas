//
//  PaywallView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI
import SuperwallKit

// MARK: - Paywall View

/// This view handles ONLY the paywall display.
/// After purchase, it advances to .complete phase.
/// Auth is handled separately in BindAccountView.

struct PaywallView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    @StateObject private var superwallManager = SuperwallManager.shared
    
    @State private var hasTriggeredPaywall = false
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
            // Loading state while paywall displays
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
        if purchased {
            print("✅ User purchased/restored subscription")
            userData.hasActiveSubscription = true
            
            // Advance to complete screen
            onboardingState.advance()
        } else {
            // User dismissed without purchasing
            #if DEBUG
            // In debug mode, allow progression without purchase for testing
            print("⚠️ DEBUG: Allowing progression without purchase")
            onboardingState.advance()
            #else
            // In production, re-show the paywall (hard paywall)
            print("🚫 User dismissed paywall - re-showing")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                triggerPaywall()
            }
            #endif
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
