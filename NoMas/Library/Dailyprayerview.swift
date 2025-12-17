//
//  DailyPrayerView.swift
//  NoMas
//
//  Daily prayer/verse view with animated text and video background
//

import SwiftUI
import Supabase

// MARK: - Prayer Model

struct Prayer: Identifiable, Codable {
    let id: UUID
    let text: String
    let reference: String  // e.g. "Juan 3:16" or "Salmos 23:1-3"
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case reference
        case isActive = "is_active"
    }
}

// MARK: - Daily Prayer View

struct DailyPrayerView: View {
    @Environment(\.dismiss) var dismiss
    
    // Data
    @State private var prayers: [Prayer] = []
    @State private var shuffledPrayers: [Prayer] = []
    @State private var currentIndex = -1
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showingIntro = true
    
    // Animation
    @State private var revealedCharacterCount = 0
    @State private var isAnimating = false
    @State private var isAnimationActive = true
    @State private var showReference = false  // Controls reference fade-in
    
    var currentPrayer: Prayer? {
        guard !shuffledPrayers.isEmpty, currentIndex >= 0, currentIndex < shuffledPrayers.count else { return nil }
        return shuffledPrayers[currentIndex]
    }
    
    var displayedText: String {
        guard let prayer = currentPrayer else { return "" }
        let endIndex = prayer.text.index(
            prayer.text.startIndex,
            offsetBy: min(revealedCharacterCount, prayer.text.count)
        )
        return String(prayer.text[..<endIndex])
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Video Background
                LoopingVideoBackground(videoName: "bg flow")
                
                // Dark overlay for readability
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let error = loadError {
                    errorView(error)
                } else if showingIntro {
                    introView
                } else if currentPrayer == nil {
                    emptyView
                } else {
                    prayerContentView
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
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await loadPrayers()
        }
        .onDisappear {
            isAnimationActive = false
        }
    }
    
    // MARK: - Intro View
    
    private var introView: some View {
        VStack {
            Spacer()
            
            Text("Let us pray...")
                .font(.titleLarge)
                .foregroundColor(.white)
            
            Spacer()
        }
        .onAppear {
            // Auto-start first prayer after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                showingIntro = false
                currentIndex = 0
                startPrayer()
            }
        }
    }
    
    // MARK: - Prayer Content View
    
    private var prayerContentView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Verse text
            VStack(spacing: 16) {
                Text(displayedText)
                    .font(.titleMedium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(8)
                
                // Bible reference - fades in after text animation
                if let prayer = currentPrayer {
                    Text("— \(prayer.reference)")
                        .font(.bodySmall)
                        .italic()
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(showReference ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: showReference)
                }
            }
            
            Spacer()
            
            // Buttons
            HStack(spacing: 16) {
                // Repeat Button
                Button(action: repeatPrayer) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Repeat")
                            .font(.button)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(LinearGradient.accent)
                    .cornerRadius(25)
                }
                .disabled(isAnimating)
                .opacity(isAnimating ? 0.5 : 1)
                
                // Continue Button
                Button(action: nextPrayer) {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.button)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                }
                .disabled(isAnimating)
                .opacity(isAnimating ? 0.5 : 1)
            }
            .padding(.bottom, 60)
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.7))
            Text("Failed to load verses")
                .font(.titleSmall)
                .foregroundColor(.white)
            Text(error)
                .font(.caption)
                .foregroundColor(.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack {
            Spacer()
            Text("No verses available")
                .font(.titleSmall)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadPrayers() async {
        isLoading = true
        loadError = nil
        
        do {
            let response: [Prayer] = try await supabase
                .from("prayers")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value
            
            prayers = response
            shuffledPrayers = response.shuffled()
            
            print("✅ Loaded \(prayers.count) verses")
            isLoading = false
        } catch {
            print("❌ Failed to load verses: \(error)")
            loadError = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Prayer Control
    
    private func startPrayer() {
        guard let prayer = currentPrayer else { return }
        
        revealedCharacterCount = 0
        isAnimating = true
        isAnimationActive = true
        showReference = false  // Hide reference at start
        
        animateText(prayer.text)
    }
    
    private func animateText(_ text: String) {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        
        func typeNextCharacter(index: Int) {
            guard isAnimationActive else {
                isAnimating = false
                return
            }
            
            guard index < text.count else {
                isAnimating = false
                // Show reference after text animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showReference = true
                }
                return
            }
            
            revealedCharacterCount = index + 1
            haptic.impactOccurred(intensity: 0.3)
            
            // 80ms delay per character
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                typeNextCharacter(index: index + 1)
            }
        }
        
        typeNextCharacter(index: 0)
    }
    
    private func repeatPrayer() {
        startPrayer()
    }
    
    private func nextPrayer() {
        currentIndex += 1
        
        // If we've gone through all, reshuffle
        if currentIndex >= shuffledPrayers.count {
            shuffledPrayers = prayers.shuffled()
            currentIndex = 0
        }
        
        startPrayer()
    }
}

// MARK: - Preview

#Preview {
    DailyPrayerView()
}
