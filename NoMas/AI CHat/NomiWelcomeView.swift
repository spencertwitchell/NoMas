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
            
        
            
            VStack(spacing: 16) {
                Text("Conoce a Nomi")
                    .font(.titleXL)
                    .foregroundColor(.textPrimary)
                
                // Lottie animation placeholder
                LottieView(animation: .named("nomaswink"))
                    .playing(loopMode: .loop)
                    .frame(width: 200, height: 200)
                
                Text("Nomi, tu compañera de IA, está aquí para apoyarte en tu proceso de recuperación. Antes de empezar a chatear, conozcámonos un poco mejor para que Nomi pueda ofrecerte orientación personalizada.")
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
                Text("Comenzar")
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
