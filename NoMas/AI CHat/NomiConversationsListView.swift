//
//  NomiConversationsListView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/13/25.
//


//
//  NomiConversationsListView.swift
//  NoMas
//
//  Main view for Chat tab - shows welcome or conversation list
//

import SwiftUI

struct NomiConversationsListView: View {
    @ObservedObject var viewModel: NomiViewModel
    @State private var showQuiz = false
    @State private var navigateToNewChat = false
    @State private var newConversation: NomiConversation?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.hasCompletedQuiz {
                    // Show conversation list with normal layout
                    conversationsContent
                } else {
                    // Show welcome view (no header, tabs still visible from parent)
                    NomiWelcomeView(viewModel: viewModel, showQuiz: $showQuiz)
                }
            }
            .fullScreenCover(isPresented: $showQuiz) {
                NomiQuizView(viewModel: viewModel, isPresented: $showQuiz)
            }
            .navigationDestination(isPresented: $navigateToNewChat) {
                if let conversation = newConversation {
                    NomiChatView(viewModel: viewModel, conversation: conversation)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.checkQuizCompletion()
                if viewModel.hasCompletedQuiz {
                    await viewModel.loadConversations()
                }
            }
        }
        .onChange(of: viewModel.hasCompletedQuiz) {
            if viewModel.hasCompletedQuiz {
                Task {
                    await viewModel.loadConversations()
                }
            }
        }
    }
    
    // MARK: - Conversations Content
    
    private var conversationsContent: some View {
        ZStack(alignment: .bottom) {
            // Background
            ZStack {
                Image("bg7")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                if viewModel.groupedConversations.isEmpty && !viewModel.isLoadingConversations {
                    emptyStateView
                } else {
                    conversationsList
                }
            }
            
            // Floating new chat button
            newChatButton
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Placeholder animation
            Image("heart_blue")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            
            Text("Start Your First Chat")
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            Text("Connect with Nomi for personalized support on your recovery journey")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    // MARK: - Conversations List
    
    private var conversationsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.groupedConversations) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title)
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                        
                        ForEach(group.conversations) { conversation in
                            NavigationLink(destination:
                                NomiChatView(viewModel: viewModel, conversation: conversation)
                            ) {
                                NomiConversationCard(conversation: conversation)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Total count
                if !viewModel.conversations.isEmpty {
                    Text("\(viewModel.conversations.count) \(viewModel.conversations.count == 1 ? "Conversation" : "Conversations") Total")
                        .font(.captionSmall)
                        .foregroundColor(.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                }
            }
            .padding(.top, 20)
        }
        .refreshable {
            await viewModel.loadConversations()
        }
    }
    
    // MARK: - New Chat Button
    
    private var newChatButton: some View {
        Button {
            Task {
                if let conversation = await viewModel.createNewConversation() {
                    newConversation = conversation
                    navigateToNewChat = true
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Start New Chat")
                    .font(.button)
            }
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(LinearGradient.accent)
            .cornerRadius(28)
            .shadow(color: Color.accentGradientStart.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Conversation Card

struct NomiConversationCard: View {
    let conversation: NomiConversation
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy - h:mm a"
        return formatter.string(from: conversation.updatedAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(conversation.title)
                .font(.bodySmall)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
                .lineLimit(1)
            
            Text(formattedDate)
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient.accent)
                .opacity(0.75)
        )
    }
}

#Preview {
    NomiConversationsListView(viewModel: NomiViewModel())
}
