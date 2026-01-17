//
//  OptionalAuthView.swift
//  NoMas
//
//  Created by Claude on 12/11/25.
//

import SwiftUI

// MARK: - Optional Auth View

/// Early authentication screen shown before the quiz.
/// Users can sign in OR skip (and will be forced to auth after paywall).

struct OptionalAuthView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingEmailSignUp = false
    @State private var showingEmailLogin = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Image background - clipped to screen bounds
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
                        .frame(height: 60)
                        .padding(.top, 60)
                    
                    Spacer() // Flexible space between logo and content
                    
                    // Main content group - centered
                    VStack(spacing: 0) {
                        // Title
                        Text("Guarda Tu Progreso")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 12)
                        
                        // Subtitle
                        Text("Inicia sesión para sincronizar tu progreso entre dispositivos.")
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
                                    handleAuthSuccess()
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
                        .padding(.bottom, 24)
                        
                        // Skip button
                        Button(action: handleSkip) {
                            HStack(spacing: 6) {
                                Text("O sáltalo por ahora")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .underline()
                                Image(systemName: "arrow.right")
                                    .font(.body)
                            }
                            .foregroundColor(.white)
                        }
                        .disabled(authManager.isLoading)
                    }
                    
                    Spacer() // Flexible space between content and login link
                    
                    // Login link anchored at bottom
                    HStack(spacing: 4) {
                        Text("¿Ya tienes una cuenta?")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                        
                        Button(action: {
                            showingEmailLogin = true
                        }) {
                            Text("Inicia sesión aquí")
                                .font(.bodySmall)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                                .underline()
                        }
                    }
                    .padding(.bottom, 40)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(isPresented: $showingEmailSignUp) {
            EmailSignUpView(
                onComplete: {
                    showingEmailSignUp = false
                    handleAuthSuccess()
                },
                onShowLogin: {
                    showingEmailSignUp = false
                    showingEmailLogin = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingEmailLogin) {
            EmailLoginView(
                onComplete: {
                    showingEmailLogin = false
                    handleAuthSuccess()
                },
                onShowSignUp: {
                    showingEmailLogin = false
                    showingEmailSignUp = true
                }
            )
        }
        // Listen for auth state changes (for OAuth callbacks like Google)
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                handleAuthSuccess()
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleSkip() {
        // Mark that user skipped early auth
        userData.skippedEarlyAuth = true
        print("⭕️ User skipped early auth - skippedEarlyAuth set to: \(userData.skippedEarlyAuth)")
        onboardingState.advance()
    }
    
    private func handleAuthSuccess() {
        // User authenticated early - clear the skip flag
        userData.skippedEarlyAuth = false
        print("✅ User authenticated early - skippedEarlyAuth set to: \(userData.skippedEarlyAuth)")
        print("   isAuthenticated: \(authManager.isAuthenticated)")
        print("   email: \(authManager.currentUserEmail ?? "nil")")
        onboardingState.advance()
    }
}

// MARK: - Preview

#Preview {
    OptionalAuthView()
}
