//
//  TestimonialsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


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
    
    @State private var currentPage = 0
    
    private let testimonials = [
        Testimonial(
            name: "Michael R.",
            age: 28,
            streakDays: 90,
            quote: "I tried quitting dozens of times before finding this app. The structure and daily accountability made all the difference. 90 days clean and I finally feel like myself again.",
            imageName: "person.circle.fill"
        ),
        Testimonial(
            name: "David K.",
            age: 34,
            streakDays: 180,
            quote: "My relationship was falling apart because of my addiction. Six months into recovery, my wife says I'm a completely different person. More present, more connected. This app saved my marriage.",
            imageName: "person.circle.fill"
        ),
        Testimonial(
            name: "James L.",
            age: 22,
            streakDays: 45,
            quote: "As a college student, I thought everyone watched porn. Learning the science behind addiction opened my eyes. I'm only 45 days in but my focus and confidence are already transforming.",
            imageName: "person.circle.fill"
        ),
        Testimonial(
            name: "Anonymous",
            age: 41,
            streakDays: 365,
            quote: "One year free. I never thought I'd say that. The urges still come sometimes, but they're whispers now, not screams. If I can do it, anyone can.",
            imageName: "person.circle.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                
                Spacer()
                    .frame(minHeight: 16)
                
                // Title
                Text("Real Stories of\nRecovery")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<testimonials.count, id: \.self) { index in
                        TestimonialCardView(testimonial: testimonials[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<testimonials.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.accentGradientStart : Color.textPrimary.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.vertical, 20)
                
                // Continue button
                Button(action: {
                    if currentPage < testimonials.count - 1 {
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

// MARK: - Testimonial Model

struct Testimonial {
    let name: String
    let age: Int
    let streakDays: Int
    let quote: String
    let imageName: String
    
    var streakText: String {
        if streakDays >= 365 {
            return "\(streakDays / 365) year\(streakDays >= 730 ? "s" : "") clean"
        } else if streakDays >= 30 {
            return "\(streakDays / 30) month\(streakDays >= 60 ? "s" : "") clean"
        } else {
            return "\(streakDays) days clean"
        }
    }
}

// MARK: - Testimonial Card View

struct TestimonialCardView: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Profile section
            VStack(spacing: 12) {
                // Avatar
                Image(systemName: testimonial.imageName)
                    .font(.system(size: 60))
                    .foregroundColor(.accentGradientStart)
                
                // Name and age
                Text("\(testimonial.name), \(testimonial.age)")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                
                // Streak badge
                Text(testimonial.streakText)
                    .font(.caption)
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(LinearGradient.accent)
                    .cornerRadius(20)
            }
            
            Spacer()
                .frame(minHeight: 24)
            
            // Quote
            Text("\"\(testimonial.quote)\"")
                .font(.body)
                .foregroundColor(.textSecondary)
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
    TestimonialsView()
}