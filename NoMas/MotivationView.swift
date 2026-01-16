//
//  MotivationView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI
import Lottie

// MARK: - Motivation View

struct MotivationView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    
    // Timing configuration
    private let charDelay: TimeInterval = 0.05
    private let linePause: TimeInterval = 0.10
    private let groupPause: TimeInterval = 1.50
    private let finalPause: TimeInterval = 1.00
    
    @State private var currentGroupIndex = 0
    @State private var currentLineIndex = 0
    @State private var revealedCharacterCount = 0
    @State private var finalSnapshot: [DisplayLine]? = nil
    @State private var showPlanCard = false
    
    // MARK: - Personalized Name
    
    private var displayName: String {
        userData.displayName.isEmpty ? "Amigo" : userData.displayName
    }
    
    // MARK: - Line Groups
    
    private var lineGroups: [[String]] {
        [
            ["Hola \(displayName)"],
            ["Bienvenido a NoMás, tu", "camino hacia la libertad."],
            ["En base a tus respuestas,", "hemos creado un plan", "solo para ti."],
            ["Está diseñado para", "ayudarte a dejar la", "pornografía para siempre."],
            ["Ahora es momento de", "invertir en ti."]
        ]
    }
    
    // MARK: - Display Line Model
    
    struct DisplayLine: Identifiable, Equatable {
        let id = UUID()
        let text: String
    }
    
    // MARK: - Displayed Lines
    
    private var displayedLines: [DisplayLine] {
        if let snap = finalSnapshot { return snap }
        guard currentGroupIndex < lineGroups.count else { return [] }
        
        var out: [DisplayLine] = []
        
        // Completed lines in current group
        for i in 0..<currentLineIndex {
            let full = lineGroups[currentGroupIndex][i]
            out.append(DisplayLine(text: full))
        }
        
        // Partially revealed current line
        if currentLineIndex < lineGroups[currentGroupIndex].count {
            let target = lineGroups[currentGroupIndex][currentLineIndex]
            let endIndex = target.index(target.startIndex, offsetBy: min(revealedCharacterCount, target.count))
            let partial = String(target[..<endIndex])
            out.append(DisplayLine(text: partial))
        }
        
        return out
    }
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg4")
            
            // Dark overlay for text readability
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Animated text at top
                VStack(spacing: 8) {
                    ForEach(displayedLines) { line in
                        Text(line.text)
                            .font(.titleCustom(size: 26))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 32)
                .padding(.top, 100)
                
                Spacer()
            }
            
            // Custom Plan Card - positioned independently
            VStack {
                Spacer()
                
                if showPlanCard {
                    CustomPlanCard(
                        displayName: displayName,
                        milestone: userData.currentMilestone,
                        daysInApp: userData.daysInApp,
                        dependencyScore: userData.dependencyScore,
                        projectedRecoveryDate: userData.projectedRecoveryDate,
                        joinDate: userData.appJoinDate
                    )
                    .padding(.horizontal, 24)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                
                Spacer()
            }
        }
        .onAppear {
            startTypingAnimation()
        }
        .onChange(of: currentGroupIndex) { oldValue, newValue in
            // Trigger card animation when 3rd group starts
            if newValue == 2 && !showPlanCard {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showPlanCard = true
                    }
                }
            }
        }
    }
    
    // MARK: - Typing Animation
    
    private func startTypingAnimation() {
        guard currentGroupIndex < lineGroups.count else {
            if finalSnapshot == nil {
                finalSnapshot = lastFullScreenSnapshot()
            }
            triggerPaywallAndComplete()
            return
        }
        
        guard currentLineIndex < lineGroups[currentGroupIndex].count else {
            DispatchQueue.main.asyncAfter(deadline: .now() + groupPause) {
                currentGroupIndex += 1
                currentLineIndex = 0
                revealedCharacterCount = 0
                startTypingAnimation()
            }
            return
        }
        
        let currentLine = lineGroups[currentGroupIndex][currentLineIndex]
        revealedCharacterCount = 0
        
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        let total = currentLine.count
        
        func typeNextCharacter(_ i: Int) {
            guard i < total else {
                DispatchQueue.main.asyncAfter(deadline: .now() + linePause) {
                    currentLineIndex += 1
                    revealedCharacterCount = 0
                    startTypingAnimation()
                }
                return
            }
            revealedCharacterCount = i + 1
            haptic.impactOccurred(intensity: 0.35)
            DispatchQueue.main.asyncAfter(deadline: .now() + charDelay) {
                typeNextCharacter(i + 1)
            }
        }
        
        typeNextCharacter(0)
    }
    
    private func lastFullScreenSnapshot() -> [DisplayLine] {
        if currentGroupIndex < lineGroups.count {
            return lineGroups[currentGroupIndex].map {
                DisplayLine(text: $0)
            }
        } else if let last = lineGroups.last {
            return last.map {
                DisplayLine(text: $0)
            }
        } else {
            return []
        }
    }
    
    private func triggerPaywallAndComplete() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if finalSnapshot == nil {
            finalSnapshot = lastFullScreenSnapshot()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + finalPause) {
            // TODO: Trigger Superwall paywall here
            // Superwall.shared.register(placement: "onboarding_complete")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onboardingState.advance()
            }
        }
    }
}

// MARK: - Custom Plan Card

struct CustomPlanCard: View {
    let displayName: String
    let milestone: Milestone
    let daysInApp: Int
    let dependencyScore: Double
    let projectedRecoveryDate: Date?
    let joinDate: Date
    
    private var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter.string(from: joinDate)
    }
    
    private var formattedRecoveryDate: String {
        guard let date = projectedRecoveryDate else { return "TBD" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(spacing: 16) {
                // Rank Section: Animation on left, text on right
                HStack(spacing: 16) {
                    // Lottie Animation
                    LottieView(animation: .named(milestone.animationName))
                        .playing(loopMode: .loop)
                        .animationSpeed(0.67)
                        .frame(width: 70, height: 70)
                        .scaleEffect(1.2)
                    
                    // Current Rank Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rango Actual")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(milestone.displayName)
                            .font(.titleMedium)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        
                        Text(milestone.title)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal, 8)
                
                // Stats Rows
                VStack(spacing: 12) {
                    PlanStatRow(label: "Días en la App", value: "\(daysInApp)")
                    PlanStatRow(label: "Puntuación de Dependencia", value: "\(Int(dependencyScore))%")
                    if projectedRecoveryDate != nil {
                        PlanStatRow(label: "Recuperación Proyectada", value: formattedRecoveryDate)
                    }
                }
            }
            .padding(20)
            
            // Footer Section (overlay on top of gradient)
            HStack {
                // Name on left
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nombre")
                        .font(.captionSmall)
                        .foregroundColor(.white.opacity(0.7))
                    Text(displayName)
                        .font(.bodySmall)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                // Free Since on right
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Libre desde")
                        .font(.captionSmall)
                        .foregroundColor(.white.opacity(0.7))
                    Text(formattedJoinDate)
                        .font(.bodySmall)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.black.opacity(0.25))
        }
        .background(
            ZStack {
                // Gradient layer (extends full height)
                RoundedRectangle(cornerRadius: 16)
                    .fill(milestone.gradient)
                
                // Dark overlay for readability
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.35))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            // 3pt gradient border
            RoundedRectangle(cornerRadius: 16)
                .stroke(milestone.gradient, lineWidth: 3)
        )
        .shadow(color: Color.accentGradientStart.opacity(0.5), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Plan Stat Row

struct PlanStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    MotivationView()
}
