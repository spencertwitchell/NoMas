//
//  ScienceView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Science View

struct ScienceView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @State private var barOffset1: CGFloat = 50
    @State private var barOffset2: CGFloat = 180
    
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
            
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let barWidth = screenWidth * 0.18
                let barSpacing = screenWidth * 0.08
                let smallBarHeight: CGFloat = 50
                let largeBarHeight: CGFloat = 180
                
                VStack(spacing: 0) {
                    // Header
                    OnboardingHeader(
                        showBackButton: true,
                        onBack: { onboardingState.goBack() }
                    )
                    
                    Spacer()
                    
                    // Content group (chart, title, description)
                    VStack(spacing: 24) {
                        // Chart section (now first)
                        VStack(spacing: 0) {
                            // Chart Title
                            Text("Recovery Timeframe")
                                .font(.titleSmall)
                                .foregroundColor(.textPrimary)
                                .padding(.bottom, 12)
                            
                            // Animated Chart
                            VStack(spacing: 0) {
                                HStack(alignment: .bottom, spacing: barSpacing) {
                                    // Moderation bar (short)
                                    VStack(spacing: 8) {
                                        ZStack(alignment: .bottom) {
                                            Rectangle()
                                                .fill(Color.white.opacity(0.3))
                                                .frame(width: barWidth, height: smallBarHeight)
                                                .cornerRadius(8)
                                                .offset(y: barOffset1)
                                        }
                                        .frame(height: smallBarHeight)
                                        .clipped()
                                    }
                                    
                                    // Full quit bar (tall)
                                    VStack(spacing: 8) {
                                        ZStack(alignment: .bottom) {
                                            Rectangle()
                                                .fill(LinearGradient.accentVertical)
                                                .frame(width: barWidth, height: largeBarHeight)
                                                .cornerRadius(8)
                                                .offset(y: barOffset2)
                                        }
                                        .frame(height: largeBarHeight)
                                        .clipped()
                                    }
                                }
                                .padding(.leading, 30)
                                .overlay(
                                    GeometryReader { geo in
                                        let yAxisX: CGFloat = 20
                                        let axisBottom: CGFloat = largeBarHeight + 8
                                        let xAxisEnd = 30 + barWidth + barSpacing + barWidth + 5
                                        
                                        Path { path in
                                            // Y axis
                                            path.move(to: CGPoint(x: yAxisX, y: 8))
                                            path.addLine(to: CGPoint(x: yAxisX, y: axisBottom))
                                            
                                            // X axis
                                            path.move(to: CGPoint(x: yAxisX, y: axisBottom))
                                            path.addLine(to: CGPoint(x: xAxisEnd, y: axisBottom))
                                        }
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                    }
                                )
                                
                                // X-axis labels
                                HStack(alignment: .top, spacing: barSpacing) {
                                    Text("Moderation")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                        .frame(width: barWidth)
                                    
                                    Text("Full Quit")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                        .frame(width: barWidth)
                                }
                                .padding(.leading, 30)
                                .padding(.top, 12)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Title
                        Text("It's Not A Trend—\nIt's Proven By Science")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Description
                        Text("Studies show people who commit to quitting pornography recover substantially faster than those who try to moderate.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: {
                        onboardingState.advance()
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
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                barOffset1 = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 1.0)) {
                    barOffset2 = 0
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScienceView()
}
