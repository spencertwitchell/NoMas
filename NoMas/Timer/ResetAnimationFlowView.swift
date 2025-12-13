//
//  ResetAnimationFlowView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/13/25.
//


//
//  ResetAnimationFlowView.swift
//  NoMas
//
//  Swipeable encouragement flow after user resets timer
//

import SwiftUI
import Lottie

// MARK: - Reset Animation Flow View

struct ResetAnimationFlowView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userData = UserData.shared
    @Binding var selectedTab: Int
    @State private var shouldDismissToHome = false
    let resetDate: Date
    
    @State private var currentPage = 0
    @State private var isDataReady = false
    @State private var newRecoveryDate: Date?
    @State private var showingWhatNext = false
    
    let totalPages = 4
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Page Content
                TabView(selection: $currentPage) {
                    ResetPage1_ItsOkay()
                        .tag(0)
                    
                    ResetPage2_EveryoneSlips()
                        .tag(1)
                    
                    ResetPage3_NewTimeline(
                        recoveryDate: newRecoveryDate,
                        totalDays: userData.totalRecoveryDays,
                        isDataReady: isDataReady
                    )
                    .tag(2)
                    
                    ResetPage4_YouCanDoThis()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    handleContinue()
                }) {
                    Text(currentPage == totalPages - 1 ? "Next Steps" : "Continue")
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
        .onAppear {
            startResetFlow()
        }
        .fullScreenCover(isPresented: $showingWhatNext) {
            WhatNextView(
                selectedTab: $selectedTab,
                shouldDismissToHome: $shouldDismissToHome
            )
        }
        .onChange(of: shouldDismissToHome) { _, newValue in
            if newValue {
                dismiss() // Dismisses ResetAnimationFlowView back to ResetTimerFlowView
            }
        }
    }
    
    // MARK: - Reset Flow Logic
    
    private func startResetFlow() {
        // IMMEDIATE: Update local data with the selected reset date
        userData.resetTimer(resetDate: resetDate)
        
        // Store the new date for display
        self.newRecoveryDate = userData.projectedRecoveryDate
        self.isDataReady = true
        
        print("🔄 Reset flow started")
        print("   New recovery date: \(userData.projectedRecoveryDate?.description ?? "nil")")
    }
    
    private func handleContinue() {
        if currentPage < totalPages - 1 {
            // Move to next page with animation
            withAnimation {
                currentPage += 1
            }
        } else {
            // Last page - go to What's Next view
            showingWhatNext = true
        }
    }
}

// MARK: - Page 1: It's Okay

struct ResetPage1_ItsOkay: View {
    var body: some View {
        VStack(spacing: 32) {
            LottieView(animation: .named("Heart_Blue"))
                .playing(loopMode: .loop)
                .frame(width: 175, height: 175)
            
            VStack(spacing: 16) {
                Text("You relapsed — and that's okay.")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Recovery isn't a straight line — it's a process of learning and coming back stronger each time.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Page 2: Everyone Slips

struct ResetPage2_EveryoneSlips: View {
    var body: some View {
        VStack(spacing: 32) {
            LottieView(animation: .named("Heart_Blue"))
                .playing(loopMode: .loop)
                .frame(width: 175, height: 175)
            
            VStack(spacing: 16) {
                Text("Almost everyone slips up.")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("What matters is that you're back here now — that's proof you're growing, not failing.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Page 3: New Timeline

struct ResetPage3_NewTimeline: View {
    let recoveryDate: Date?
    let totalDays: Int
    let isDataReady: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            LottieView(animation: .named("Heart_Blue"))
                .playing(loopMode: .loop)
                .frame(width: 200, height: 150)
            
            VStack(spacing: 16) {
                Text("You're still on the right path — just with a new timeline.")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            // Recovery Date Card
            if isDataReady, let date = recoveryDate {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your new projected recovery date:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(formatRecoveryDate(date))
                        .font(.titleMedium)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("0%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(daysRemaining(to: date)) days remaining")
                                .font(.captionSmall)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Progress bar (at 0% since just reset)
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(LinearGradient.accent)
                                    .frame(width: 0, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient.accent
                        .opacity(0.3)
                )
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
            } else {
                // Loading placeholder
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    
                    Text("Calculating your new timeline...")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                .frame(height: 120)
            }
        }
    }
    
    private func formatRecoveryDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func daysRemaining(to date: Date) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(days, 0)
    }
}

// MARK: - Page 4: You Can Do This

struct ResetPage4_YouCanDoThis: View {
    var body: some View {
        VStack(spacing: 32) {
            LottieView(animation: .named("Heart_Blue"))
                .playing(loopMode: .loop)
                .frame(width: 200, height: 175)
            
            VStack(spacing: 16) {
                Text("You can get through this.")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Stay consistent. Stay patient. Stay strong — your recovered self is closer than you think.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview

#Preview("Reset Animation Flow") {
    ResetAnimationFlowView(selectedTab: .constant(0), resetDate: Date())
}

#Preview("Page 3 - Timeline") {
    ZStack {
        AppBackground()
        ResetPage3_NewTimeline(
            recoveryDate: Calendar.current.date(byAdding: .day, value: 90, to: Date()),
            totalDays: 90,
            isDataReady: true
        )
    }
}