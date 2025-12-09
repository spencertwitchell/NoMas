//
//  CommitmentView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//


//
//  CommitmentView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
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
                
                // Title
                Text("Sign Your Commitment")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                    .frame(minHeight: 12)
                
                // Subtitle
                Text("Make a promise to yourself that you will commit to your recovery journey, one day at a time.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                
                Spacer()
                    .frame(minHeight: 32)
                
                // Signature label
                Text("Draw Your Signature")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                
                Spacer()
                    .frame(minHeight: 12)
                
                // Signature Canvas
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.textPrimary.opacity(0.95))
                    
                    // Signature line hint
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                    }
                    
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
                .frame(maxHeight: 200)
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(minHeight: 12)
                
                // Clear button
                Button(action: {
                    paths.removeAll()
                    currentPath = Path()
                }) {
                    Text("Clear")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Finish button
                Button(action: {
                    onboardingState.advance()
                }) {
                    Text("I Commit")
                        .font(.button)
                        .foregroundColor(.accentGradientStart)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.textPrimary)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: -4)
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