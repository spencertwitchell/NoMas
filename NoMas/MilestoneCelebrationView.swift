//
//  MilestoneCelebrationView.swift
//  NoMas
//
//  Created by Claude on 1/7/26.
//

import SwiftUI
import Lottie

// MARK: - Milestone Celebration View

struct MilestoneCelebrationView: View {
    let milestone: Milestone
    let onDismiss: () -> Void
    
    @ObservedObject var userData = UserData.shared
    @State private var showConfetti = false
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.87)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap
                }
            
            // Confetti layer
            if showConfetti {
                ConfettiView(colors: milestone.gradientColors)
                    .ignoresSafeArea()
            }
            
            // Main content
            VStack(spacing: 24) {
                // X button at top left
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                
                // Emblem - positioned higher and larger
                LottieView(animation: .named(milestone.animationName))
                    .playing(loopMode: .loop)
                    .frame(width: 375, height: 375)
                    .scaleEffect(animateContent ? 1 : 0.5)
                    .opacity(animateContent ? 1 : 0)
                
                // Header
                HStack(spacing: 8) {
                    Text("🏆")
                        .font(.system(size: 28))
                    Text("\(milestone.displayName) Unlocked!")
                        .font(.titleLarge)
                        .foregroundColor(.white)
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                .opacity(animateContent ? 1 : 0)
                
                // Caption (milestone description)
                Text(milestone.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(animateContent ? 1 : 0)
                
                // Progress bar section
                VStack(spacing: 12) {
                    HStack {
                        Text(progressFormatted)
                            .font(.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(daysRemaining) \(daysRemaining == 1 ? "day" : "days") left")
                            .font(.captionSmall)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(milestone.gradient)
                                .frame(width: geometry.size.width * CGFloat(progressPercentage), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .opacity(animateContent ? 1 : 0)
                
                Spacer()
                
                // Continue button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.accent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(animateContent ? 1 : 0)
            }
        }
        .onAppear {
            // Trigger animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
            
            // Start confetti slightly delayed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var daysRemaining: Int {
        guard let date = userData.projectedRecoveryDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(days, 0)
    }
    
    var progressPercentage: Double {
        guard userData.totalRecoveryDays > 0 else { return 0 }
        let progress = Double(userData.daysSinceRelapse) / Double(userData.totalRecoveryDays)
        return min(max(progress, 0), 1)
    }
    
    var progressFormatted: String {
        let percentage = Int(progressPercentage * 100)
        return "\(percentage)% Complete"
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    let colors: [Color]
    
    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, colors: colors)
                }
            }
            .onAppear {
                startConfetti(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startConfetti(in size: CGSize) {
        // Initial burst
        for _ in 0..<50 {
            addParticle(in: size)
        }
        
        // Continue adding particles
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if particles.count < 100 {
                addParticle(in: size)
            }
        }
        
        // Stop after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            timer?.invalidate()
        }
    }
    
    private func addParticle(in size: CGSize) {
        let particle = ConfettiParticle(
            id: UUID(),
            x: CGFloat.random(in: 0...size.width),
            y: -20,
            rotation: Double.random(in: 0...360),
            scale: CGFloat.random(in: 0.5...1.2),
            colorIndex: Int.random(in: 0..<max(colors.count, 1)),
            speed: CGFloat.random(in: 3...8),
            wobble: CGFloat.random(in: -3...3)
        )
        particles.append(particle)
    }
}

// MARK: - Confetti Particle Model

struct ConfettiParticle: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    var scale: CGFloat
    var colorIndex: Int
    var speed: CGFloat
    var wobble: CGFloat
}

// MARK: - Confetti Piece View

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let colors: [Color]
    
    @State private var currentY: CGFloat = -20
    @State private var currentX: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1
    
    var color: Color {
        guard !colors.isEmpty else { return .white }
        return colors[particle.colorIndex % colors.count]
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 8 * particle.scale, height: 12 * particle.scale)
            .rotationEffect(.degrees(currentRotation))
            .position(x: currentX, y: currentY)
            .opacity(opacity)
            .onAppear {
                currentX = particle.x
                currentY = particle.y
                currentRotation = particle.rotation
                
                withAnimation(.linear(duration: 4)) {
                    currentY = UIScreen.main.bounds.height + 50
                    currentX = particle.x + (particle.wobble * 50)
                    currentRotation = particle.rotation + 360 * 3
                }
                
                withAnimation(.linear(duration: 4).delay(2)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview("Milestone Celebration - Silver") {
    MilestoneCelebrationView(milestone: .silver, onDismiss: {})
}

#Preview("Milestone Celebration - Diamond") {
    MilestoneCelebrationView(milestone: .diamond, onDismiss: {})
}

#Preview("Milestone Celebration - Grandmaster") {
    MilestoneCelebrationView(milestone: .grandmaster, onDismiss: {})
}
