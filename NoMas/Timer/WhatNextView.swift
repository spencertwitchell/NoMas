//
//  WhatNextView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/13/25.
//


//
//  WhatNextView.swift
//  NoMas
//
//  Post-reset guidance page with action buttons
//

import SwiftUI
import Lottie

// MARK: - What Next View

struct WhatNextView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int
    @Binding var shouldDismissToHome: Bool
    
    @State private var showingReflectionView = false
    @State private var showingWhyQuittingView = false
    @State private var showingSelfCareView = false
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer()
                        .frame(height: 20)
                    
                    // Header
                    Text("What To Do Next")
                        .font(.titleXL)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Description
                    Text("Don't dwell on what happened — redirect your energy. The best way to recover from a setback is by focusing on what you can do next to heal and move forward.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                    
                    // Lottie Animation
                    LottieView(animation: .named("Heart_Blue"))
                        .playing(loopMode: .loop)
                        .frame(width: 175, height: 175)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        WhatNextActionButton(
                            icon: "pencil.and.outline",
                            title: "Reflect on What Triggered You",
                            action: {
                                showingReflectionView = true
                            }
                        )
                        
                        WhatNextActionButton(
                            icon: "brain.head.profile",
                            title: "Remind Yourself Why You're Quitting",
                            action: {
                                showingWhyQuittingView = true
                            }
                        )
                        
                        WhatNextActionButton(
                            icon: "heart.fill",
                            title: "Practice Self-Compassion",
                            action: {
                                showingSelfCareView = true
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                        .frame(height: 16)
                    
                    // Return to Timer Button
                    Button(action: {
                        selectedTab = 0
                        shouldDismissToHome = true
                        dismiss()
                    }) {
                        Text("Return to Timer")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(LinearGradient.accent)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    
                    // Bottom caption
                    Text("This moment will pass. Stay strong — you're moving forward.")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .sheet(isPresented: $showingReflectionView) {
            ReflectionPlaceholderView()
        }
        .sheet(isPresented: $showingWhyQuittingView) {
            WhyQuittingPlaceholderView()
        }
        .sheet(isPresented: $showingSelfCareView) {
            SelfCarePlaceholderView()
        }
    }
}

// MARK: - What Next Action Button

struct WhatNextActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.textPrimary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.button)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.accent.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder Views (to be replaced later)

struct ReflectionPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.accent)
                
                Text("Reflection Journal")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Coming soon — a space to reflect on your triggers and learn from each experience.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

struct WhyQuittingPlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.accent)
                
                Text("Why I'm Quitting")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Coming soon — reminders of your reasons for recovery and the benefits you're working toward.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

struct SelfCarePlaceholderView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.accent)
                
                Text("Self-Compassion")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Coming soon — guided exercises for self-compassion and healthy coping strategies.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Preview

#Preview("What Next View") {
    WhatNextView(selectedTab: .constant(0), shouldDismissToHome: .constant(false))
}

#Preview("Reflection Placeholder") {
    ReflectionPlaceholderView()
}