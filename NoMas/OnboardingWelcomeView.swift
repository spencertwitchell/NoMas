//
//  OnboardingWelcomeView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Onboarding Welcome View

struct OnboardingWelcomeView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    var body: some View {
        ZStack {
            // Background image
            Image("bg7")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Dark overlay
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Logo - smaller and higher
                Image("nomaslogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
                    .padding(.top, 80)
                
                Spacer()
                
                // Title & Description
                VStack(spacing: 16) {
                    Text("Welcome to NoMas")
                        .font(.titleXL)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                    
                    Text("Take a short quiz to help us understand your situation — we'll use your answers to build a personalized recovery plan just for you.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                    .frame(height: 32)
                
                // Start Quiz Button - right below paragraph
                Button(action: {
                    onboardingState.advance()
                }) {
                    HStack(spacing: 8) {
                        Text("Start Quiz")
                            .font(.button)
                        
                        Image(systemName: "arrow.right")
                            .font(.button)
                    }
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient.accent)
                    .cornerRadius(16)
                    .shadow(color: Color.accentGradientStart.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 48)
                
                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingWelcomeView()
}
