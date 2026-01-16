//
//  NegativeEffectsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie

// MARK: - Warning Colors (for negative content screens)

extension Color {
    static let warningGradientStart = Color(hex: "4A0A0A")
    static let warningGradientEnd = Color(hex: "7A1515")
}

extension LinearGradient {
    static let warning = LinearGradient(
        gradient: Gradient(colors: [Color.warningGradientStart, Color.warningGradientEnd]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Negative Effects View

struct NegativeEffectsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @State private var currentPage = 0
    
    private let cards = [
        NegativeEffectCard(
            title: "La pornografía reconfigura tu cerebro",
            description: "La exposición repetida secuestra el sistema de recompensa de tu cerebro, creando vías neuronales que requieren contenido cada vez más extremo para sentir la misma descarga de dopamina.",
            lottieName: "Brain"
        ),
        NegativeEffectCard(
            title: "Daña la intimidad real",
            description: "La pornografía genera expectativas poco realistas y te insensibiliza a la conexión humana real, haciendo que la intimidad genuina se sienta menos satisfactoria con el tiempo.",
            lottieName: "intimac"
        ),
        NegativeEffectCard(
            title: "Cada recaída profundiza el ciclo",
            description: "Cada vez que cedes, fortaleces las vías adictivas en tu cerebro. No se trata de fuerza de voluntad, sino de romper el ciclo antes de que te rompa a ti.",
            lottieName: "rut"
        ),
        NegativeEffectCard(
            title: "La recuperación requiere distancia",
            description: "Al igual que con cualquier adicción, la sanación requiere abstinencia completa. Tu cerebro necesita tiempo sin estimulación para reconstruir conexiones neuronales saludables.",
            lottieName: "recovery"
        )
    ]
    
    var body: some View {
        ZStack {
            // Warning gradient background (deeper red)
            LinearGradient.warning
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { onboardingState.goBack() }) {
                        Image(systemName: "chevron.left")
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Image("nomaslogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 40)
                    
                    Spacer()
                    
                    Spacer()
                        .frame(width: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Carousel (lottie, title, description) - positioned higher
                TabView(selection: $currentPage) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        NegativeEffectCardView(card: cards[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 520)
                
                Spacer()
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.textPrimary : Color.textPrimary.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 24)
                
                // Continue button (stays at bottom)
                Button(action: {
                    if currentPage < cards.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onboardingState.advance()
                    }
                }) {
                    Text("Continuar")
                        .font(.button)
                        .foregroundColor(.warningGradientEnd)
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

// MARK: - Card Model

struct NegativeEffectCard {
    let title: String
    let description: String
    let lottieName: String
}

// MARK: - Individual Card View

struct NegativeEffectCardView: View {
    let card: NegativeEffectCard
    
    var body: some View {
        VStack(spacing: 24) {
            // Lottie animation (doubled size)
            LottieView(animation: .named(card.lottieName))
                .playing(loopMode: .loop)
                .frame(width: 280, height: 280)
            
            // Title
            Text(card.title)
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            // Description
            Text(card.description)
                .font(.body)
                .foregroundColor(.textPrimary.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

#Preview {
    NegativeEffectsView()
}
