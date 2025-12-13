//
//  PlaceholderFlows.swift
//  NoMas
//
//  Temporary placeholder views for flows to be implemented later
//

import SwiftUI

// MARK: - Might Break Flow (Placeholder)

struct MightBreakFlowView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentGradientStart)
                
                Text("I Might Break")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Placeholder")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                
                Text("This flow will help you when you're feeling tempted.")
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

// MARK: - Panic Button Flow (Placeholder)

struct PanicButtonFlowView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("PANIC BUTTON")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Placeholder")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                
                Text("This flow will provide immediate crisis support and coping tools.")
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
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Previews

#Preview("Might Break") {
    MightBreakFlowView()
}

#Preview("Panic Button") {
    PanicButtonFlowView()
}
