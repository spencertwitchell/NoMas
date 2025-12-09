//
//  BenefitsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


//
//  BenefitsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie

// MARK: - Benefits View

struct BenefitsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @State private var currentPage = 0
    
    private let cards = [
        BenefitCard(
            title: "Reclaim Your\nMental Clarity",
            description: "Without the fog of addiction, your mind becomes sharper. Focus improves, creativity returns, and you'll think more clearly than you have in years.",
            lottieName: "Heart_Blue"
        ),
        BenefitCard(
            title: "Restore Real\nIntimacy",
            description: "As your brain resets, genuine connection becomes possible again. You'll experience deeper, more fulfilling relationships.",
            lottieName: "Heart_Blue"
        ),
        BenefitCard(
            title: "Boost Your\nConfidence",
            description: "Every day of recovery proves you're in control. That self-mastery spills into every area of your life—work, relationships, and personal goals.",
            lottieName: "Heart_Blue"
        ),
        BenefitCard(
            title: "Regain Your\nTime & Energy",
            description: "Hours spent on pornography become hours for growth. You'll be amazed at what you accomplish when you redirect that energy.",
            lottieName: "Heart_Blue"
        ),
        BenefitCard(
            title: "Break Free\nFor Good",
            description: "This isn't about willpower—it's about rewiring your brain. With the right approach, lasting freedom is absolutely possible.",
            lottieName: "Heart_Blue"
        )
    ]
    
    var body: some View {
        ZStack {
            // Light gradient background
            LinearGradient.hope
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeaderDark(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                
                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        BenefitCardView(card: cards[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<cards.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.accentGradientStart : Color.gray.opacity(0.4))
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
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
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
        VStack(spacing: 0) {
            Spacer()
            
            // Lottie animation
            LottieView(animation: .named(card.lottieName))
                .playing(loopMode: .loop)
                .frame(maxWidth: 220, maxHeight: 180)
            
            Spacer()
                .frame(minHeight: 32)
            
            // Title
            Text(card.title)
                .font(.titleLarge)
                .foregroundColor(.accentGradientStart)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
                .frame(minHeight: 20)
            
            // Description
            Text(card.description)
                .font(.body)
                .foregroundColor(.accentGradientEnd)
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
    BenefitsView()
}