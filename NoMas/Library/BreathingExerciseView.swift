//
//  BreathingExerciseView.swift
//  NoMas
//
//  Breathing exercise with animated heart visualization
//

import SwiftUI
import Lottie

struct BreathingExerciseView: View {
    @Environment(\.dismiss) var dismiss
    
    // Intro state
    @State private var showingIntro = true
    @State private var introTextOpacity: Double = 0
    
    // Breathing state
    @State private var phase: BreathingPhase = .inhale
    @State private var countdown: Int = 6
    @State private var scale: CGFloat = 0.0
    @State private var opacity: Double = 0.0
    @State private var timer: Timer?
    
    enum BreathingPhase {
        case inhale   // 6s - heart grows
        case hold     // 16s - lottie animation pumps
        case exhale   // 10s - heart shrinks
        case pause    // 6s - heart stays small
        
        var duration: Int {
            switch self {
            case .inhale: return 6
            case .hold: return 16
            case .exhale: return 10
            case .pause: return 6
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "Breathe in while the heart grows..."
            case .hold: return "Hold in your breath while it pumps..."
            case .exhale: return "Exhale as the heart gently fades..."
            case .pause: return "Pause gently, no rush to breathe in."
            }
        }
        
        var next: BreathingPhase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .pause
            case .pause: return .inhale
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Video Background
                LoopingVideoBackground(videoName: "bg flow")
                
                // Dark overlay for readability
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                if showingIntro {
                    introView
                } else {
                    breathingView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Breathing Exercise")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
    
    // MARK: - Intro View
    
    private var introView: some View {
        VStack {
            Spacer()
            
            Text("Calm your urges with a breathing exercise...")
                .font(.titleMedium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(introTextOpacity)
            
            Spacer()
        }
        .onAppear {
            // Fade in text
            withAnimation(.easeIn(duration: 1.0)) {
                introTextOpacity = 1.0
            }
            
            // Fade out text after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    introTextOpacity = 0.0
                }
            }
            
            // Switch to breathing view after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showingIntro = false
                // Start breathing cycle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    startBreathingCycle()
                }
            }
        }
    }
    
    // MARK: - Breathing View
    
    private var breathingView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            
            // Instruction text (fixed position at top)
            Text(phase.instruction)
                .font(.titleSmall)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)
                .frame(height: 100, alignment: .center)
            
            Spacer()
                .frame(height: 2)
            
            // Heart visualization (fixed container)
            ZStack {
                if phase == .hold {
                    // Lottie animation during hold phase
                    LottieView(animation: .named("Heart_White"))
                        .playing(loopMode: .loop)
                        .resizable()
                        .frame(width: 480, height: 480)
                        .transition(.opacity)
                } else if phase != .pause {
                    // Static image with scale animation for inhale/exhale
                    Image("whiteheart")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .transition(.opacity)
                }
            }
            .frame(width: 480, height: 480)
            .clipped()
            
            Spacer()
        }
    }
    
    // MARK: - Breathing Cycle
    
    private func startBreathingCycle() {
        // Start with inhale phase
        animatePhase()
        
        // Countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                // Move to next phase
                withAnimation(.easeInOut(duration: 0.5)) {
                    phase = phase.next
                }
                countdown = phase.duration
                animatePhase()
            }
        }
    }
    
    private func animatePhase() {
        switch phase {
        case .inhale:
            // Grow from nothing to large
            withAnimation(.easeInOut(duration: Double(phase.duration))) {
                scale = 1.15
                opacity = 1.0
            }
            
        case .hold:
            // Keep at full size, Lottie plays
            scale = 1.15
            opacity = 1.0
            
        case .exhale:
            // Shrink to nothing and fade completely
            withAnimation(.easeInOut(duration: Double(phase.duration))) {
                scale = 0.0
                opacity = 0.0
            }
            
        case .pause:
            // Stay hidden (nothing shows)
            scale = 0.0
            opacity = 0.0
        }
    }
}

// MARK: - Preview

#Preview {
    BreathingExerciseView()
}
