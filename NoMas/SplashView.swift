//
//  SplashView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/9/25.
//

import SwiftUI

// MARK: - Swipe Reveal Modifier

struct SwipeRevealModifier: ViewModifier {
    let isRevealed: Bool
    let duration: Double
    
    @State private var revealProgress: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geometry in
                    LinearGradient(
                        stops: gradientStops,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            )
            .onChange(of: isRevealed) { _, newValue in
                if newValue {
                    withAnimation(.easeOut(duration: duration)) {
                        revealProgress = 1.2 // Go slightly past 1 to ensure full reveal
                    }
                }
            }
    }
    
    private var gradientStops: [Gradient.Stop] {
        // Ensure stops are always in ascending order
        let edgeStart = max(0, revealProgress - 0.1)
        let edgeEnd = max(edgeStart + 0.01, revealProgress) // Always slightly after edgeStart
        
        return [
            .init(color: .white, location: 0),
            .init(color: .white, location: edgeStart),
            .init(color: .clear, location: edgeEnd),
            .init(color: .clear, location: 1)
        ]
    }
}

extension View {
    func swipeReveal(isRevealed: Bool, duration: Double = 0.8) -> some View {
        modifier(SwipeRevealModifier(isRevealed: isRevealed, duration: duration))
    }
}

// MARK: - Splash View

struct SplashView: View {
    @Binding var isComplete: Bool
    @Binding var contentReady: Bool
    
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var superwallManager = SuperwallManager.shared
    @StateObject private var libraryViewModel = LibraryViewModel.shared
    
    // Animation states
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var showFirstLine: Bool = false
    @State private var showSecondLine: Bool = false
    @State private var showReviews: Bool = false
    @State private var fadeOut: Bool = false
    
    // Data loading state
    @State private var dataLoaded: Bool = false
    
    var body: some View {
        ZStack {
            // Solid background that shows immediately (prevents flash while video loads)
            Color.black
                .ignoresSafeArea()
            
            // Video background
            LoopingVideoBackground(videoName: "bg4")
            
            // Dark overlay for better text readability
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)
                
                // Logo with glow effect - positioned towards top, smaller
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
                                startRadius: 25,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(glowOpacity)
                    
                    // Logo - smaller (60px instead of 100px)
                    Image("nomaslogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                Spacer()
                    .frame(height: 80)
                
                // Text lines container
                VStack(spacing: 16) {
                    // First line with swipe reveal
                    Text("Embrace this pause.")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                        .swipeReveal(isRevealed: showFirstLine, duration: 0.8)
                    
                    // Second line with swipe reveal
                    Text("Reflect before you relapse.")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                        .swipeReveal(isRevealed: showSecondLine, duration: 0.8)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                
                Spacer()
                    .frame(height: 40)
                
                // Reviews image with swipe reveal
                Image("nomasreviews")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
                    .swipeReveal(isRevealed: showReviews, duration: 0.8)
                
                Spacer()
            }
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear {
            startAnimations()
            loadData()
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Logo fade in and scale (quick - 0.6s)
        withAnimation(.easeOut(duration: 0.6)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Glow pulse
        withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
            glowOpacity = 1.0
        }
        
        // First text line swipe reveals after logo (starts at 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showFirstLine = true
        }
        
        // Second text line swipe reveals (starts at 2.8s - after first line visible for 2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            showSecondLine = true
        }
        
        // Reviews image swipe reveals (starts at 4.8s - after second line visible for 2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.8) {
            showReviews = true
        }
        
        // Complete splash after reviews shown for 1 second (at ~6.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.4) {
            completeIfReady()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        Task {
            // Run data loading tasks in parallel for efficiency
            async let userDataTask: () = userData.initializeFromSupabase()
            async let authTask: () = authManager.checkAuthStatus()
            async let subscriptionTask: () = superwallManager.checkSubscriptionStatus()
            async let libraryTask: () = libraryViewModel.fetchData()
            
            // Wait for all tasks to complete
            _ = await (userDataTask, authTask, subscriptionTask, libraryTask)
            
            // Sync Superwall result to userData
            userData.hasActiveSubscription = superwallManager.hasActiveSubscription
            
            // Preload article images (runs in background, may extend past splash)
            // The articles are already fetched, so we can start caching images
            let allArticles = libraryViewModel.articlesByCategory.values.flatMap { $0 }
            if !allArticles.isEmpty {
                Task {
                    await ImageCacheManager.shared.preloadArticleImages(articles: Array(allArticles))
                }
            }
            
            await MainActor.run {
                dataLoaded = true
                // Signal that content can now be rendered behind splash
                contentReady = true
            }
        }
    }
    
    private func completeIfReady() {
        // Only complete if data is loaded
        // If data isn't loaded yet, we'll wait for it
        if dataLoaded {
            // Start fade out animation
            withAnimation(.easeInOut(duration: 0.5)) {
                fadeOut = true
            }
            // Complete after fade out finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isComplete = true
            }
        } else {
            // Check again in a short while
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completeIfReady()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView(isComplete: .constant(false), contentReady: .constant(false))
}
