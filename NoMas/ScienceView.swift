//
//  ScienceView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


//
//  ScienceView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Positive/Hope Colors (for light-themed screens)

extension Color {
    static let hopeGradientStart = Color(hex: "E8D5F2")  // Light purple
    static let hopeGradientEnd = Color(hex: "D4C4E0")    // Slightly darker purple
}

extension LinearGradient {
    static let hope = LinearGradient(
        gradient: Gradient(colors: [Color.hopeGradientStart, Color.hopeGradientEnd]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Science View

struct ScienceView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @State private var barOffset1: CGFloat = 50
    @State private var barOffset2: CGFloat = 180
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let barWidth = screenWidth * 0.18
            let barSpacing = screenWidth * 0.08
            let smallBarHeight: CGFloat = 50
            let largeBarHeight: CGFloat = 180
            
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
                    
                    Spacer()
                    
                    // Title
                    Text("It's Not A Trend—\nIt's Proven By Science")
                        .font(.titleLarge)
                        .foregroundColor(.accentGradientStart)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(minHeight: 16)
                    
                    // Description
                    Text("Studies show people who commit to quitting pornography recover substantially faster than those who try to moderate.")
                        .font(.body)
                        .foregroundColor(.accentGradientEnd)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                        .frame(minHeight: 24)
                    
                    // Chart Title
                    Text("Recovery Timeframe")
                        .font(.titleSmall)
                        .foregroundColor(.accentGradientStart)
                        .padding(.bottom, 8)
                    
                    // Animated Chart
                    VStack(spacing: 0) {
                        HStack(alignment: .bottom, spacing: barSpacing) {
                            // Moderation bar (short)
                            VStack(spacing: 8) {
                                ZStack(alignment: .bottom) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
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
                                .stroke(Color.accentGradientStart.opacity(0.4), lineWidth: 2)
                            }
                        )
                        
                        // X-axis labels
                        HStack(alignment: .top, spacing: barSpacing) {
                            Text("Moderation")
                                .font(.caption)
                                .foregroundColor(.accentGradientStart)
                                .frame(width: barWidth)
                            
                            Text("Full Quit")
                                .font(.caption)
                                .foregroundColor(.accentGradientStart)
                                .frame(width: barWidth)
                        }
                        .padding(.leading, 30)
                        .padding(.top, 12)
                    }
                    .frame(maxWidth: .infinity)
                    
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
}

// MARK: - Dark Header (for light backgrounds)

struct OnboardingHeaderDark: View {
    var showBackButton: Bool = true
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            if showBackButton, let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.titleSmall)
                        .foregroundColor(.accentGradientStart)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
            
            Spacer()
            
            // Dark logo variant (you may need to add this asset)
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
    }
}

// MARK: - Preview

#Preview {
    ScienceView()
}