//
//  NoMasApp.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import UserNotifications
// TODO: Uncomment when Superwall is added
// import SuperwallKit

@main
struct NoMasApp: App {
    
    // MARK: - App Delegate (for push notifications, deep links, etc.)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
                    setWindowBackgroundColor()
                }
                .onOpenURL { url in
                    // Handle OAuth callbacks (Google, Apple, Magic Link, etc.)
                    handleDeepLink(url)
                }
        }
    }
    
    // MARK: - Configuration
    
    private func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.backgroundGradientEnd)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setWindowBackgroundColor() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = UIColor(Color.backgroundGradientEnd)
            }
        }
    }
    
    private func configureSuperwall() {
        SuperwallManager.shared.configure()
    }
    
    // MARK: - Deep Links
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Received deep link: \(url)")
        
        // Handle Supabase auth callbacks (Google OAuth, Magic Links, etc.)
        if url.scheme == "nomas" {
            Task {
                await AuthManager.shared.handleOAuthCallback(url: url)
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return true
    }
    
    // Handle URL schemes (for OAuth)
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("🔗 AppDelegate received URL: \(url)")
        
        // Handle Supabase OAuth callback
        if url.scheme == "nomas" {
            Task {
                await AuthManager.shared.handleOAuthCallback(url: url)
            }
            return true
        }
        
        return false
    }
    
    // Push notifications
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 Push token: \(token)")
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for push notifications: \(error)")
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
