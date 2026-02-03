//
//  TrackingPermissionManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 2/3/26.
//


//
//  TrackingPermissionManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 2/3/26.
//

import Foundation
import AppTrackingTransparency
import Combine

@MainActor
final class TrackingPermissionManager: ObservableObject {
    static let shared = TrackingPermissionManager()

    @Published private(set) var attStatus: ATTrackingManager.AuthorizationStatus =
        ATTrackingManager.trackingAuthorizationStatus

    @Published private(set) var hasFinishedATTFlow: Bool = false

    private let hasRequestedATTKey = "hasRequestedATT"

    private init() {}

    var hasRequestedATTBefore: Bool {
        UserDefaults.standard.bool(forKey: hasRequestedATTKey)
    }

    /// Call this ONCE on app launch (SplashView is ideal)
    func requestATTIfNeeded() async {
        // Refresh current status (in case it changed)
        attStatus = ATTrackingManager.trackingAuthorizationStatus

        // If already determined, we’re done immediately
        if attStatus != .notDetermined {
            hasFinishedATTFlow = true
            print("✅ ATT already determined: \(attStatus.debugDescription)")
            return
        }

        // Prevent re-request spam
        if hasRequestedATTBefore {
            // Even if we requested before, Apple may still show notDetermined for a bit
            // but we don't want loops
            hasFinishedATTFlow = true
            print("⚠️ ATT was requested before but still notDetermined — skipping prompt")
            return
        }

        // Mark that we requested it (so we never loop prompts)
        UserDefaults.standard.set(true, forKey: hasRequestedATTKey)

        print("📲 Requesting ATT...")

        let status = await ATTrackingManager.requestTrackingAuthorization()
        attStatus = status
        hasFinishedATTFlow = true

        print("✅ ATT finished. Status = \(status.debugDescription)")
    }
}

// MARK: - Debug Helper

extension ATTrackingManager.AuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .restricted: return "restricted"
        case .notDetermined: return "notDetermined"
        @unknown default: return "unknown"
        }
    }
}
