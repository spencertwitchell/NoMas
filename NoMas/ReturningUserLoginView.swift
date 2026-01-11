//
//  ReturningUserLoginView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 1/10/26.
//


//
//  ReturningUserLoginView.swift
//  NoMas
//
//  Auth Screen #2: For returning users who need to sign in.
//  Shown when hasCompletedOnboarding but not authenticated.
//

import SwiftUI

// MARK: - Returning User Login View

/// "Welcome Back" login screen for returning users.
/// After successful login, RootView routing handles destination automatically.

struct ReturningUserLoginView: View {
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingEmailLogin = false
    @State private var showingEmailSignUp = false
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg flow")
            
            // Dark overlay
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo
                Image("nomaslogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                
                Spacer()
                    .frame(height: 32)
                
                // Welcome back message
                Text("Welcome Back")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                    .frame(height: 12)
                
                Text("Sign in to continue your\nrecovery journey")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Spacer()
                
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
                        title: "Continue with Google",
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
                            // Auth state change handled by RootView routing
                        },
                        onError: { error in
                            print("Apple Sign In error: \(error)")
                        }
                    )
                    
                    // Email Login
                    AuthButton(
                        title: "Sign in with Email",
                        icon: "envelope.fill",
                        style: .accent,
                        isLoading: authManager.isLoading,
                        action: {
                            showingEmailLogin = true
                        }
                    )
                }
                .padding(.horizontal, 32)
                .opacity(authManager.isLoading ? 0.6 : 1.0)
                
                Spacer()
                    .frame(height: 24)
                
                // Sign up link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Button(action: {
                        showingEmailSignUp = true
                    }) {
                        Text("Sign up")
                            .font(.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .underline()
                    }
                }
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .fullScreenCover(isPresented: $showingEmailLogin) {
            EmailLoginView(
                onComplete: {
                    showingEmailLogin = false
                    // Auth state change handled by RootView routing
                },
                onShowSignUp: {
                    showingEmailLogin = false
                    showingEmailSignUp = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingEmailSignUp) {
            EmailSignUpView(
                onComplete: {
                    showingEmailSignUp = false
                    // Auth state change handled by RootView routing
                },
                onShowLogin: {
                    showingEmailSignUp = false
                    showingEmailLogin = true
                }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ReturningUserLoginView()
}
