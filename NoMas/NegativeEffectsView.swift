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
    static let warningGradientStart = Color(hex: "991717")
    static let warningGradientEnd = Color(hex: "D32121")
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
            title: "Pornography Rewires Your Brain",
            description: "Repeated exposure hijacks your brain's reward system, creating neural pathways that demand increasingly extreme content to feel the same dopamine rush.",
            lottieName: "Heart_Blue"
        ),
        NegativeEffectCard(
            title: "It Damages Real Intimacy",
            description: "Pornography creates unrealistic expectations and desensitizes you to real human connection, making genuine intimacy feel less satisfying over time.",
            lottieName: "Heart_Blue"
        ),
        NegativeEffectCard(
            title: "Each Relapse Deepens the Rut",
            description: "Every time you give in, you strengthen the addictive pathways in your brain. It's not about willpower—it's about breaking the cycle before it breaks you.",
            lottieName: "Heart_Blue"
        ),
        NegativeEffectCard(
            title: "Recovery Requires Distance",
            description: "Just like any addiction, healing requires complete abstinence. Your brain needs time without stimulation to rebuild healthy neural connections.",
            lottieName: "Heart_Blue"
        )
    ]
    
    var body: some View {
        ZStack {
            // Warning gradient background
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
                
                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        NegativeEffectCardView(card: cards[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.textPrimary : Color.textPrimary.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.vertical, 20)
                
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
                    Text("Continue")
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
        VStack(spacing: 0) {
            Spacer()
            
            // Lottie animation
            LottieView(animation: .named(card.lottieName))
                .playing(loopMode: .loop)
                .frame(maxWidth: 250, maxHeight: 180)
            
            Spacer()
                .frame(minHeight: 32)
            
            // Title
            Text(card.title)
                .font(.titleLarge)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
                .frame(minHeight: 20)
            
            // Description
            Text(card.description)
                .font(.body)
                .foregroundColor(.textPrimary.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    NegativeEffectsView()
}
