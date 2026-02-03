//
//  TikTokSDKManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 2/3/26.
//

import Foundation
import Combine
import AppTrackingTransparency
import TikTokBusinessSDK

@MainActor
final class TikTokSDKManager: ObservableObject {
    static let shared = TikTokSDKManager()

    @Published private(set) var isInitialized: Bool = false
    private let didInitKey = "didInitializeTikTokSDK"

    private init() {}

    // MARK: - Initialization

    func attemptInitializeIfAllowed() {
        if isInitialized { return }

        if UserDefaults.standard.bool(forKey: didInitKey) {
            isInitialized = true
            return
        }

        let attStatus = TrackingPermissionManager.shared.attStatus
        let attDone = TrackingPermissionManager.shared.hasFinishedATTFlow

        guard attDone else {
            print("⏳ TikTok init blocked: ATT flow not finished yet")
            return
        }

        print("🚀 Initializing TikTok SDK (ATT = \(attStatus.debugDescription))")

        let config = TikTokConfig(
            accessToken: AppConfig.tikTokAccessToken,
            appId: AppConfig.tikTokAppId,
            tiktokAppId: AppConfig.tikTokTikTokAppId
        )

        // ✅ This is the exact signature from your screenshot
        TikTokBusiness.initializeSdk(config)

        isInitialized = true
        UserDefaults.standard.set(true, forKey: didInitKey)

        print("✅ TikTok SDK initialized")
    }

    // MARK: - Subscribe Event

    func logSubscribe(productId: String) {
        if !isInitialized {
            attemptInitializeIfAllowed()
        }

        guard isInitialized else {
            print("⚠️ TikTok Subscribe NOT fired — SDK not initialized yet")
            return
        }

        let amount = mapProductIdToAmount(productId)
        print("📈 TikTok Subscribe event fired: \(productId) ($\(amount))")

        let event = TikTokBaseEvent(eventName: "Subscribe")
        event.properties = [
            "currency": "USD",
            "value": amount,
            "content_id": productId
        ]

        print("🧾 TikTok state before Subscribe: initialized=\(isInitialized), ATT=\(TrackingPermissionManager.shared.attStatus.debugDescription)")

        TikTokBusiness.trackTTEvent(event)
        print("✅ TikTok Subscribe tracked successfully")
    }


    // MARK: - Product Mapping

    private func mapProductIdToAmount(_ productId: String) -> Double {
        switch productId {
        case "com.twitchapps.NoMasApp.monthly1499":
            return 14.99
        case "com.twitchapps.NoMasApp.yearly2999":
            return 29.99
        default:
            print("⚠️ Unknown product id: \(productId). Defaulting value to 0.")
            return 0
        }
    }
}
