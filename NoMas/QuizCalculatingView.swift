//
//  QuizCalculatingView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


//
//  QuizCalculatingView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Quiz Calculating View

struct QuizCalculatingView: View {
    @State private var progress: Double = 0
    @State private var currentMessageIndex = 0
    
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    private let messages = [
        "Analyzing your responses...",
        "Calculating dependency level...",
        "Preparing your recovery plan..."
    ]
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Circular progress indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.textPrimary.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient.accent,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.1), value: progress)
                    
                    // Percentage text
                    Text("\(Int(progress * 100))%")
                        .font(.titleCustom(size: 48))
                        .foregroundColor(.textPrimary)
                }
                
                // Status text
                VStack(spacing: 16) {
                    Text("Calculating...")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text(messages[currentMessageIndex])
                        .font(.bodyLarge)
                        .foregroundColor(.textSecondary)
                        .id(currentMessageIndex)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startCalculating()
        }
    }
    
    // MARK: - Animation Logic
    
    private func startCalculating() {
        // Progress animation timer
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.02
                
                // Haptic feedback every 10%
                if Int(progress * 100) % 10 == 0 {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                }
            } else {
                timer.invalidate()
                
                // Final haptic
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Short delay then advance to results
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onboardingState.advance()
                }
            }
        }
        
        // Message rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { currentMessageIndex = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { currentMessageIndex = 2 }
        }
    }
}

// MARK: - Preview

#Preview {
    QuizCalculatingView()
}