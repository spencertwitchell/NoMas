//
//  MightBreakView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  MightBreakView.swift
//  NoMas
//
//  Main "I Might Break" page with reflection questions and action links
//

import SwiftUI
import Lottie

struct MightBreakView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int
    @State private var currentQuestionIndex = 0
    @State private var showingPledge = false
    
    let questions: [String] = [
        "\"If I give in right now, will it bring real peace — or just a few minutes of relief followed by shame?\"",
        "\"Am I craving connection, or just running from discomfort? What do I actually need right now?\"",
        "\"Would the future version of me — the one I'm working to become — make this choice?\"",
        "\"What triggered this urge? Boredom? Stress? Loneliness? Can I address that instead?\"",
        "\"If I stay strong for just the next 10 minutes, will this urge still feel as powerful?\""
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .center, spacing: 16) {
                            // Header section
                            VStack(alignment: .center, spacing: 12) {
                                Text("Urges don't mean\nyou're failing.")
                                    .font(.titleLarge)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                                
                                // Lottie animation
                                LottieView(animation: .named("doubting"))
                                    .playing(loopMode: .loop)
                                    .frame(width: 175, height: 175)
                                
                                Text("Feeling the pull is a normal part of recovery. What matters is what you do next. Every urge you overcome makes the next one easier to resist.")
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(5)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                            
                            // Questions section
                            VStack(alignment: .center, spacing: 2) {
                                Text("Questions to reflect:")
                                    .font(.titleMedium)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                // Questions carousel
                                TabView(selection: $currentQuestionIndex) {
                                    ForEach(0..<questions.count, id: \.self) { index in
                                        MightBreakQuestionCard(question: questions[index])
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 140)
                                
                                // Page dots
                                HStack(spacing: 8) {
                                    ForEach(0..<questions.count, id: \.self) { index in
                                        Circle()
                                            .fill(currentQuestionIndex == index ? Color.accentGradientStart : Color.textTertiary)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 1)
                                .padding(.bottom, 16)
                            }
                            
                            // Things to do instead section
                            VStack(alignment: .center, spacing: 16) {
                                Text("Things to do instead:")
                                    .font(.titleMedium)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 10) {
                                    MightBreakActionButton(
                                        icon: "ellipsis.message.fill",
                                        title: "Talk It Out with AI Chat",
                                        action: {
                                            dismiss()
                                            selectedTab = 1 // Chat tab
                                        }
                                    )
                                    
                                    MightBreakActionButton(
                                        icon: "hand.raised.fill",
                                        title: "Make a Pledge for Today",
                                        action: {
                                            showingPledge = true
                                        }
                                    )
                                    
                                    MightBreakActionButton(
                                        icon: "person.3.fill",
                                        title: "Connect with the Community",
                                        action: {
                                            dismiss()
                                            selectedTab = 3 // Community tab
                                        }
                                    )
                                    
                                    MightBreakActionButton(
                                        icon: "sparkles",
                                        title: "Focus on Self Growth",
                                        action: {
                                            dismiss()
                                            selectedTab = 2 // Library tab
                                        }
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Return button
                            VStack(spacing: 12) {
                                Button(action: { dismiss() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 16))
                                        Text("Return to Timer")
                                            .font(.button)
                                    }
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(LinearGradient.accent)
                                    .cornerRadius(12)
                                }
                                
                                Text("This urge will pass. Stay strong — you're rewiring your brain.")
                                    .font(.captionSmall)
                                    .foregroundColor(.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPledge) {
                PledgeView()
            }
            // When pledge sheet is dismissed, also dismiss this view
            .onChange(of: showingPledge) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    // Pledge sheet was dismissed, dismiss this flow too
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Question Card

struct MightBreakQuestionCard: View {
    let question: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question)
                .font(.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient.accent
                .opacity(0.5)
        )
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Action Button

struct MightBreakActionButton: View {
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
                    .font(.buttonSmall)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(
                LinearGradient.accent
                    .opacity(0.5)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MightBreakView(selectedTab: .constant(0))
}