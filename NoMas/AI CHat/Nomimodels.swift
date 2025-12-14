//
//  NomiModels.swift
//  NoMas
//
//  Data models for Nomi AI chat feature
//

import SwiftUI

// MARK: - Conversation Model

struct NomiConversation: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var messageCount: Int
    let contextSummary: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case messageCount = "message_count"
        case contextSummary = "context_summary"
    }
}

// MARK: - Message Model

struct NomiMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let conversationId: UUID
    let role: String
    let content: String
    let createdAt: Date
    let tokenCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case role
        case content
        case createdAt = "created_at"
        case tokenCount = "token_count"
    }
    
    static func == (lhs: NomiMessage, rhs: NomiMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Context Data Model (Database)

struct NomiContextData: Codable {
    let id: UUID?
    let userId: UUID
    let struggleDuration: String?
    let currentRelationship: String?
    let triggers: String?
    let vulnerableSituations: String?
    let postUseFeelings: String?
    let negativeEffects: String?
    let motivationForChange: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case struggleDuration = "struggle_duration"
        case currentRelationship = "current_relationship"
        case triggers
        case vulnerableSituations = "vulnerable_situations"
        case postUseFeelings = "post_use_feelings"
        case negativeEffects = "negative_effects"
        case motivationForChange = "motivation_for_change"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Check if all required fields are filled
    var isComplete: Bool {
        guard let struggleDuration = struggleDuration, !struggleDuration.isEmpty,
              let currentRelationship = currentRelationship, !currentRelationship.isEmpty,
              let triggers = triggers, !triggers.isEmpty,
              let vulnerableSituations = vulnerableSituations, !vulnerableSituations.isEmpty,
              let postUseFeelings = postUseFeelings, !postUseFeelings.isEmpty,
              let negativeEffects = negativeEffects, !negativeEffects.isEmpty,
              let motivationForChange = motivationForChange, !motivationForChange.isEmpty
        else {
            return false
        }
        return true
    }
}

// MARK: - Quiz Data (Local State)

struct NomiQuizData {
    var struggleDuration: String = ""
    var currentRelationship: String = ""
    var triggers: String = ""
    var vulnerableSituations: String = ""
    var postUseFeelings: String = ""
    var negativeEffects: String = ""
    var motivationForChange: String = ""
    
    init() {}
    
    init(from contextData: NomiContextData) {
        self.struggleDuration = contextData.struggleDuration ?? ""
        self.currentRelationship = contextData.currentRelationship ?? ""
        self.triggers = contextData.triggers ?? ""
        self.vulnerableSituations = contextData.vulnerableSituations ?? ""
        self.postUseFeelings = contextData.postUseFeelings ?? ""
        self.negativeEffects = contextData.negativeEffects ?? ""
        self.motivationForChange = contextData.motivationForChange ?? ""
    }
}

// MARK: - Grouped Conversations

struct GroupedNomiConversations: Identifiable {
    let id = UUID()
    let title: String
    let conversations: [NomiConversation]
}

// MARK: - API Response Models

struct NomiChatResponse: Codable {
    let message: String
    let tokensUsed: Int
    let usage: NomiUsageInfo
    
    enum CodingKeys: String, CodingKey {
        case message
        case tokensUsed
        case usage
    }
}

struct NomiUsageInfo: Codable {
    let current: Int
    let limit: Int
}

struct NomiRateLimitResponse: Codable {
    let error: String
    let usage: NomiUsageInfo
}

struct NomiErrorResponse: Codable {
    let error: String
}

// MARK: - Database Insert/Update Structs

struct NomiContextDataInsert: Encodable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct NomiContextDataUpdate: Encodable {
    var struggleDuration: String?
    var currentRelationship: String?
    var triggers: String?
    var vulnerableSituations: String?
    var postUseFeelings: String?
    var negativeEffects: String?
    var motivationForChange: String?
    
    enum CodingKeys: String, CodingKey {
        case struggleDuration = "struggle_duration"
        case currentRelationship = "current_relationship"
        case triggers
        case vulnerableSituations = "vulnerable_situations"
        case postUseFeelings = "post_use_feelings"
        case negativeEffects = "negative_effects"
        case motivationForChange = "motivation_for_change"
    }
}
