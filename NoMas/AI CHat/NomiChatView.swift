//
//  NomiChatView.swift
//  NoMas
//
//  Individual chat view for Nomi AI conversations
//  Structure matches NoContact AIChatView for proper keyboard handling
//

import SwiftUI
import Lottie

struct NomiChatView: View {
    @ObservedObject var viewModel: NomiViewModel
    let conversation: NomiConversation
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    // Track which messages already animated so we never re-animate
    @State private var animatedMessageIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Image("bg7")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.dailyUsage.current >= 35 {
                        usageWarningBanner
                    }
                    messagesScrollView
                }
            }
            .navigationTitle("Chat with Nomi")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                        Task { await viewModel.summarizeConversation() }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.selectConversation(conversation)
            }
        }
        .safeAreaInset(edge: .bottom) {
            messageInputBar
        }
    }
    
    private var usageWarningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill").font(.system(size: 16))
            Text("\(viewModel.dailyUsage.current)/\(viewModel.dailyUsage.limit) Messages Used Today")
                .font(.captionSmall)
                .fontWeight(.medium)
        }
        .foregroundColor(.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(LinearGradient.accent)
    }
    
    private var messagesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Group {
                    // A) First page still loading: small spinner (no placeholder flicker)
                    if !viewModel.hasLoadedMessagesForCurrentConversation && viewModel.isLoadingMessages {
                        VStack {
                            Spacer(minLength: 60)
                            ProgressView().tint(.textPrimary)
                            Spacer(minLength: 60)
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)

                    // B) Loaded and empty: true empty state
                    } else if viewModel.hasLoadedMessagesForCurrentConversation && viewModel.messages.isEmpty {
                        placeholderView

                    // C) Messages (either cache shown instantly, or fetched)
                    } else {
                        LazyVStack(spacing: 16) {
                            if viewModel.canLoadMoreMessages && !viewModel.isLoadingMessages {
                                Button {
                                    Task { await viewModel.loadMessages(for: conversation.id, loadMore: true) }
                                } label: {
                                    Text("Load More")
                                        .font(.captionSmall)
                                        .foregroundColor(.textSecondary)
                                        .padding(.vertical, 8)
                                }
                            }
                            
                            if viewModel.isLoadingMessages {
                                ProgressView().tint(.textPrimary).padding(.vertical, 8)
                            }
                            
                            ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                let isLatest = index == viewModel.messages.count - 1
                                let shouldAnimate = message.role == "assistant"
                                    && isLatest
                                    && !animatedMessageIds.contains(message.id)
                                    && !message.content.isEmpty
                                
                                let showTyping = message.role == "assistant"
                                    && isLatest
                                    && viewModel.isSendingMessage
                                    && message.content.isEmpty
                                
                                NomiMessageBubble(
                                    message: message,
                                    showTypingIndicator: showTyping,
                                    shouldAnimateOnce: shouldAnimate,
                                    didFinishAnimating: { id in animatedMessageIds.insert(id) }
                                )
                                .id(message.id)
                            }
                            
                            // Bottom anchor for scrolling
                            Color.clear
                                .frame(height: 275)
                                .id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .defaultScrollAnchor(.bottom)
            .onAppear {
                // Initial scroll to bottom
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                // Scroll when message count changes
                scrollToBottom(proxy: proxy, animated: true)
            }
            .onChange(of: viewModel.isSendingMessage) { _, isSending in
                // Scroll when sending starts (typing indicator appears)
                if isSending {
                    scrollToBottom(proxy: proxy, animated: true)
                }
            }
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if animated {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 24) {
            Spacer()
            LottieView(animation: .named("nomasnormal"))
                .playing(loopMode: .loop)
                .frame(width: 200, height: 200)
            VStack(spacing: 12) {
                Text("What's on your mind?")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                Text("This is your space to talk through what you're feeling. Whether you're struggling with urges or celebrating progress, Nomi is here to help.")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 222)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 500)
    }
    
    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.2))
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask anything...", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                    .foregroundColor(.textPrimary)
                    .focused($isInputFocused)
                    .onChange(of: viewModel.messageText) {
                        if viewModel.messageText.count > 1000 {
                            viewModel.messageText = String(viewModel.messageText.prefix(1000))
                        }
                    }
                    .onSubmit {
                        // Dismiss keyboard and send on return key
                        if !viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            isInputFocused = false
                            Task {
                                // Small delay to let keyboard dismiss smoothly
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                                await viewModel.sendMessage()
                            }
                        }
                    }
                
                Button {
                    isInputFocused = false
                    Task {
                        // Small delay to let keyboard dismiss smoothly
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 38))
                        .foregroundStyle(
                            viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient.accent
                        )
                }
                .disabled(
                    viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isSendingMessage
                    || viewModel.dailyUsage.current >= viewModel.dailyUsage.limit
                )

            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.clear)
    }
}

// MARK: - Message Bubble

struct NomiMessageBubble: View {
    let message: NomiMessage
    let showTypingIndicator: Bool
    let shouldAnimateOnce: Bool
    let didFinishAnimating: (UUID) -> Void
    
    @State private var displayedText = ""
    @State private var animTask: Task<Void, Never>? = nil
    
    // Fast, "ChatGPT-like"
    private let charDelay: TimeInterval = 0.012
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == "user" { Spacer(minLength: 50) }
            
            if showTypingIndicator {
                typingIndicator
            } else {
                VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                    Text(shouldAnimateOnce ? displayedText : message.content)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(bubbleBackground)
                        .cornerRadius(18)
                }
            }
            
            if message.role == "assistant" { Spacer(minLength: 50) }
        }
        .onAppear(perform: maybeAnimate)
        .onChange(of: shouldAnimateOnce) { _, _ in
            maybeAnimate()
        }
        .onDisappear { animTask?.cancel() }
    }
    
    private var bubbleBackground: some View {
        Group {
            if message.role == "user" {
                LinearGradient.accent
            } else {
                LinearGradient.accent.opacity(0.25)
            }
        }
    }
    
    private var typingIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                        value: showTypingIndicator
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(LinearGradient.accent.opacity(0.25))
        .cornerRadius(18)
    }
    
    private func maybeAnimate() {
        // Only animate once per message id
        guard shouldAnimateOnce else {
            // ensure full text shows when not animating
            displayedText = message.content
            return
        }
        
        animTask?.cancel()
        displayedText = ""
        
        let chars = Array(message.content)
        animTask = Task {
            for c in chars {
                try? await Task.sleep(nanoseconds: UInt64(charDelay * 1_000_000_000))
                if Task.isCancelled { return }
                await MainActor.run { displayedText.append(c) }
            }
            await MainActor.run { didFinishAnimating(message.id) }
        }
    }
}

#Preview {
    NomiChatView(
        viewModel: NomiViewModel(),
        conversation: NomiConversation(
            id: UUID(),
            userId: UUID(),
            title: "Test Conversation",
            createdAt: Date(),
            updatedAt: Date(),
            messageCount: 5,
            contextSummary: nil
        )
    )
}
