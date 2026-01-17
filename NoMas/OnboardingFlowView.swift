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
            
        case .bindAuth:
            BindAccountView()
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Flow") {
    OnboardingFlowView()
}

