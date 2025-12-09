//
//  OnboardingCompleteView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//


//
//  OnboardingCompleteView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie

// MARK: - Onboarding Complete View

struct OnboardingCompleteView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    
    @State private var showCheckmark = false
    @State private var showText = false
    @State private var isTransitioning = false
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success animation
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGradientStart.opacity(0.4),
                                    Color.accentGradientStart.opacity(0)
                                ]),
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(showCheckmark ? 1.0 : 0.5)
                        .opacity(showCheckmark ? 1.0 : 0)
                    
                    // Checkmark circle
                    Circle()
                        .fill(LinearGradient.accent)
                        .frame(width: 120, height: 120)
                        .scaleEffect(showCheckmark ? 1.0 : 0.3)
                        .opacity(showCheckmark ? 1.0 : 0)
                    
                    // Checkmark icon
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showCheckmark ? 1.0 : 0.3)
                        .opacity(showCheckmark ? 1.0 : 0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showCheckmark)
                
                // Congratulations text
                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text("Your recovery journey begins now.\nWe're with you every step of the way.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showText ? 1.0 : 0)
                .offset(y: showText ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.3), value: showText)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Current streak display
                VStack(spacing: 8) {
                    Text("Your Current Streak")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundColor(userData.currentMilestone.color)
                        
                        Text("\(userData.daysSinceRelapse)")
                            .font(.titleXL)
                            .foregroundColor(.textPrimary)
                        
                        Text(userData.daysSinceRelapse == 1 ? "day" : "days")
                            .font(.titleSmall)
                            .foregroundColor(.textSecondary)
                    }
                }
                .opacity(showText ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.5), value: showText)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    if !isTransitioning {
                        isTransitioning = true
                        completeOnboarding()
                    }
                }) {
                    Text("Start My Journey")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(showText ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.7), value: showText)
            }
        }
        .onAppear {
            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showCheckmark = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showText = true
            }
            
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func completeOnboarding() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Mark onboarding as complete
        onboardingState.completeOnboarding()
        
        // This will trigger the app to show MainView
        // The transition is handled by the root view checking hasCompletedOnboarding
    }
}

// MARK: - Preview

#Preview {
    OnboardingCompleteView()
}