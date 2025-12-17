//
//  RemindersManager.swift
//  NoMas
//
//  Manages user's recovery reminders (reasons for quitting) with Supabase
//

import Foundation
import SwiftUI
import Combine
import Supabase

// MARK: - Reminder Model

struct RecoveryReminder: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    var text: String
    let createdAt: Date
    var sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case text
        case createdAt = "created_at"
        case sortOrder = "sort_order"
    }
}

// MARK: - Supabase Insert/Update Structs

struct ReminderInsert: Encodable {
    let userId: String
    let text: String
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case text
        case sortOrder = "sort_order"
    }
}

struct ReminderUpdate: Encodable {
    var text: String?
    var sortOrder: Int?
    
    enum CodingKeys: String, CodingKey {
        case text
        case sortOrder = "sort_order"
    }
}

// MARK: - Reminders Manager

@MainActor
class RemindersManager: ObservableObject {
    static let shared = RemindersManager()
    
    @Published var reminders: [RecoveryReminder] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let userData = UserData.shared
    
    private init() {}
    
    // MARK: - Default Reminder
    
    private var defaultReminder: String {
        "I'm trying to better myself"
    }
    
    // MARK: - Fetch Reminders
    
    func fetchReminders() async {
        guard let userId = userData.supabaseUserId else {
            print("⚠️ No user ID available for fetching reminders")
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchedReminders: [RecoveryReminder] = try await supabase
                .from("recovery_reminders")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("sort_order", ascending: true)
                .execute()
                .value
            
            // If no reminders exist, create the default one
            if fetchedReminders.isEmpty {
                await createReminder(text: defaultReminder)
            } else {
                reminders = fetchedReminders
            }
            
            print("✅ Fetched \(reminders.count) reminders")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to fetch reminders: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Create Reminder
    
    func createReminder(text: String) async {
        guard let userId = userData.supabaseUserId else {
            print("⚠️ No user ID available for creating reminder")
            return
        }
        
        let newSortOrder = (reminders.map { $0.sortOrder }.max() ?? -1) + 1
        
        let insert = ReminderInsert(
            userId: userId.uuidString,
            text: text,
            sortOrder: newSortOrder
        )
        
        do {
            let newReminder: RecoveryReminder = try await supabase
                .from("recovery_reminders")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value
            
            reminders.append(newReminder)
            print("✅ Created reminder: \(text)")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to create reminder: \(error)")
        }
    }
    
    // MARK: - Update Reminder
    
    func updateReminder(_ reminder: RecoveryReminder, newText: String) async {
        let update = ReminderUpdate(text: newText)
        
        do {
            try await supabase
                .from("recovery_reminders")
                .update(update)
                .eq("id", value: reminder.id.uuidString)
                .execute()
            
            if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[index].text = newText
            }
            
            print("✅ Updated reminder: \(newText)")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to update reminder: \(error)")
        }
    }
    
    // MARK: - Delete Reminder
    
    func deleteReminder(_ reminder: RecoveryReminder) async {
        do {
            try await supabase
                .from("recovery_reminders")
                .delete()
                .eq("id", value: reminder.id.uuidString)
                .execute()
            
            reminders.removeAll { $0.id == reminder.id }
            print("✅ Deleted reminder")
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to delete reminder: \(error)")
        }
    }
    
    // MARK: - Reorder Reminders
    
    func reorderReminders(_ newOrder: [RecoveryReminder]) async {
        reminders = newOrder
        
        // Update sort orders in database
        for (index, reminder) in newOrder.enumerated() {
            let update = ReminderUpdate(sortOrder: index)
            
            do {
                try await supabase
                    .from("recovery_reminders")
                    .update(update)
                    .eq("id", value: reminder.id.uuidString)
                    .execute()
            } catch {
                print("❌ Failed to update sort order: \(error)")
            }
        }
    }
}
