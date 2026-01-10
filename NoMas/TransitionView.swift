//
//  TransitionView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie

// MARK: - Transition View

struct TransitionView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                
                Spacer()
                
                // Content group (title, lottie, description)
                VStack(spacing: 24) {
                    // Title
                    Text("Breaking Free\nIs Possible")
                        .font(.titleXL)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    // Lottie animation
                    LottieView(animation: .named("breakfreeee"))
                        .playing(loopMode: .loop)
                        .frame(width: 280, height: 220)
                    
                    // Description
                    Text("Committing to recovery gives your brain the space it needs to heal. You'll regain clarity, feel more present, and rebuild the life you want.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Continue button
                Button(action: {
                    onboardingState.advance()
                }) {
                    Text("Continue")
                        .font(.button)
                        .foregroundColor(Color.accentGradientStart)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.textPrimary)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TransitionView()
}
