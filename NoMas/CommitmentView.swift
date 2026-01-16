//
//  CommitmentView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI

// MARK: - Commitment View

struct CommitmentView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @State private var currentPath = Path()
    @State private var paths: [Path] = []
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                
                Spacer()
                
                // Content group
                VStack(spacing: 20) {
                    // Title
                    Text("Firma Tu Compromiso")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 48)
                    
                    // Subtitle
                    Text("Hazte una promesa a ti mismo: comprométete con tu proceso de recuperación, un día a la vez.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        .padding(.top, -8)
                    
                    
                    // Signature section
                    VStack(alignment: .leading, spacing: 12) {
                        // Signature label
                        Text("Firma")
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)
                        
                        // Signature Canvas
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.textPrimary.opacity(0.95))
                            
                            // Drawing canvas
                            Canvas { context, size in
                                for path in paths {
                                    context.stroke(
                                        path,
                                        with: .color(.black),
                                        lineWidth: 3
                                    )
                                }
                                
                                context.stroke(
                                    currentPath,
                                    with: .color(.black),
                                    lineWidth: 3
                                )
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let point = value.location
                                        if currentPath.isEmpty {
                                            currentPath.move(to: point)
                                        } else {
                                            currentPath.addLine(to: point)
                                        }
                                    }
                                    .onEnded { _ in
                                        paths.append(currentPath)
                                        currentPath = Path()
                                    }
                            )
                        }
                        .frame(height: 180)
                        
                        // Clear button
                        Button(action: {
                            paths.removeAll()
                            currentPath = Path()
                        }) {
                            Text("Borrar")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                
                Spacer()
                
                // Finish button
                Button(action: {
                    onboardingState.advance()
                }) {
                    Text("Me Comprometo")
                        .font(.button)
                        .foregroundColor(.accentGradientStart)
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

// MARK: - Preview

#Preview {
    CommitmentView()
}
