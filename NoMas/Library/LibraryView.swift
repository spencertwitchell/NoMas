//
//  LibraryView.swift
//  NoMas
//
//  Library tab with self-care tools and educational articles
//

import SwiftUI
import MarkdownUI

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedArticle: Article?
    
    // Self Care tool sheet states
    @State private var showingJournal = false
    @State private var showingAffirmations = false
    @State private var showingBreathing = false
    @State private var showingGratitude = false
    @State private var showingMeditation = false
    @State private var showingWebsiteBlocker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                selfCareSection
                guidesArticlesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 100) // Extra padding for tab bar
        }
        .task {
            await viewModel.fetchData()
        }
        .fullScreenCover(item: $selectedArticle) { article in
            ArticleDetailView(article: article)
        }
        // Self Care sheets
        .fullScreenCover(isPresented: $showingJournal) { ReflectionJournalView() }
        .fullScreenCover(isPresented: $showingAffirmations) { AffirmationsView() }
        .fullScreenCover(isPresented: $showingBreathing) { BreathingExerciseView() }
        .fullScreenCover(isPresented: $showingGratitude) { GratitudeView() }
        .fullScreenCover(isPresented: $showingMeditation) { RelaxationSoundsView() }
        .fullScreenCover(isPresented: $showingWebsiteBlocker) { WebsiteBlockerView() }
    }
    
    // MARK: - Self Care Section
    
    private var selfCareSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Self Care")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text("Daily practices to strengthen your mind and support recovery.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            // 4 Circular Icon Buttons
            HStack(spacing: 16) {
                SelfCareCircleButton(
                    icon: "book.pages.fill",
                    label: "Recovery\nJournal",
                    action: { showingJournal = true }
                )
                
                SelfCareCircleButton(
                    icon: "brain.head.profile.fill",
                    label: "Daily\nAffirmations",
                    action: { showingAffirmations = true }
                )
                
                SelfCareCircleButton(
                    icon: "wind",
                    label: "Breathing\nExercise",
                    action: { showingBreathing = true }
                )
                
                SelfCareCircleButton(
                    icon: "hands.sparkles.fill",
                    label: "Express\nGratitude",
                    action: { showingGratitude = true }
                )
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 4)
            
            // 2 Image Background Cards
            VStack(spacing: 12) {
                SelfCareImageCard(
                    title: "Guided Meditation",
                    imageName: "meditation",
                    action: { showingMeditation = true }
                )
                
                SelfCareImageCard(
                    title: "Website Blocker",
                    imageName: "blocker",
                    action: { showingWebsiteBlocker = true }
                )
            }
        }
    }
    
    // MARK: - Guides & Articles Section
    
    private var guidesArticlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Guides & Articles")
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text("Educational content on addiction, recovery, and building a healthier life.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 40)
                    Spacer()
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .font(.bodySmall)
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.vertical, 20)
            } else if viewModel.categories.isEmpty {
                Text("No articles available yet")
                    .font(.bodySmall)
                    .foregroundColor(.textTertiary)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.categories) { category in
                    CategorySection(
                        category: category,
                        articles: viewModel.articlesByCategory[category.id]?.sorted { $0.sort < $1.sort } ?? [],
                        onArticleTap: { article in
                            selectedArticle = article
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Self Care Circle Button

struct SelfCareCircleButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.accent)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 70)
        }
    }
}

// MARK: - Self Care Image Card

struct SelfCareImageCard: View {
    let title: String
    let imageName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                // Background image
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 50)
                
                // Gradient overlay for text readability (left to right)
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 50)
                
                // Title
                Text(title)
                    .font(.titleSmall)
                    .foregroundColor(.white)
                    .padding(.leading, 16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: Category
    let articles: [Article]
    let onArticleTap: (Article) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(category.title)
                .font(.titleSmall)
                .foregroundColor(.white)
            
            if articles.isEmpty {
                Text("No articles yet")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .padding(.bottom, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(articles) { article in
                            ArticleCard(article: article)
                                .onTapGesture {
                                    onArticleTap(article)
                                }
                        }
                    }
                    .padding(.trailing, 28)
                }
                .scrollClipDisabled()
            }
        }
    }
}

// MARK: - Article Card

struct ArticleCard: View {
    let article: Article
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: URL(string: article.heroImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient.accent.opacity(0.5))
                    .overlay(ProgressView().tint(.white))
            }
            .frame(width: 270, height: 180)
            .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Title
            Text(article.title)
                .font(.titleSmall)
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .padding(12)
        }
        .frame(width: 270, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Article Detail View

struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss) var dismiss
    @State private var articleContent: String = ""
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Hero Image
                            AsyncImage(url: URL(string: article.heroImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(LinearGradient.accent.opacity(0.3))
                            }
                            .frame(maxWidth: .infinity, maxHeight: 300)
                            .clipped()
                            
                            // Content
                            VStack(alignment: .leading, spacing: 16) {
                                Text(article.title)
                                    .font(.titleLarge)
                                    .foregroundColor(.white)
                                
                                Markdown(articleContent)
                                    .appMarkdownStyle()
                            }
                            .padding(20)
                        }
                    }
                    .ignoresSafeArea(edges: .top)
                }
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 32, height: 32)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .task {
                await fetchArticleContent()
            }
        }
    }
    
    func fetchArticleContent() async {
        isLoading = true
        
        guard let url = URL(string: article.bodyMd) else {
            articleContent = "Failed to load article content."
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let content = String(data: data, encoding: .utf8) {
                articleContent = content
            } else {
                articleContent = "Failed to decode article content."
            }
        } catch {
            articleContent = "Error loading article: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppBackground()
        LibraryView()
    }
}
