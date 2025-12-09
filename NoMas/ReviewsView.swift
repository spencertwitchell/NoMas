//
//  ReviewsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import StoreKit

// MARK: - Reviews View

struct ReviewsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @Environment(\.requestReview) private var requestReview
    @State private var isRequestingReview = false
    
    private let reviews = [
        AppReview(
            name: "Michael R.",
            text: "I tried quitting dozens of times on my own. This app gave me the structure and accountability I needed. 6 months clean and counting.",
            imageName: "person.circle.fill"
        ),
        AppReview(
            name: "Anonymous",
            text: "I was skeptical at first, but the daily tracking and science-based approach really works. My relationship with my wife has never been better.",
            imageName: "person.circle.fill"
        ),
        AppReview(
            name: "David K.",
            text: "The community aspect is what sets this apart. Knowing others are going through the same struggle made me feel less alone. Highly recommend.",
            imageName: "person.circle.fill"
        ),
        AppReview(
            name: "James L.",
            text: "As someone who struggled since my teens, I never thought I could break free. This app proved me wrong. Best decision I ever made.",
            imageName: "person.circle.fill"
        ),
        AppReview(
            name: "Anonymous",
            text: "The streak tracking is surprisingly motivating. Every day I don't want to break my streak, and before I knew it, I'd gone 90 days.",
            imageName: "person.circle.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(minHeight: 24)
                        
                        // Title
                        Text("Help Others\nFind Freedom")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                            .frame(minHeight: 16)
                        
                        // Stars icon
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.title)
                                    .foregroundStyle(LinearGradient.accent)
                            }
                        }
                        
                        Spacer()
                            .frame(minHeight: 16)
                        
                        // Description
                        VStack(spacing: 8) {
                            Text("By leaving a positive rating, you're helping others struggling with addiction find this app and start their recovery journey.")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Text("We appreciate your support!")
                                .font(.titleSmall)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                            .frame(minHeight: 32)
                        
                        // Reviews list
                        VStack(spacing: 16) {
                            ForEach(reviews) { review in
                                AppReviewCard(review: review)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Bottom padding for floating button
                        Spacer()
                            .frame(minHeight: 120)
                    }
                }
            }
            
            // Floating Continue Button
            VStack {
                Spacer()
                
                Button(action: {
                    if !isRequestingReview {
                        isRequestingReview = true
                        requestReview()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            onboardingState.advance()
                        }
                    }
                }) {
                    Text("Continue")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: -4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .disabled(isRequestingReview)
                .opacity(isRequestingReview ? 0.6 : 1.0)
            }
        }
    }
    
    // MARK: - Review Model
    
    struct AppReview: Identifiable {
        let id = UUID()
        let name: String
        let text: String
        let imageName: String
    }
    
    // MARK: - Review Card
    
    struct AppReviewCard: View {
        let review: AppReview
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Avatar + Name + Stars
                HStack(spacing: 12) {
                    Image(systemName: review.imageName)
                        .font(.system(size: 32))
                        .foregroundColor(.accentGradientStart)
                    
                    Text(review.name)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    // 5 Stars
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.captionSmall)
                                .foregroundStyle(LinearGradient.accent)
                        }
                    }
                }
                
                // Review text
                Text("\"\(review.text)\"")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surfaceBackground)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReviewsView()
}
