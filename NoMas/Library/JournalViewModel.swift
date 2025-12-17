//
//  JournalViewModel.swift
//  NoMas
//
//  ViewModel for journal prompts and entries
//

import Foundation
import Supabase
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    @Published var currentPrompt: JournalPrompt?
    @Published var allPrompts: [JournalPrompt] = []
    @Published var entries: [JournalEntry] = []
    @Published var groupedEntries: [GroupedEntries] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    // MARK: - Fetch Random Prompt
    
    func fetchRandomPrompt() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch all active prompts
            let prompts: [JournalPrompt] = try await supabase
                .from("journal_prompts")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value
            
            allPrompts = prompts
            
            // Select a random one
            if let randomPrompt = prompts.randomElement() {
                currentPrompt = randomPrompt
            }
            
            print("✅ Loaded \(prompts.count) journal prompts")
            isLoading = false
        } catch {
            print("❌ Failed to fetch prompt: \(error)")
            errorMessage = "Failed to load prompt"
            isLoading = false
        }
    }
    
    // MARK: - Get Next Prompt (skip current)
    
    func getNextPrompt() {
        guard !allPrompts.isEmpty else { return }
        
        // Filter out current prompt and select random from remaining
        let otherPrompts = allPrompts.filter { $0.id != currentPrompt?.id }
        if let nextPrompt = otherPrompts.randomElement() {
            currentPrompt = nextPrompt
        } else if let fallback = allPrompts.randomElement() {
            currentPrompt = fallback
        }
    }
    
    // MARK: - Save Entry
    
    func saveEntry(text: String, prompt: JournalPrompt?) async -> Bool {
        guard let userId = UserData.shared.supabaseUserId else {
            print("❌ No user ID")
            errorMessage = "Please sign in to save entries"
            return false
        }
        
        guard !text.isEmpty else {
            print("❌ Empty entry text")
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            struct JournalEntryInsert: Encodable {
                let user_id: String
                let prompt_id: String?
                let prompt_text: String?
                let entry_text: String
            }
            
            let entry = JournalEntryInsert(
                user_id: userId.uuidString,
                prompt_id: prompt?.id.uuidString,
                prompt_text: prompt?.promptText,
                entry_text: text
            )
            
            try await supabase
                .from("journal_entries")
                .insert(entry)
                .execute()
            
            print("✅ Journal entry saved")
            isSaving = false
            return true
        } catch {
            print("❌ Failed to save entry: \(error)")
            errorMessage = "Failed to save entry"
            isSaving = false
            return false
        }
    }
    
    // MARK: - Fetch All Entries
    
    func fetchEntries() async {
        guard let userId = UserData.shared.supabaseUserId else {
            print("❌ No user ID")
            return
        }
        
        isLoading = true
        
        do {
            let fetchedEntries: [JournalEntry] = try await supabase
                .from("journal_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            entries = fetchedEntries
            groupEntriesByDate()
            
            print("✅ Loaded \(fetchedEntries.count) journal entries")
            isLoading = false
        } catch {
            print("❌ Failed to fetch entries: \(error)")
            errorMessage = "Failed to load entries"
            isLoading = false
        }
    }
    
    // MARK: - Group Entries by Date
    
    private func groupEntriesByDate() {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [GroupedEntries] = []
        
        // Today
        let todayEntries = entries.filter { calendar.isDateInToday($0.createdAt) }
        if !todayEntries.isEmpty {
            groups.append(GroupedEntries(title: "Today", entries: todayEntries))
        }
        
        // Yesterday
        let yesterdayEntries = entries.filter { calendar.isDateInYesterday($0.createdAt) }
        if !yesterdayEntries.isEmpty {
            groups.append(GroupedEntries(title: "Yesterday", entries: yesterdayEntries))
        }
        
        // Previous 7 Days (excluding today and yesterday)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let weekEntries = entries.filter {
            !calendar.isDateInToday($0.createdAt) &&
            !calendar.isDateInYesterday($0.createdAt) &&
            $0.createdAt >= sevenDaysAgo &&
            $0.createdAt < now
        }
        if !weekEntries.isEmpty {
            groups.append(GroupedEntries(title: "Previous 7 Days", entries: weekEntries))
        }
        
        // Older
        let olderEntries = entries.filter { $0.createdAt < sevenDaysAgo }
        if !olderEntries.isEmpty {
            groups.append(GroupedEntries(title: "Older", entries: olderEntries))
        }
        
        groupedEntries = groups
    }
    
    // MARK: - Update Entry
    
    func updateEntry(id: UUID, newText: String) async -> Bool {
        guard !newText.isEmpty else { return false }
        
        isSaving = true
        
        do {
            struct JournalEntryUpdate: Encodable {
                let entry_text: String
                let updated_at: String
            }
            
            let update = JournalEntryUpdate(
                entry_text: newText,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("journal_entries")
                .update(update)
                .eq("id", value: id.uuidString)
                .execute()
            
            print("✅ Entry updated")
            
            // Refresh entries
            await fetchEntries()
            
            isSaving = false
            return true
        } catch {
            print("❌ Failed to update entry: \(error)")
            isSaving = false
            return false
        }
    }
    
    // MARK: - Delete Entry
    
    func deleteEntry(id: UUID) async {
        do {
            try await supabase
                .from("journal_entries")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
            
            print("✅ Entry deleted")
            
            // Remove from local array
            entries.removeAll { $0.id == id }
            groupEntriesByDate()
        } catch {
            print("❌ Failed to delete entry: \(error)")
        }
    }
}
