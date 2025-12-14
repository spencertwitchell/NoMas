//
//  NomiWelcomeView.swift
//  NoMas
//
//  Welcome screen for Nomi AI - shown before quiz completion
//

import SwiftUI
import Lottie

struct NomiWelcomeView: View {
    @ObservedObject var viewModel: NomiViewModel
    @Binding var showQuiz: Bool
    
    var body: some View {
        // No background - uses parent's AppBackground from MainView
        VStack(spacing: 32) {
            Spacer()
            
            // Lottie animation placeholder
            LottieView(animation: .named("Heart_Blue"))
                .playing(loopMode: .loop)
                .frame(width: 180, height: 180)
            
            VStack(spacing: 16) {
                Text("Meet Nomi")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Your personal AI accountability coach")
                    .font(.titleSmall)
                    .foregroundColor(.textSecondary)
                
                Text("Nomi is here to support you through your recovery journey. Before you start chatting, let's get to know you a bit better so Nomi can provide personalized guidance.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Get Started Button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showQuiz = true
                }
            } label: {
                Text("Get Started")
                    .font(.button)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.accent)
                    .cornerRadius(28)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    ZStack {
        AppBackground()
        NomiWelcomeView(
            viewModel: NomiViewModel(),
            showQuiz: .constant(false)
        )
    }
}
