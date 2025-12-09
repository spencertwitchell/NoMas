//
//  MotivationView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//


//
//  MotivationView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

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
    
    // MARK: - Personalized Date
    
    private var personalizedDate: String {
        guard let date = userData.projectedRecoveryDate else {
            return "a few months"
        }
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        let base = formatter.string(from: date)
        let year = calendar.component(.year, from: date)
        return "\(base)\(suffix), \(year)"
    }
    
    // MARK: - Line Groups
    
    private var lineGroups: [[String]] {
        [
            ["Based on your answers,", "we've designed a", "personalized recovery", "plan just for you..."],
            ["Urges will come.", "With the right tools", "and accountability,", "you'll stay strong..."],
            ["If you commit,", "you could be free by:", personalizedDate],
            ["NoMas isn't just", "about quitting porn.", "It's about reclaiming", "your life..."],
            ["Now it's time to", "invest in yourself..."]
        ]
    }
    
    // MARK: - Display Line Model
    
    struct DisplayLine: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let isChip: Bool
    }
    
    // MARK: - Displayed Lines
    
    private var displayedLines: [DisplayLine] {
        if let snap = finalSnapshot { return snap }
        guard currentGroupIndex < lineGroups.count else { return [] }
        
        var out: [DisplayLine] = []
        
        // Completed lines in current group
        for i in 0..<currentLineIndex {
            let full = lineGroups[currentGroupIndex][i]
            out.append(DisplayLine(text: full, isChip: (full == personalizedDate)))
        }
        
        // Partially revealed current line
        if currentLineIndex < lineGroups[currentGroupIndex].count {
            let target = lineGroups[currentGroupIndex][currentLineIndex]
            let endIndex = target.index(target.startIndex, offsetBy: min(revealedCharacterCount, target.count))
            let partial = String(target[..<endIndex])
            out.append(DisplayLine(text: partial, isChip: (target == personalizedDate)))
        }
        
        return out
    }
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Light overlay
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(minHeight: 120)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(displayedLines) { line in
                        if line.isChip {
                            // Date chip with gradient background
                            if !line.text.isEmpty {
                                Text(line.text)
                                    .font(.titleMedium)
                                    .foregroundColor(.textPrimary)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(LinearGradient.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        } else {
                            Text(line.text)
                                .font(.titleMedium)
                                .foregroundColor(.accentGradientStart)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .onAppear {
            startTypingAnimation()
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
                DisplayLine(text: $0, isChip: ($0 == personalizedDate))
            }
        } else if let last = lineGroups.last {
            return last.map {
                DisplayLine(text: $0, isChip: ($0 == personalizedDate))
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

// MARK: - Preview

#Preview {
    MotivationView()
}