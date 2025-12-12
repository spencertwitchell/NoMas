//
//  OnboardingFlowView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Onboarding Flow Container

/// The main router view that displays the correct screen based on OnboardingState.currentPhase
struct OnboardingFlowView: View {
    @StateObject private var onboardingState = OnboardingState.shared
    @StateObject private var userData = UserData.shared
    
    var body: some View {
        ZStack {
            // PERSISTENT BACKGROUND - prevents white flash during transitions
            // This stays visible while child views animate in/out
            AppBackground()
            
            // Route to correct view based on current phase
            // Using opacity transition for smooth fades between phases
            currentPhaseView
                .id(onboardingState.currentPhase) // Force view recreation on phase change
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: onboardingState.currentPhase)
        }
        .onAppear {
            // Initialize user data from Supabase
            Task {
                await userData.initializeFromSupabase()
            }
        }
    }
    
    // MARK: - Phase Router
    
    @ViewBuilder
    private var currentPhaseView: some View {
        switch onboardingState.currentPhase {
        case .welcome:
            OnboardingWelcomeView()
            
        case .optionalAuth:
            OptionalAuthView()
            
        case .quiz:
            OnboardingQuizFlow()
            
        case .quizCalculating:
            QuizCalculatingView()
            
        case .quizResults:
            QuizResultsView()
            
        case .symptoms:
            SymptomsView()
            
        case .negativeEffects:
            NegativeEffectsView()
            
        case .transition:
            TransitionView()
            
        case .science:
            ScienceView()
            
        case .benefits:
            BenefitsView()
            
        case .testimonials:
            TestimonialsView()
            
        case .reviews:
            ReviewsView()
            
        case .commitment:
            CommitmentView()
            
        case .motivation:
            MotivationView()
            
        case .paywall:
            PaywallView()
            
        case .complete:
            OnboardingCompleteView()
        }
    }
}

// MARK: - Placeholder View (Temporary)

/// Temporary placeholder for screens not yet built
struct PlaceholderView: View {
    let title: String
    let phase: OnboardingPhase
    
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                Text(title)
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Coming Soon")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if phase.canGoBack {
                        Button(action: { onboardingState.goBack() }) {
                            Text("Back")
                                .font(.button)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Color.surfaceBackground)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: { onboardingState.advance() }) {
                        Text("Continue")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.accent)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    OnboardingFlowView()
}

#Preview("Placeholder") {
    PlaceholderView(title: "Test Screen", phase: .symptoms)
}
