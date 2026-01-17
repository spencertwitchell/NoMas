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
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let barWidth = screenWidth * 0.18
            let barSpacing = screenWidth * 0.08
            let smallBarHeight: CGFloat = 50
            let largeBarHeight: CGFloat = 180
            
            ZStack {
                // Background image - constrained to screen bounds
                Image("bg67")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                // Dark overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                // Content constrained to screen size
                VStack(spacing: 0) {
                    // Header anchored at top
                    OnboardingHeader(
                        showBackButton: true,
                        onBack: { onboardingState.goBack() }
                    )
                    .padding(.top, 60)
                    
                    Spacer() // Flexible space between header and content
                    
                    // Content group (chart, title, description) - centered
                    VStack(spacing: 24) {
                        // Chart section
                        VStack(spacing: 0) {
                            // Chart Title
                            Text("Tiempo de Recuperación")
                                .font(.titleMedium)
                                .foregroundColor(.textPrimary)
                                .padding(.bottom, 24)
                            
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
                                    Text("Moderación")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                        .frame(width: barWidth)
                                    
                                    Text("Abstinencia")
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
                        Text("No es una moda—\nestá comprobado por la ciencia")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Description
                        Text("Los estudios muestran que dejar la pornografía permite una recuperación más rápida que solo moderarla.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer() // Flexible space between content and button
                    
                    // Continue button anchored at bottom
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
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
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
