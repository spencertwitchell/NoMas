//
//  JournalModels.swift
//  NoMas
//
//  Models for journal prompts and entries
//

import Foundation

// MARK: - Journal Prompt Model

struct JournalPrompt: Identifiable, Codable {
    let id: UUID
    let promptText: String
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case promptText = "prompt_text"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

// MARK: - Journal Entry Model

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let promptId: UUID?
    let promptText: String?
    let entryText: String
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case promptId = "prompt_id"
        case promptText = "prompt_text"
        case entryText = "entry_text"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Grouped Entries for Display

struct GroupedEntries: Identifiable {
    let id = UUID()
    let title: String
    let entries: [JournalEntry]
}
