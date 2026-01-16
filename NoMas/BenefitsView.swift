//
//  BenefitsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie

// MARK: - Benefits Colors (for positive content screens)

extension Color {
    static let benefitsGradientStart = Color(hex: "0A3A1A")
    static let benefitsGradientEnd = Color(hex: "156B3A")
}

extension LinearGradient {
    static let benefits = LinearGradient(
        gradient: Gradient(colors: [Color.benefitsGradientStart, Color.benefitsGradientEnd]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Benefits View

struct BenefitsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @State private var currentPage = 0
    
    private let cards = [
        BenefitCard(
            title: "Reclama Tu\nClaridad Mental",
            description: "Sin la niebla de la adicción, tu mente se vuelve más aguda. La concentración mejora, la creatividad vuelve y pensarás más claramente que en años.",
            lottieName: "clarityyy"
        ),
        BenefitCard(
            title: "Restaura La\nIntimidad Real",
            description: "A medida que tu cerebro se reinicia, la conexión genuina vuelve a ser posible. Experimentarás relaciones más profundas y satisfactorias.",
            lottieName: "resto"
        ),
        BenefitCard(
            title: "Aumenta Tu\nConfianza",
            description: "Cada día de recuperación demuestra que tienes el control. Ese dominio personal se refleja en todas las áreas de tu vida: trabajo, relaciones y metas personales.",
            lottieName: "confidente"
        ),
        BenefitCard(
            title: "Recupera Tu\nTiempo Y Energía",
            description: "Las horas que antes dedicabas a la pornografía se convierten en horas para crecer. Te sorprenderá lo que logras al redirigir esa energía.",
            lottieName: "timetyshi"
        ),
        BenefitCard(
            title: "Libérate\nDefinitivamente",
            description: "No se trata de fuerza de voluntad, sino de reconfigurar tu cerebro. Con el enfoque correcto, es posible lograr una libertad duradera.",
            lottieName: "fogood"
        )
    ]

    
    var body: some View {
        ZStack {
            // Dark green gradient background
            LinearGradient.benefits
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
                        BenefitCardView(card: cards[index])
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
                
                // Continue button
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
                        .foregroundColor(.benefitsGradientEnd)
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

struct BenefitCard {
    let title: String
    let description: String
    let lottieName: String
}

// MARK: - Individual Card View

struct BenefitCardView: View {
    let card: BenefitCard
    
    var body: some View {
        VStack(spacing: 24) {
            // Lottie animation (larger size)
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
    BenefitsView()
}
