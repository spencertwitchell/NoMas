//
//  NoMasApp.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
// import SuperwallKit  // Uncomment when Superwall is integrated

@main
struct NoMasApp: App {
    
    // MARK: - App Delegate (for push notifications, deep links, etc.)
    // @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Init
    
    init() {
        configureAppearance()
        configureSuperwall()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    // Set window background color to prevent white flash during transitions
                    setWindowBackgroundColor()
                }
        }
    }
    
    // MARK: - Configuration
    
    private func configureAppearance() {
        // Configure navigation bar appearance globally
        // This prevents white flash during view transitions
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance (for future use)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.backgroundGradientEnd)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setWindowBackgroundColor() {
        // Set all windows' background color to dark to prevent white flash
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = UIColor(Color.backgroundGradientEnd)
            }
        }
    }
    
    private func configureSuperwall() {
        // TODO: Configure Superwall when ready
        // Superwall.configure(apiKey: AppConfig.superwallAPIKey)
        // Superwall.shared.delegate = SuperwallDelegateHandler()
    }
}

// MARK: - App Delegate (Optional)

/// Uncomment and implement if you need:
/// - Push notifications
/// - Deep link handling
/// - Background tasks
/// - Third-party SDK initialization

/*
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize third-party SDKs here
        return true
    }
    
    // Handle deep links
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        // Handle OAuth callbacks, deep links, etc.
        return true
    }
    
    // Handle push notification registration
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Send token to your server
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for push notifications: \(error)")
    }
}
*/

// MARK: - Superwall Delegate (Optional)

/// Uncomment when Superwall is integrated

/*
class SuperwallDelegateHandler: SuperwallDelegate {
    
    func handleSuperwallEvent(withInfo eventInfo: SuperwallEventInfo) {
        switch eventInfo.event {
        case .transactionComplete:
            // User completed purchase
            Task {
                await AuthManager.shared.updateSubscriptionStatus(isActive: true)
            }
            print("✅ Superwall: Transaction complete")
            
        case .subscriptionStatusDidChange:
            // Subscription status changed
            Task {
                await AuthManager.shared.checkSubscriptionStatus()
            }
            print("🔄 Superwall: Subscription status changed")
            
        case .paywallClose:
            print("👋 Superwall: Paywall closed")
            
        default:
            break
        }
    }
}
*/
