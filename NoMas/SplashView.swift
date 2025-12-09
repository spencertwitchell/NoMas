//
//  SplashView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//


//
//  SplashView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI

// MARK: - Splash View

struct SplashView: View {
    @Binding var isComplete: Bool
    
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    
    // Animation states
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    
    // Minimum display time to ensure smooth branding experience
    private let minimumDisplayTime: TimeInterval = 2.0
    
    var body: some View {
        ZStack {
            // Background gradient
            AppBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo with glow effect
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.accentGradientStart.opacity(0.5),
                                    Color.accentGradientStart.opacity(0)
                                ]),
                                center: .center,
                                startRadius: 40,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .opacity(glowOpacity)
                    
                    // Logo
                    Image("nomaslogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                Spacer()
                    .frame(height: 24)
                
                // Tagline
                Text("Break Free. Reclaim Your Life.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .opacity(taglineOpacity)
                
                Spacer()
                
                // Loading indicator (subtle)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.5)))
                    .scaleEffect(0.8)
                    .opacity(taglineOpacity)
                
                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            startAnimations()
            loadDataAndComplete()
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Logo fade in and scale
        withAnimation(.easeOut(duration: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Glow pulse
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            glowOpacity = 1.0
        }
        
        // Tagline fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            taglineOpacity = 1.0
        }
    }
    
    // MARK: - Data Loading
    
    private func loadDataAndComplete() {
        let startTime = Date()
        
        Task {
            // Load user data from Supabase
            await userData.initializeFromSupabase()
            
            // Check auth status
            await authManager.checkAuthStatus()
            
            // Ensure minimum display time for branding
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < minimumDisplayTime {
                try? await Task.sleep(for: .seconds(minimumDisplayTime - elapsed))
            }
            
            // Complete splash
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isComplete = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(isComplete: .constant(false))
}