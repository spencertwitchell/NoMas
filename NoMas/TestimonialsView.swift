//
//  TestimonialsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Testimonials View

struct TestimonialsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    private let testimonials = [
        Testimonial(
            name: "Michael R.",
            quote: "I tried quitting dozens of times before finding this app. The structure and daily accountability made all the difference. 90 days clean and I finally feel like myself again.",
            imageName: "testimonial1"
        ),
        Testimonial(
            name: "David K.",
            quote: "My relationship was falling apart because of my addiction. Six months into recovery, my wife says I'm a completely different person. More present, more connected. This app saved my marriage.",
            imageName: "testimonial2"
        ),
        Testimonial(
            name: "James L.",
            quote: "As a college student, I thought everyone watched porn. Learning the science behind addiction opened my eyes. I'm only 45 days in but my focus and confidence are already transforming.",
            imageName: "testimonial3"
        ),
        Testimonial(
            name: "Anonymous",
            quote: "One year free. I never thought I'd say that. The urges still come sometimes, but they're whispers now, not screams. If I can do it, anyone can.",
            imageName: "testimonial4"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background image
            Image("bg67")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                .padding(.bottom, 12)
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title
                        Text("Lo que otros están diciendo")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                        
                        // Subtitle
                        Text("Millones de personas han experimentado una recuperación efectiva al comprometerse a dejar la pornografía,este enfoque promueve una sanación duradera.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                        
                        // Testimonials list
                        VStack(spacing: 16) {
                            ForEach(testimonials, id: \.name) { testimonial in
                                TestimonialCardView(testimonial: testimonial)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                        .padding(.bottom, 120) // Space for button
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            // Continue button (fixed at bottom)
            VStack {
                Spacer()
                
                Button(action: {
                    onboardingState.advance()
                }) {
                    Text("Continuar")
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

// MARK: - Testimonial Model

struct Testimonial {
    let name: String
    let quote: String
    let imageName: String
}

// MARK: - Testimonial Card View

struct TestimonialCardView: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile row
            HStack(spacing: 12) {
                // Profile image
                Image(testimonial.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                // Name
                Text(testimonial.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            // Quote card
            Text("\"\(testimonial.quote)\"")
                .font(.body)
                .foregroundColor(.textPrimary.opacity(0.95))
                .lineSpacing(5)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.12))
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview

#Preview {
    TestimonialsView()
}
