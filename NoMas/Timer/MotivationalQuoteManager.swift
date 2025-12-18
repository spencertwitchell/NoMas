//
//  MotivationalQuoteManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  MotivationalQuoteManager.swift
//  NoMas
//
//  Manages motivational quotes from Supabase with 6-hour refresh cycle
//

import Foundation
import SwiftUI
import Supabase
import Combine

@MainActor
class MotivationalQuoteManager: ObservableObject {
    static let shared = MotivationalQuoteManager()
    
    @Published var currentQuote: String = "Every day you choose freedom is a victory. Keep going. 🔥"
    @Published var isLoading: Bool = false
    
    private let defaultQuote = "Every day you choose freedom is a victory. Keep going. 🔥"
    private let refreshInterval: TimeInterval = 6 * 60 * 60 // 6 hours in seconds
    
    // UserDefaults keys
    private let cachedQuoteKey = "cachedMotivationalQuote"
    private let cachedQuoteTimestampKey = "cachedQuoteTimestamp"
    private let cachedMilestoneKey = "cachedQuoteMilestone"
    private let lastResetDateKey = "lastQuoteResetDate"
    
    private init() {
        loadCachedQuote()
    }
    
    // MARK: - Public Methods
    
    /// Fetch a new quote if needed (checks 6-hour cache)
    func refreshQuoteIfNeeded(for milestone: Milestone, isReset: Bool = false) async {
        let milestoneCategory = getMilestoneCategory(milestone: milestone, isReset: isReset)
        
        // Check if we need to refresh
        if shouldFetchNewQuote(for: milestoneCategory) {
            await fetchNewQuote(for: milestoneCategory)
        }
    }
    
    /// Force fetch a new quote (ignores cache)
    func forceRefresh(for milestone: Milestone, isReset: Bool = false) async {
        let milestoneCategory = getMilestoneCategory(milestone: milestone, isReset: isReset)
        await fetchNewQuote(for: milestoneCategory)
    }
    
    // MARK: - Private Methods
    
    private func getMilestoneCategory(milestone: Milestone, isReset: Bool) -> String {
        // Special case: if user just reset and is on bronze milestone, use bronze_reset quotes
        if milestone == .bronze {
            if isReset {
                // User just reset - mark the reset time
                UserDefaults.standard.set(Date(), forKey: lastResetDateKey)
                return "bronze_reset"
            }
            
            // Check if reset was recent (within last 7 days while on bronze)
            if let lastResetDate = UserDefaults.standard.object(forKey: lastResetDateKey) as? Date {
                let daysSinceReset = Calendar.current.dateComponents([.day], from: lastResetDate, to: Date()).day ?? 0
                if daysSinceReset < 7 {
                    // Still within 7 days of reset - keep showing bronze_reset quotes
                    return "bronze_reset"
                }
            }
        }
        
        // Otherwise map milestone to category name (matches Supabase table)
        switch milestone {
        case .bronze: return "bronze"
        case .silver: return "silver"
        case .gold: return "gold"
        case .platinum: return "platinum"
        case .diamond: return "diamond"
        case .ruby: return "ruby"
        case .elite: return "elite"
        case .master: return "master"
        case .grandmaster: return "grandmaster"
        }
    }
    
    private func shouldFetchNewQuote(for milestoneCategory: String) -> Bool {
        // Check if cached milestone matches current milestone
        let cachedMilestone = UserDefaults.standard.string(forKey: cachedMilestoneKey)
        if cachedMilestone != milestoneCategory {
            // Milestone changed, fetch new quote
            return true
        }
        
        // Check if 6 hours have passed
        if let lastFetchTimestamp = UserDefaults.standard.object(forKey: cachedQuoteTimestampKey) as? Date {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetchTimestamp)
            return timeSinceLastFetch >= refreshInterval
        }
        
        // No timestamp found, fetch new quote
        return true
    }
    
    private func fetchNewQuote(for milestoneCategory: String) async {
        isLoading = true
        
        do {
            // Fetch all quotes for this milestone category
            struct QuoteResponse: Decodable {
                let id: String
                let milestone_category: String
                let quote_text: String
                let created_at: String
            }
            
            let quotes: [QuoteResponse] = try await supabase
                .from("motivational_quotes")
                .select()
                .eq("milestone_category", value: milestoneCategory)
                .execute()
                .value
            
            guard !quotes.isEmpty else {
                print("⚠️ No quotes found for milestone: \(milestoneCategory)")
                // Keep current quote or use default
                if currentQuote.isEmpty {
                    currentQuote = defaultQuote
                }
                isLoading = false
                return
            }
            
            // Pick a random quote
            if let randomQuote = quotes.randomElement() {
                currentQuote = randomQuote.quote_text
                
                // Cache the quote
                UserDefaults.standard.set(randomQuote.quote_text, forKey: cachedQuoteKey)
                UserDefaults.standard.set(Date(), forKey: cachedQuoteTimestampKey)
                UserDefaults.standard.set(milestoneCategory, forKey: cachedMilestoneKey)
                
                // Clear reset marker if user has progressed beyond bronze_reset
                if milestoneCategory != "bronze" && milestoneCategory != "bronze_reset" {
                    UserDefaults.standard.removeObject(forKey: lastResetDateKey)
                }
                
                print("✅ Fetched new quote for \(milestoneCategory): \(randomQuote.quote_text.prefix(50))...")
            }
            
        } catch {
            print("❌ Failed to fetch quote from Supabase: \(error)")
            // Keep the current quote or use default
            if currentQuote.isEmpty {
                currentQuote = defaultQuote
            }
        }
        
        isLoading = false
    }
    
    private func loadCachedQuote() {
        if let cachedQuote = UserDefaults.standard.string(forKey: cachedQuoteKey),
           !cachedQuote.isEmpty {
            currentQuote = cachedQuote
            print("📖 Loaded cached quote: \(cachedQuote.prefix(50))...")
        }
    }
}

// MARK: - UserData Extension

extension UserData {
    /// Call this when the timer is reset to get encouraging "reset" quotes
    func refreshMotivationalQuoteForReset() async {
        await MotivationalQuoteManager.shared.refreshQuoteIfNeeded(
            for: self.currentMilestone,
            isReset: true
        )
    }
}