//
//  QuizResultsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


//
//  QuizResultsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Quiz Results View

struct QuizResultsView: View {
    @State private var userBarHeight: CGFloat = 0
    @State private var avgBarHeight: CGFloat = 0
    
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    
    // MARK: - Computed Properties
    
    private var score: Double {
        userData.dependencyScore
    }
    
    private var scoreText: String {
        if score >= 85 {
            return "una dependencia grave"
        } else if score >= 75 {
            return "una dependencia significativa"
        } else if score >= 65 {
            return "una dependencia moderada"
        } else {
            return "algún nivel de dependencia"
        }
    }
    
    private var aboveAveragePercent: Int {
        Int(score - 40)
    }
    
    // Bar chart configuration
    private let maxBarHeight: CGFloat = 200
    private var userBarPercentage: CGFloat {
        CGFloat(score / 100)
    }
    private let avgBarPercentage: CGFloat = 0.40
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title
                    Text("Análisis Completo")
                        .font(.titleXL)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    
                    // Description
                    Text("Tus respuestas indican\(scoreText) sobre la pornografía — lo que indica patrones que requieren un cambio intencional.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                    
                    // Bar Chart
                    VStack(spacing: 20) {
                        HStack(alignment: .bottom, spacing: 40) {
                            // User score bar
                            VStack(spacing: 12) {
                                ZStack(alignment: .bottom) {
                                    // Background bar
                                    Rectangle()
                                        .fill(Color.textPrimary.opacity(0.2))
                                        .frame(width: 80, height: maxBarHeight)
                                        .cornerRadius(8)
                                    
                                    // Filled bar
                                    Rectangle()
                                        .fill(LinearGradient.accentVertical)
                                        .frame(width: 80, height: userBarHeight)
                                        .cornerRadius(8)
                                    
                                    // Score label
                                    Text("\(Int(score))%")
                                        .font(.titleMedium)
                                        .foregroundColor(.textPrimary)
                                        .offset(y: -(userBarHeight / 2))
                                }
                                
                                Text("Tus Resultados")
                                    .font(.caption)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            // Average bar
                            VStack(spacing: 12) {
                                ZStack(alignment: .bottom) {
                                    // Background bar
                                    Rectangle()
                                        .fill(Color.textPrimary.opacity(0.2))
                                        .frame(width: 80, height: maxBarHeight)
                                        .cornerRadius(8)
                                    
                                    // Filled bar
                                    Rectangle()
                                        .fill(Color.textPrimary.opacity(0.4))
                                        .frame(width: 80, height: avgBarHeight)
                                        .cornerRadius(8)
                                    
                                    // Score label
                                    Text("40%")
                                        .font(.titleMedium)
                                        .foregroundColor(.textPrimary)
                                        .offset(y: -(avgBarHeight / 3))
                                }
                                
                                Text("Promedio")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        // Comparison text
                        Text("\(aboveAveragePercent)% mayor dependencia\nque el promedio")
                            .font(.titleMedium)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                    
                    // Encouraging message
                    Text("¿La buena noticia? Reconocerlo es el primer paso. Estamos aquí para ayudarte a liberarte.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                    
                    // Continue button
                    Button(action: {
                        onboardingState.advance()
                    }) {
                        Text("Ver tus Síntomas")
                            .font(.button)
                            .foregroundColor(Color.accentGradientStart)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.textPrimary)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    
                    // Disclaimer
                    Text("*Este resultado es solo una indicación, no un diagnóstico médico.")
                        .font(.captionSmall)
                        .foregroundColor(.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            animateBars()
        }
    }
    
    // MARK: - Animation
    
    private func animateBars() {
        // Animate user bar first
        withAnimation(.easeOut(duration: 1.2)) {
            userBarHeight = maxBarHeight * userBarPercentage
        }
        
        // Animate average bar with slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 1.0)) {
                avgBarHeight = maxBarHeight * avgBarPercentage
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuizResultsView()
}
