//
//  MightBreakAnimationView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  MightBreakAnimationView.swift
//  NoMas
//
//  Animation sequence for the "I Might Break" flow with encouraging messages
//

import SwiftUI

struct MightBreakAnimationView: View {
    let onComplete: () -> Void
    
    @State private var currentPageIndex = 0
    @State private var revealedCharacterCount = 0
    @State private var fadeOut = false
    @State private var isAnimationActive = true
    
    // Animation speed control
    // 0.05 = fast, 0.1 = slower, 0.08 = medium
    let characterDelay: Double = 0.08
    
    let pages: [String] = [
        "Feeling the urge doesn't mean you're failing. It means you're human...",
        "This moment of weakness is temporary. Your commitment to change is not...",
        "Every urge you resist rewires your brain. You're building strength right now..."
    ]
    
    var currentText: String {
        guard currentPageIndex < pages.count else {
            // Show last page's full text
            return pages[pages.count - 1]
        }
        let text = pages[currentPageIndex]
        let endIndex = text.index(text.startIndex, offsetBy: min(revealedCharacterCount, text.count))
        return String(text[..<endIndex])
    }
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay for better text readability
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text(currentText)
                    .font(.titleLarge)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 40)
                    .frame(maxWidth: .infinity)
                    .opacity(fadeOut ? 0 : 1)
                
                Spacer()
            }
        }
        .onAppear {
            isAnimationActive = true
            startTypingAnimation()
        }
        .onDisappear {
            isAnimationActive = false
        }
    }
    
    func startTypingAnimation() {
        guard isAnimationActive else { return }
        
        guard currentPageIndex < pages.count else {
            // All pages done - fade and transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                guard isAnimationActive else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    fadeOut = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                    guard isAnimationActive else { return }
                    onComplete()
                }
            }
            return
        }
        
        let currentPage = pages[currentPageIndex]
        revealedCharacterCount = 0
        
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        
        // Type each character
        func typeNextCharacter(index: Int) {
            guard isAnimationActive else { return }
            
            guard index < currentPage.count else {
                // Page complete, wait then move to next
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
                    guard isAnimationActive else { return }
                    currentPageIndex += 1
                    startTypingAnimation()
                }
                return
            }
            
            revealedCharacterCount = index + 1
            haptic.impactOccurred(intensity: 0.4)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + characterDelay) {
                typeNextCharacter(index: index + 1)
            }
        }
        
        typeNextCharacter(index: 0)
    }
}

#Preview {
    MightBreakAnimationView(onComplete: {})
}
