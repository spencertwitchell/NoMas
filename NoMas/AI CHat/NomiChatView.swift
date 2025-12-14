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
    @State private var scrollProxy: ScrollViewProxy?
    @FocusState private var isInputFocused: Bool
    @State private var hasScrolledToBottom = false
    
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
                    messageInputBar
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
            .onChange(of: viewModel.messages) {
                // Delay scroll slightly to let keyboard dismiss first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    scrollToBottom()
                }
            }
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
                            
                            // Bottom spacer
                            Color.clear.frame(height: 10).id("bottom")
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
            .onAppear {
                scrollProxy = proxy
                if !hasScrolledToBottom && !viewModel.messages.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBottom(animated: false)
                        hasScrolledToBottom = true
                    }
                }
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 24) {
            Spacer()
            LottieView(animation: .named("Heart_Blue"))
                .playing(loopMode: .loop)
                .frame(width: 160, height: 160)
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
                .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSendingMessage)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.clear)
    }
    
    private func scrollToBottom(animated: Bool = true) {
        guard let scrollProxy = scrollProxy else { return }
        
        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                scrollProxy.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            scrollProxy.scrollTo("bottom", anchor: .bottom)
        }
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
