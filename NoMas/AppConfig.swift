//
//  AppConfig.swift
//  NoMas
//
//  Created by Spencer Twitchell on 2/3/26.
//

import Foundation

enum AppConfig {

    // MARK: - Supabase

    static let supabaseURL = "https://gxnnjgqmvynyllgyibhx.supabase.co"
    static let supabaseAnonKey = "sb_publishable_yPniFSk_JofE3J9RCA9W6Q_19F603ZA"
    static let authRedirectURL = "nomas://auth-callback"

    // MARK: - Superwall

    static let superwallAPIKey = "pk_Wmfb02wsL-JnAyyViD8-H"

    // MARK: - TikTok Events SDK

    /// TikTok "App ID" (shorter numeric)
    static let tikTokAppId = "6757657134"

    /// TikTok "TikTok App ID" (long numeric)
    static let tikTokTikTokAppId = "7602707129216303112"

    /// TikTok Access Token (required by TikTokConfig)
    static let tikTokAccessToken = "TTz1NbC881fR6yE10mcvqAVFovCeRiAz"
}
