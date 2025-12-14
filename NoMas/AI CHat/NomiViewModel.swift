//
//  NomiViewModel.swift
//  NoMas
//
//  ViewModel for Nomi AI chat feature
//

import SwiftUI
import Supabase
import Combine

@MainActor
class NomiViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Conversations
    @Published var conversations: [NomiConversation] = []
    @Published var groupedConversations: [GroupedNomiConversations] = []
    @Published var currentConversation: NomiConversation?
    @Published var isLoadingConversations = false
    
    // Messages
    @Published var messages: [NomiMessage] = []
    @Published var isLoadingMessages = false
    @Published var hasLoadedMessagesForCurrentConversation = false
    @Published var isSendingMessage = false
    @Published var messageText = ""
    
    // Quiz
    @Published var hasCompletedQuiz = false
    @Published var quizData = NomiQuizData()
    
    // Usage & Errors
    @Published var dailyUsage: (current: Int, limit: Int) = (0, 40)
    @Published var errorMessage: String?
    
    // Pagination
    private var oldestLoadedMessageDate: Date?
    var canLoadMoreMessages = true
    private var messageCache: [UUID: [NomiMessage]] = [:]
    
    // MARK: - Constants
    
    private let baseURL = "https://app.nomas-app.com/functions/v1"
    
    // MARK: - Init
    
    init() {
        Task {
            await checkQuizCompletion()
        }
    }
    
    private struct DailyUsageRPCResponse: Decodable {
        let current: Int
        let limit: Int
    }

    private func incrementDailyUsageOrThrow() async throws -> (current: Int, limit: Int) {
        // Default limit from app state, or hardcode 40
        let limit = dailyUsage.limit

        let response: DailyUsageRPCResponse = try await supabase
            .rpc("increment_nomi_daily_usage", params: ["p_limit": limit])
            .execute()
            .value

        return (response.current, response.limit)
    }

    // MARK: - Quiz Methods
    
    func checkQuizCompletion() async {
        do {
            guard let userId = supabase.auth.currentUser?.id else { return }
            
            let response: [NomiContextData] = try await supabase
                .from("nomi_context_data")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let contextData = response.first {
                hasCompletedQuiz = contextData.isComplete
                if hasCompletedQuiz {
                    quizData = NomiQuizData(from: contextData)
                }
            } else {
                hasCompletedQuiz = false
            }
        } catch {
            print("❌ Failed to check quiz completion: \(error)")
            hasCompletedQuiz = false
        }
    }
    
    func saveQuizData() async throws {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "NomiViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        
        // First, check if record exists
        let existing: [NomiContextData] = try await supabase
            .from("nomi_context_data")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        let update = NomiContextDataUpdate(
            struggleDuration: quizData.struggleDuration,
            currentRelationship: quizData.currentRelationship,
            triggers: quizData.triggers,
            vulnerableSituations: quizData.vulnerableSituations,
            postUseFeelings: quizData.postUseFeelings,
            negativeEffects: quizData.negativeEffects,
            motivationForChange: quizData.motivationForChange
        )
        
        if existing.isEmpty {
            // Insert new record
            try await supabase
                .from("nomi_context_data")
                .insert([
                    "user_id": userId.uuidString,
                    "struggle_duration": quizData.struggleDuration,
                    "current_relationship": quizData.currentRelationship,
                    "triggers": quizData.triggers,
                    "vulnerable_situations": quizData.vulnerableSituations,
                    "post_use_feelings": quizData.postUseFeelings,
                    "negative_effects": quizData.negativeEffects,
                    "motivation_for_change": quizData.motivationForChange
                ])
                .execute()
        } else {
            // Update existing record
            try await supabase
                .from("nomi_context_data")
                .update(update)
                .eq("user_id", value: userId.uuidString)
                .execute()
        }
        
        hasCompletedQuiz = true
    }
    
    // MARK: - Conversation Methods
    
    func loadConversations() async {
        guard !isLoadingConversations else { return }
        isLoadingConversations = true
        errorMessage = nil
        
        do {
            guard let userId = supabase.auth.currentUser?.id else {
                isLoadingConversations = false
                return
            }
            
            let response: [NomiConversation] = try await supabase
                .from("nomi_conversations")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("updated_at", ascending: false)
                .execute()
                .value
            
            conversations = response
            groupConversationsByDate()
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            print("❌ Failed to load conversations: \(error)")
        }
        
        isLoadingConversations = false
    }
    
    private func groupConversationsByDate() {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [GroupedNomiConversations] = []
        
        // Today
        let todayConversations = conversations.filter { calendar.isDateInToday($0.updatedAt) }
        if !todayConversations.isEmpty {
            groups.append(GroupedNomiConversations(title: "Today", conversations: todayConversations))
        }
        
        // Yesterday
        let yesterdayConversations = conversations.filter { calendar.isDateInYesterday($0.updatedAt) }
        if !yesterdayConversations.isEmpty {
            groups.append(GroupedNomiConversations(title: "Yesterday", conversations: yesterdayConversations))
        }
        
        // Previous 7 Days
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let weekConversations = conversations.filter {
            !calendar.isDateInToday($0.updatedAt) &&
            !calendar.isDateInYesterday($0.updatedAt) &&
            $0.updatedAt >= sevenDaysAgo &&
            $0.updatedAt < now
        }
        if !weekConversations.isEmpty {
            groups.append(GroupedNomiConversations(title: "Previous 7 Days", conversations: weekConversations))
        }
        
        // Older
        let olderConversations = conversations.filter { $0.updatedAt < sevenDaysAgo }
        if !olderConversations.isEmpty {
            groups.append(GroupedNomiConversations(title: "Older", conversations: olderConversations))
        }
        
        groupedConversations = groups
    }
    
    func createNewConversation() async -> NomiConversation? {
        do {
            guard let userId = supabase.auth.currentUser?.id else { return nil }
            
            let newConversation = NomiConversation(
                id: UUID(),
                userId: userId,
                title: "New Chat",
                createdAt: Date(),
                updatedAt: Date(),
                messageCount: 0,
                contextSummary: nil
            )
            
            let response: NomiConversation = try await supabase
                .from("nomi_conversations")
                .insert(newConversation)
                .select()
                .single()
                .execute()
                .value
            
            conversations.insert(response, at: 0)
            currentConversation = response
            messages = []
            groupConversationsByDate()
            
            return response
        } catch {
            errorMessage = "Failed to create conversation: \(error.localizedDescription)"
            print("❌ Failed to create conversation: \(error)")
            return nil
        }
    }
    
    func selectConversation(_ conversation: NomiConversation) {
        currentConversation = conversation
        oldestLoadedMessageDate = nil
        canLoadMoreMessages = true
        hasLoadedMessagesForCurrentConversation = false
        
        // Show cached messages instantly if available
        if let cached = messageCache[conversation.id], !cached.isEmpty {
            messages = cached
        } else {
            messages = []
        }
        
        Task { await loadMessages(for: conversation.id, loadMore: false) }
    }
    
    // MARK: - Message Methods
    
    func loadMessages(for conversationId: UUID, loadMore: Bool = false) async {
        guard !isLoadingMessages else { return }
        isLoadingMessages = true
        
        do {
            var query = supabase
                .from("nomi_messages")
                .select()
                .eq("conversation_id", value: conversationId.uuidString)
            
            if loadMore, let oldestDate = oldestLoadedMessageDate {
                query = query.lt("created_at", value: ISO8601DateFormatter().string(from: oldestDate))
            }
            
            let response: [NomiMessage] = try await query
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value
            
            if response.isEmpty {
                canLoadMoreMessages = false
            } else {
                oldestLoadedMessageDate = response.last?.createdAt
                
                let reversed = response.reversed()
                if loadMore {
                    messages.insert(contentsOf: reversed, at: 0)
                } else {
                    messages = Array(reversed)
                }
                
                // Update cache
                messageCache[conversationId] = messages
            }
            
            hasLoadedMessagesForCurrentConversation = true
        } catch {
            print("❌ Failed to load messages: \(error)")
        }
        
        isLoadingMessages = false
    }
    
    func sendMessage() async {
        let userMessageText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userMessageText.isEmpty,
              let conversationId = currentConversation?.id else { return }

        // Clear input + set state
        messageText = ""
        isSendingMessage = true
        errorMessage = nil

        // rollback helper for optimistic UI
        func rollbackOptimistic(userId: UUID, aiId: UUID) {
            messages.removeAll { $0.id == userId || $0.id == aiId }
        }

        struct DailyUsageRPCRow: Decodable {
            let current: Int
            let limit: Int
        }

        do {
            // 1) Auth
            guard let session = supabase.auth.currentSession else {
                throw NSError(domain: "NomiViewModel", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "Not authenticated"
                ])
            }

            // 2) Increment daily usage FIRST (RPC returns an ARRAY of rows)
            do {
                let rows: [DailyUsageRPCRow] = try await supabase
                    .rpc("increment_nomi_daily_usage", params: ["p_limit": dailyUsage.limit])
                    .execute()
                    .value

                guard let row = rows.first else {
                    throw NSError(domain: "NomiViewModel", code: 500, userInfo: [
                        NSLocalizedDescriptionKey: "Daily usage RPC returned no rows."
                    ])
                }

                dailyUsage = (row.current, row.limit)

                // Block only if we somehow exceed limit (RPC should prevent that anyway)
                if dailyUsage.current > dailyUsage.limit {
                    throw NSError(domain: "NomiViewModel", code: 429, userInfo: [
                        NSLocalizedDescriptionKey: "Daily message limit reached."
                    ])
                }
            }

            // 3) Optimistic UI
            let userMessageId = UUID()
            let aiMessageId = UUID()

            let userMessage = NomiMessage(
                id: userMessageId,
                conversationId: conversationId,
                role: "user",
                content: userMessageText,
                createdAt: Date(),
                tokenCount: 0
            )
            messages.append(userMessage)

            let aiPlaceholder = NomiMessage(
                id: aiMessageId,
                conversationId: conversationId,
                role: "assistant",
                content: "",
                createdAt: Date(),
                tokenCount: 0
            )
            messages.append(aiPlaceholder)

            bumpCurrentConversation(addedMessages: 1)

            // 4) Call Edge Function
            let requestBody: [String: Any] = [
                "conversationId": conversationId.uuidString,
                "message": userMessageText
            ]

            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

            var request = URLRequest(url: URL(string: "\(baseURL)/nomi-chat")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                rollbackOptimistic(userId: userMessageId, aiId: aiMessageId)
                throw NSError(domain: "NomiViewModel", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid response"
                ])
            }

            if httpResponse.statusCode == 429 {
                let rateLimitResponse = try JSONDecoder().decode(NomiRateLimitResponse.self, from: data)
                dailyUsage = (rateLimitResponse.usage.current, rateLimitResponse.usage.limit)

                rollbackOptimistic(userId: userMessageId, aiId: aiMessageId)

                throw NSError(domain: "NomiViewModel", code: 429, userInfo: [
                    NSLocalizedDescriptionKey: rateLimitResponse.error
                ])
            }

            if httpResponse.statusCode != 200 {
                let errorResponse = try? JSONDecoder().decode(NomiErrorResponse.self, from: data)

                rollbackOptimistic(userId: userMessageId, aiId: aiMessageId)

                throw NSError(domain: "NomiViewModel", code: httpResponse.statusCode, userInfo: [
                    NSLocalizedDescriptionKey: errorResponse?.error ?? "Unknown error"
                ])
            }

            let chatResponse = try JSONDecoder().decode(NomiChatResponse.self, from: data)

            // If your Edge Function returns usage too, keep it (should match)
            dailyUsage = (chatResponse.usage.current, chatResponse.usage.limit)

            if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                messages[index] = NomiMessage(
                    id: aiMessageId,
                    conversationId: conversationId,
                    role: "assistant",
                    content: chatResponse.message,
                    createdAt: Date(),
                    tokenCount: chatResponse.tokensUsed
                )
            }

        } catch {
            errorMessage = error.localizedDescription
            print("❌ sendMessage error: \(error.localizedDescription)")
        }

        isSendingMessage = false
    }


    
    private func bumpCurrentConversation(updatedAt: Date = Date(), addedMessages: Int = 0) {
        guard let convoId = currentConversation?.id,
              let idx = conversations.firstIndex(where: { $0.id == convoId }) else { return }
        
        conversations[idx].updatedAt = updatedAt
        conversations[idx].messageCount += addedMessages
        
        conversations.sort { $0.updatedAt > $1.updatedAt }
        groupConversationsByDate()
    }
    
    func summarizeConversation() async {
        guard let conversationId = currentConversation?.id else { return }
        
        do {
            guard let session = supabase.auth.currentSession else { return }
            
            let requestBody: [String: Any] = [
                "conversationId": conversationId.uuidString
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = URLRequest(url: URL(string: "\(baseURL)/nomi-summarize")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let _ = try await URLSession.shared.data(for: request)
            // Summarization happens in background, no need to handle response
        } catch {
            print("❌ Failed to summarize conversation: \(error)")
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}


