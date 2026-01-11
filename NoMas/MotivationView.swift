//
//  MotivationView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
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
    
    // MARK: - Personalized Name
    
    private var displayName: String {
        userData.displayName.isEmpty ? "Friend" : userData.displayName
    }
    
    // MARK: - Line Groups
    
    private var lineGroups: [[String]] {
        [
            ["Hey \(displayName)"],
            ["Welcome to NoMas,", "your path to freedom."],
            ["Based on your answers,", "we've created a plan", "just for you."],
            ["It's designed to help you", "quit porn forever."],
            ["Now it's time to", "invest in yourself."]
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
            
            VStack(spacing: 8) {
                ForEach(displayedLines) { line in
                    Text(line.text)
                        .font(.titleCustom(size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 32)
            .padding(.top, 100)
            .frame(maxHeight: .infinity, alignment: .top)
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

// MARK: - Preview

#Preview {
    MotivationView()
}
