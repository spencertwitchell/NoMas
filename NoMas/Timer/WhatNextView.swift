//
//  WhatNextView.swift
//  NoMas
//
//  Post-reset guidance page with action buttons that link to real features
//

import SwiftUI
import Lottie

// MARK: - What Next View

struct WhatNextView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int
    @Binding var shouldDismissToHome: Bool
    
    @State private var showingPledge = false
    @State private var showingReflectionJournal = false
    @State private var showingCreatePost = false
    
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
                            icon: "hand.raised.fill",
                            title: "Pledge to Stay Strong Tomorrow",
                            action: {
                                showingPledge = true
                            }
                        )
                        
                        WhatNextActionButton(
                            icon: "person.3.fill",
                            title: "Make a Post to Stay Accountable",
                            action: {
                                showingCreatePost = true
                            }
                        )
                        
                        WhatNextActionButton(
                            icon: "book.pages.fill",
                            title: "Reflect on What Happened",
                            action: {
                                showingReflectionJournal = true
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
        .sheet(isPresented: $showingPledge) {
            PledgeView()
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView(onPostCreated: {
                // Post was created successfully
            })
        }
        .sheet(isPresented: $showingReflectionJournal) {
            ReflectionJournalView()
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

// MARK: - Preview

#Preview("What Next View") {
    WhatNextView(selectedTab: .constant(0), shouldDismissToHome: .constant(false))
}
