//
//  NoMasApp.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import UserNotifications
import SuperwallKit

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

