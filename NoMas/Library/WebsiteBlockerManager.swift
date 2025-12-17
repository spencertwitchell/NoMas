//
//  WebsiteBlockerManager.swift
//  NoMas
//
//  Manages website blocking using FamilyControls and ManagedSettings
//

import Foundation
import FamilyControls
import ManagedSettings
import Supabase
import Combine

@MainActor
class WebsiteBlockerManager: ObservableObject {
    static let shared = WebsiteBlockerManager()
    
    @Published var isAuthorized = false
    @Published var isBlockerEnabled = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var blockedDomainsCount = 0
    
    private let store = ManagedSettingsStore()
    private let authorizationCenter = AuthorizationCenter.shared
    
    private let isEnabledKey = "websiteBlockerEnabled"
    
    private init() {
        // Check current authorization status
        checkAuthorizationStatus()
        
        // Load saved state
        isBlockerEnabled = UserDefaults.standard.bool(forKey: isEnabledKey)
    }
    
    // MARK: - Authorization
    
    private func checkAuthorizationStatus() {
        switch authorizationCenter.authorizationStatus {
        case .approved:
            isAuthorized = true
        case .denied, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            isAuthorized = true
            return true
        } catch {
            print("❌ FamilyControls authorization failed: \(error)")
            errorMessage = "Authorization failed. Please try again."
            isAuthorized = false
            return false
        }
    }
    
    // MARK: - Enable/Disable Blocker
    
    func enableBlocker() async {
        isLoading = true
        errorMessage = nil
        
        // Request authorization if not already authorized
        if !isAuthorized {
            let authorized = await requestAuthorization()
            if !authorized {
                isLoading = false
                return
            }
        }
        
        // Fetch domains from Supabase
        let domains = await fetchBlockedDomains()
        
        // Apply blocked domains
        applyBlockedDomains(domains)
        
        // Save state
        isBlockerEnabled = true
        UserDefaults.standard.set(true, forKey: isEnabledKey)
        
        print("✅ Website blocker enabled with \(domains.count) blocked domains")
        
        isLoading = false
    }
    
    func disableBlocker() {
        isLoading = true
        
        // Clear all blocked domains
        store.webContent.blockedByFilter = nil
        
        // Save state
        isBlockerEnabled = false
        UserDefaults.standard.set(false, forKey: isEnabledKey)
        blockedDomainsCount = 0
        
        print("⏹ Website blocker disabled")
        
        isLoading = false
    }
    
    // MARK: - Fetch Domains from Supabase
    
    private func fetchBlockedDomains() async -> [BlockedDomain] {
        do {
            let domains: [BlockedDomain] = try await supabase
                .from("blocked_domains")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value
            
            print("📋 Fetched \(domains.count) blocked domains from Supabase")
            return domains
            
        } catch {
            print("⚠️ Failed to fetch blocked domains: \(error)")
            return []
        }
    }
    
    private func applyBlockedDomains(_ domains: [BlockedDomain]) {
        // Create a set of WebDomains
        var blockedDomains = Set<WebDomain>()
        
        for blockedDomain in domains {
            blockedDomains.insert(WebDomain(domain: blockedDomain.domain))
        }
        
        // Apply to the store using FilterPolicy
        store.webContent.blockedByFilter = .specific(blockedDomains)
        blockedDomainsCount = domains.count
    }
    
    // MARK: - Refresh Domains
    
    func refreshBlockedDomains() async {
        guard isBlockerEnabled else { return }
        
        let domains = await fetchBlockedDomains()
        applyBlockedDomains(domains)
        
        print("🔄 Refreshed blocked domains: \(domains.count)")
    }
}
