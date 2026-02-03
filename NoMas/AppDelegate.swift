//
//  AppDelegate.swift
//  NoMas
//
//  Created by Spencer Twitchell on 2/3/26.
//


//
//  AppDelegate.swift
//  NoMas
//
//  Created by Spencer Twitchell on 2/3/26.
//

import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // Do NOT init TikTok here.
        // TikTok must init only AFTER ATT result is known.
        print("✅ AppDelegate didFinishLaunching")
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Safe: sometimes app becomes active after ATT prompt.
        // We'll attempt init here too as a backup.
        TikTokSDKManager.shared.attemptInitializeIfAllowed()
    }
}
