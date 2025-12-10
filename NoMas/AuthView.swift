//
//  AuthView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Auth View

struct AuthView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    @StateObject private var authManager = AuthManager.shared
    
    @State private var showingEmailSignUp = false
    @State private var showingEmailLogin = false
    
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
                    .frame(minHeight: 32)
                
                // Tagline
                Text("Break Free.\nReclaim Your Life.")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
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
                                    // Note: This opens Safari. The actual auth completion
                                    // happens when the app receives the callback URL.
                                    // The .onChange below will detect when auth succeeds.
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
                                onboardingState.advance()
                            }
                        },
                        onError: { error in
                            print("Apple Sign In error: \(error)")
                        }
                    )
                    
                    // Email Sign Up
                    AuthButton(
                        title: "Sign up with Email",
                        icon: "envelope.fill",
                        style: .accent,
                        isLoading: authManager.isLoading,
                        action: {
                            showingEmailSignUp = true
                        }
                    )
                }
                .padding(.horizontal, 32)
                .opacity(authManager.isLoading ? 0.6 : 1.0)
                
                Spacer()
                    .frame(minHeight: 24)
                
                // Login link
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Button(action: {
                        showingEmailLogin = true
                    }) {
                        Text("Login here")
                            .font(.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .underline()
                    }
                }
                
                Spacer()
                    .frame(minHeight: 40)
            }
        }
        .fullScreenCover(isPresented: $showingEmailSignUp) {
            EmailSignUpView(
                onComplete: {
                    showingEmailSignUp = false
                    if authManager.isAuthenticated {
                        onboardingState.advance()
                    }
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
                    if authManager.isAuthenticated {
                        onboardingState.advance()
                    }
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
                onboardingState.advance()
            }
        }
    }
}

// MARK: - Auth Button Styles

enum AuthButtonStyle {
    case google
    case apple
    case accent
    
    var backgroundColor: Color {
        switch self {
        case .google: return .white
        case .apple: return .black
        case .accent: return .accentGradientStart
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .google: return .black
        case .apple: return .white
        case .accent: return .white
        }
    }
    
    var usesGradient: Bool {
        self == .accent
    }
}

// MARK: - Auth Button Component

struct AuthButton: View {
    let title: String
    let icon: String
    let style: AuthButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(.button)
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                Group {
                    if style.usesGradient {
                        LinearGradient.accent
                    } else {
                        style.backgroundColor
                    }
                }
            )
            .cornerRadius(28)
        }
        .disabled(isLoading)
    }
}

// MARK: - Email Sign Up View

struct EmailSignUpView: View {
    let onComplete: () -> Void
    let onShowLogin: () -> Void
    
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingVerification = false
    
    private var isValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 24) {
                    Spacer()
                        .frame(minHeight: 40)
                    
                    Text("Create Account")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text("Start your recovery journey today")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    VStack(spacing: 16) {
                        // Email field
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.textTertiary))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.surfaceBackground)
                            .foregroundColor(.textPrimary)
                            .cornerRadius(12)
                        
                        // Password field
                        SecureField("", text: $password, prompt: Text("Password (6+ characters)").foregroundColor(.textTertiary))
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color.surfaceBackground)
                            .foregroundColor(.textPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    
                    // Error message
                    if let error = authManager.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Create Account button
                    Button(action: {
                        Task {
                            do {
                                try await authManager.signUpWithEmail(email: email, password: password)
                                // Show verification message or complete
                                showingVerification = true
                            } catch {
                                // Error handled by authManager
                            }
                        }
                    }) {
                        Text("Create Account")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient.accent)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .disabled(!isValid || authManager.isLoading)
                    .opacity(isValid && !authManager.isLoading ? 1.0 : 0.6)
                    
                    // Login link
                    Button(action: {
                        dismiss()
                        onShowLogin()
                    }) {
                        Text("Already have an account? Login here")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
            .alert("Check Your Email", isPresented: $showingVerification) {
                Button("OK") {
                    dismiss()
                    onComplete()
                }
            } message: {
                Text("We've sent a verification link to \(email). Please verify your email to continue.")
            }
        }
    }
}

// MARK: - Email Login View

struct EmailLoginView: View {
    let onComplete: () -> Void
    let onShowSignUp: () -> Void
    
    @StateObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingResetPassword = false
    @State private var resetEmailSent = false
    
    private var isValid: Bool {
        !email.isEmpty && email.contains("@") && !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 24) {
                    Spacer()
                        .frame(minHeight: 40)
                    
                    Text("Welcome Back")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text("Continue your recovery journey")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    VStack(spacing: 16) {
                        // Email field
                        TextField("", text: $email, prompt: Text("Email").foregroundColor(.textTertiary))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.surfaceBackground)
                            .foregroundColor(.textPrimary)
                            .cornerRadius(12)
                        
                        // Password field
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.textTertiary))
                            .textContentType(.password)
                            .padding()
                            .background(Color.surfaceBackground)
                            .foregroundColor(.textPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    
                    // Forgot password
                    Button(action: {
                        showingResetPassword = true
                    }) {
                        Text("Forgot password?")
                            .font(.caption)
                            .foregroundColor(.accentGradientStart)
                    }
                    
                    // Error message
                    if let error = authManager.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Login button
                    Button(action: {
                        Task {
                            do {
                                try await authManager.signInWithEmail(email: email, password: password)
                                if authManager.isAuthenticated {
                                    dismiss()
                                    onComplete()
                                }
                            } catch {
                                // Error handled by authManager
                            }
                        }
                    }) {
                        Text("Login")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient.accent)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .disabled(!isValid || authManager.isLoading)
                    .opacity(isValid && !authManager.isLoading ? 1.0 : 0.6)
                    
                    // Sign up link
                    Button(action: {
                        dismiss()
                        onShowSignUp()
                    }) {
                        Text("Don't have an account? Sign up")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
            .alert("Reset Password", isPresented: $showingResetPassword) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Button("Send Reset Link") {
                    Task {
                        do {
                            try await authManager.resetPassword(email: email)
                            resetEmailSent = true
                        } catch {
                            // Error handled by authManager
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email to receive a password reset link.")
            }
            .alert("Email Sent", isPresented: $resetEmailSent) {
                Button("OK") {}
            } message: {
                Text("Check your email for a password reset link.")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
