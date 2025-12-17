//
//  LibraryToolPlaceholders.swift
//  NoMas
//
//  Placeholder views for library tools to be implemented
//

import SwiftUI

// MARK: - Generic Tool Placeholder

struct ToolPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    init(
        icon: String,
        title: String,
        description: String,
        accentColor: Color = .accentGradientStart
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Coming Soon")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                
                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Self Care Tools

struct JournalView: View {
    var body: some View {
        ToolPlaceholderView(
            icon: "book.pages.fill",
            title: "Recovery Journal",
            description: "Document your journey, track triggers, and celebrate victories in your personal recovery journal."
        )
    }
}

struct AffirmationsView: View {
    var body: some View {
        ToolPlaceholderView(
            icon: "brain.head.profile.fill",
            title: "Daily Affirmations",
            description: "Rewire your mindset with positive affirmations designed to strengthen your resolve and self-worth."
        )
    }
}

struct BreathingExerciseView: View {
    var body: some View {
        ToolPlaceholderView(
            icon: "wind",
            title: "Breathing Exercise",
            description: "Calm urges and reduce anxiety with guided breathing techniques proven to help in moments of temptation."
        )
    }
}

struct GratitudeView: View {
    var body: some View {
        ToolPlaceholderView(
            icon: "hands.sparkles.fill",
            title: "Express Gratitude",
            description: "Shift your focus to the positive aspects of your life and recovery journey through daily gratitude practice."
        )
    }
}

// MARK: - Previews

#Preview("Journal") {
    JournalView()
}

#Preview("Affirmations") {
    AffirmationsView()
}

#Preview("Breathing") {
    BreathingExerciseView()
}
