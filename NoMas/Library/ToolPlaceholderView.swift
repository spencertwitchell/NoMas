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

// MARK: - Previews

#Preview("Breathing") {
    BreathingExerciseView()
}

#Preview("Pledge") {
    PledgeView()
}
