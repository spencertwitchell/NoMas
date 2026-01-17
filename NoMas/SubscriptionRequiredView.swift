//
//  SubscriptionRequiredView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 1/10/26.
//


//
//  SubscriptionRequiredView.swift
//  NoMas
//
//  For returning users who are authenticated but don't have an active subscription.
//  Shows a message and button to trigger Superwall paywall.
//

import SwiftUI

// MARK: - Subscription Required View

/// Shown when a returning user is authenticated but has no active subscription.
/// User must subscribe to continue to the main app.

struct SubscriptionRequiredView: View {
    @StateObject private var userData = UserData.shared
    @StateObject private var superwallManager = SuperwallManager.shared
    
    @State private var isShowingPaywall = false
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(LinearGradient.accent)
                
                Spacer()
                    .frame(height: 32)
                
                // Title
                Text("Suscripción Requerida")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                    .frame(height: 16)
                
                // Message
                Text("Tu suscripción ha caducado o está inactiva.\nSuscríbete para continuar tu proceso de recuperación.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Features reminder
                VStack(alignment: .leading, spacing: 12) {
                    SubscriptionFeatureRow(icon: "flame.fill", text: "Sigue tu racha y tus logros")
                    SubscriptionFeatureRow(icon: "brain.head.profile", text: "Compañero de recuperación con IA")
                    SubscriptionFeatureRow(icon: "book.fill", text: "Acceso completo a recursos")
                    SubscriptionFeatureRow(icon: "person.3.fill", text: "Apoyo de la comunidad")
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Subscribe button
                Button(action: {
                    // Check for manual paywall bypass
                    if userData.manualPaywallBypass {
                        print("🔓 Manual paywall bypass enabled - granting access")
                        userData.hasActiveSubscription = true
                        // RootView will automatically route to MainView
                        return
                    }
                    
                    triggerPaywall()
                }) {
                    Text("Suscríbete Ahora")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 16)
                
                // Restore purchases link
                Button(action: {
                    restorePurchases()
                }) {
                    Text("Restaurar Compra")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .underline()
                }
                
                Spacer()
                    .frame(height: 40)
            }
        }
    }
    
    // MARK: - Paywall Logic
    
    private func triggerPaywall() {
        print("ðŸ’° Triggering subscription required paywall...")
        
        superwallManager.triggerSubscriptionRequiredPaywall { purchased in
            if purchased {
                print("âœ… User subscribed - updating state")
                userData.hasActiveSubscription = true
                // RootView will automatically route to MainView
            } else {
                print("âŒ User did not subscribe")
                // Stay on this screen
            }
        }
    }
    
    private func restorePurchases() {
        print("ðŸ”„ Restoring purchases...")
        
        Task {
            await superwallManager.checkSubscriptionStatus()
            if superwallManager.hasActiveSubscription {
                userData.hasActiveSubscription = true
                print("âœ… Purchases restored successfully")
            } else {
                print("âŒ No active subscription found")
            }
        }
    }
}

// MARK: - Subscription Feature Row

private struct SubscriptionFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(LinearGradient.accent)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionRequiredView()
}
