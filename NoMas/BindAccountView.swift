//
//  BindAccountView.swift
//  NoMas
//
//  Auth Screen #3: Required account binding after subscription.
//  Shown to users who skipped early auth and need to connect their account.
//

import SwiftUI

// MARK: - Bind Account View

/// Required authentication screen shown after subscription purchase.
/// NO skip button - auth is required to bind subscription to account.
/// After auth completes, marks onboarding as complete.

struct BindAccountView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingEmailSignUp = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Image background - constrained to screen bounds
                Image("bg7")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                // Dark overlay
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                
                // Content constrained to screen size
                VStack(spacing: 0) {
                    // Logo anchored at top
                    Image("nomaslogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                        .padding(.top, 80)
                    
                    Spacer() // Flexible space between logo and content
                    
                    // Main content group - centered but offset up with bottom padding
                    VStack(spacing: 0) {
                        // Title
                        Text("Vincula Tu Cuenta")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 12)
                        
                        // Subtitle
                        Text("Conecta tu cuenta para activar\ntu suscripción y sincronizar tu progreso.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 32)
                        
                        // Error message
                        if let error = authManager.authError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.bottom, 16)
                        }
                        
                        // Auth buttons
                        VStack(spacing: 16) {
                            // Google Sign In
                            AuthButton(
                                title: "Continua con Google",
                                icon: "g.circle.fill",
                                style: .google,
                                isLoading: authManager.isLoading,
                                action: {
                                    Task {
                                        do {
                                            try await AuthManager.shared.signInWithGoogle()
                                        } catch {
                                            print("❌ Google Sign In error: \(error)")
                                        }
                                    }
                                }
                            )
                            
                            // Apple Sign In
                            SignInWithAppleButton(
                                onSuccess: {
                                    if authManager.isAuthenticated {
                                        handleAuthComplete()
                                    }
                                },
                                onError: { error in
                                    print("Apple Sign In error: \(error)")
                                }
                            )
                            
                            // Email Sign Up
                            AuthButton(
                                title: "Regístrate con Correo",
                                icon: "envelope.fill",
                                style: .accent,
                                isLoading: authManager.isLoading,
                                action: {
                                    showingEmailSignUp = true
                                }
                            )
                        }
                        .padding(.horizontal, 48)
                        .opacity(authManager.isLoading ? 0.6 : 1.0)
                    }
                    .padding(.bottom, 80) // Offset content upward
                    
                    Spacer() // Flexible space below content
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showingEmailSignUp) {
            EmailSignUpView(
                onComplete: {
                    showingEmailSignUp = false
                    if authManager.isAuthenticated {
                        handleAuthComplete()
                    }
                },
                onShowLogin: {
                    // Just dismiss - no login option on this screen
                    showingEmailSignUp = false
                }
            )
        }
        // Listen for auth state changes (for OAuth callbacks like Google)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                handleAuthComplete()
            }
        }
    }
    
    // MARK: - Auth Complete
    
    private func handleAuthComplete() {
        print("✅ Account bound successfully")
        
        // Clear the skipped flag
        userData.skippedEarlyAuth = false
        
        // Mark onboarding as complete - this triggers navigation to MainView
        onboardingState.completeOnboarding()
    }
}

// MARK: - Preview

#Preview {
    BindAccountView()
}
