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
        checkAuthorizationStatus()

        isBlockerEnabled = UserDefaults.standard.bool(forKey: isEnabledKey)

        if isBlockerEnabled {
            Task {
                await refreshBlockedDomains()
            }
        }
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
            errorMessage = "La autorización falló. Por favor, inténtalo de nuevo."
            isAuthorized = false
            return false
        }
    }

    // MARK: - Enable/Disable Blocker

    func enableBlocker() async {
        isLoading = true
        errorMessage = nil

        if !isAuthorized {
            let authorized = await requestAuthorization()
            if !authorized {
                isLoading = false
                return
            }
        }

        let domains = await fetchBlockedDomains()

        if domains.isEmpty {
            errorMessage = "No se encontraron sitios para bloquear. Inténtalo de nuevo."
            store.webContent.blockedByFilter = nil
            blockedDomainsCount = 0
            isBlockerEnabled = false
            UserDefaults.standard.set(false, forKey: isEnabledKey)
            isLoading = false
            return
        }

        applyBlockedDomains(domains)

        isBlockerEnabled = true
        UserDefaults.standard.set(true, forKey: isEnabledKey)

        print("✅ Website blocker enabled with \(domains.count) blocked domains")

        isLoading = false
    }

    func disableBlocker() {
        isLoading = true
        errorMessage = nil

        store.webContent.blockedByFilter = nil

        isBlockerEnabled = false
        UserDefaults.standard.set(false, forKey: isEnabledKey)
        blockedDomainsCount = 0

        print("⏹ Website blocker disabled")

        isLoading = false
    }

    // MARK: - Fetch Domains

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

    // MARK: - Domain Sanitization

    private func sanitizeDomain(_ input: String) -> String {
        var domain = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip protocol
        domain = domain.replacingOccurrences(of: "https://", with: "")
        domain = domain.replacingOccurrences(of: "http://", with: "")

        // Strip path/query/fragment
        if let slashIndex = domain.firstIndex(of: "/") {
            domain = String(domain[..<slashIndex])
        }
        if let questionIndex = domain.firstIndex(of: "?") {
            domain = String(domain[..<questionIndex])
        }
        if let hashIndex = domain.firstIndex(of: "#") {
            domain = String(domain[..<hashIndex])
        }

        // Strip trailing dots
        domain = domain.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        return domain
    }

    private func expandDomains(_ domain: String) -> [String] {
        // Always block both root + www variant
        if domain.hasPrefix("www.") {
            let root = String(domain.dropFirst(4))
            return [root, domain]
        } else {
            return [domain, "www.\(domain)"]
        }
    }

    // MARK: - Apply Blocker

    private func applyBlockedDomains(_ domains: [BlockedDomain]) {
        var blocked = Set<WebDomain>()

        for item in domains {
            let sanitized = sanitizeDomain(item.domain)

            guard !sanitized.isEmpty else { continue }

            for expanded in expandDomains(sanitized) {
                blocked.insert(WebDomain(domain: expanded))
            }
        }

        if blocked.isEmpty {
            print("⚠️ No valid domains after sanitization")
            store.webContent.blockedByFilter = nil
            blockedDomainsCount = 0
            return
        }

        store.webContent.blockedByFilter = .specific(blocked)
        blockedDomainsCount = blocked.count

        print("🛡 Applied filter policy with \(blocked.count) domains")
        print("🧱 Example blocked domains: \(blocked.prefix(10).map { $0.domain })")
    }

    // MARK: - Refresh

    func refreshBlockedDomains() async {
        guard isBlockerEnabled else { return }

        if !isAuthorized {
            let authorized = await requestAuthorization()
            if !authorized { return }
        }

        let domains = await fetchBlockedDomains()
        if domains.isEmpty {
            print("⚠️ refreshBlockedDomains found 0 domains")
            return
        }

        applyBlockedDomains(domains)
        print("🔄 Refreshed blocked domains")
    }
}
