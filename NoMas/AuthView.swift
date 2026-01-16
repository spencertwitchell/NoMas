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
                Text("Libérate.\nRecupera Tu Vida.")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
                
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
                        title: "Continua con Google",
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
                        title: "Regístrate con Correo",
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
                    Text("¿Ya tienes una cuenta?")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                    
                    Button(action: {
                        showingEmailLogin = true
                    }) {
                        Text("Inicia sesión")
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
    @State private var showingVerificationScreen = false
    
    private var isValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                // Centered content
                VStack(spacing: 24) {
                    // Title section
                    VStack(spacing: 12) {
                        Text("Crear una cuenta")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                        
                        Text("Comienza tu camino de recuperación hoy")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Form fields
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
                        SecureField("", text: $password, prompt: Text("Contraseña (6+ caracteres)").foregroundColor(.textTertiary))
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
                                // Check if we got a session (auto-verified) or need email confirmation
                                if authManager.isAuthenticated {
                                    // Auto-verified (unlikely with email confirmation enabled)
                                    dismiss()
                                    onComplete()
                                } else {
                                    // Email confirmation required - show verification screen
                                    showingVerificationScreen = true
                                }
                            } catch {
                                // Error handled by authManager
                            }
                        }
                    }) {
                        Text("Crear una Cuenta")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient.accent)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .disabled(!isValid || authManager.isLoading)
                    .opacity(isValid && !authManager.isLoading ? 1.0 : 0.6)
                    
                    // Login link
                    Button(action: {
                        dismiss()
                        onShowLogin()
                    }) {
                        Text("¿Ya tienes una cuenta? Inicia sesión aquí")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
            .fullScreenCover(isPresented: $showingVerificationScreen) {
                EmailVerificationPendingView(
                    email: email,
                    onVerified: {
                        showingVerificationScreen = false
                        dismiss()
                        onComplete()
                    },
                    onCancel: {
                        showingVerificationScreen = false
                    }
                )
            }
        }
    }
}

// MARK: - Email Verification Pending View

struct EmailVerificationPendingView: View {
    let email: String
    let onVerified: () -> Void
    let onCancel: () -> Void
    
    @StateObject private var authManager = AuthManager.shared
    @State private var isCheckingStatus = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Email icon
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(LinearGradient.accent)
                
                // Title
                VStack(spacing: 12) {
                    Text("Revisa tu correo electrónico")
                        .font(.titleLarge)
                        .foregroundColor(.textPrimary)
                    
                    Text("Hemos enviado un enlace de verificación a:")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    Text(email)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                }
                
                // Instructions
                VStack(spacing: 8) {
                    Text("Haz clic en el enlace del correo electrónico para verificarlo tu cuenta y continúa.")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Check status button
                Button(action: {
                    checkVerificationStatus()
                }) {
                    HStack(spacing: 8) {
                        if isCheckingStatus {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isCheckingStatus ? "Chequeando..." : "He verificado mi correo electrónico")
                    }
                    .font(.button)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient.accent)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .disabled(isCheckingStatus)
                
                // Resend link
                Button(action: {
                    resendVerificationEmail()
                }) {
                    Text("Reenviar correo de verificación")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .underline()
                }
                
                Spacer()
                    .frame(height: 16)
                
                // Cancel / Go back
                Button(action: onCancel) {
                    Text("Cancelar")
                        .font(.bodySmall)
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                onVerified()
            }
        }
    }
    
    private func checkVerificationStatus() {
        isCheckingStatus = true
        errorMessage = nil
        
        Task {
            // Try to refresh the session to check if email is now verified
            do {
                try await authManager.refreshSession()
                
                if authManager.isAuthenticated {
                    onVerified()
                } else {
                    // Not verified yet
                    errorMessage = "Correo no verificado aún. Por favor, revisa tu bandeja de entrada y haz clic en el enlace de verificación."
                }
            } catch {
                errorMessage = "No se pudo verificar. Por favor, inténtalo de nuevo."
            }
            
            isCheckingStatus = false
        }
    }
    
    private func resendVerificationEmail() {
        errorMessage = nil
        
        Task {
            do {
                // Use magic link to resend verification
                try await authManager.signInWithMagicLink(email: email)
                errorMessage = "¡Correo de verificación enviado!"
            } catch {
                errorMessage = "No se pudo reenviar el correo. Por favor, inténtalo de nuevo."
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
                
                // Centered content
                VStack(spacing: 24) {
                    // Title section
                    VStack(spacing: 12) {
                        Text("Bienvenido de Vuelta")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                        
                        Text("Continúa tu camino de recuperación")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Form fields
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
                        SecureField("", text: $password, prompt: Text("Contraseña").foregroundColor(.textTertiary))
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
                        Text("¿Olvidaste tu contraseña?")
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
                        Text("Iniciar sesión")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(LinearGradient.accent)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    .disabled(!isValid || authManager.isLoading)
                    .opacity(isValid && !authManager.isLoading ? 1.0 : 0.6)
                    
                    // Sign up link
                    Button(action: {
                        dismiss()
                        onShowSignUp()
                    }) {
                        Text("¿No tienes una cuenta? Regístrate")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.textPrimary)
                }
            }
            .alert("Restablecer contraseña", isPresented: $showingResetPassword) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Button("Enviar Enlace de Restablecimiento") {
                    Task {
                        do {
                            try await authManager.resetPassword(email: email)
                            resetEmailSent = true
                        } catch {
                            // Error handled by authManager
                        }
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Ingresa tu correo electrónico para recibir un enlace de restablecimiento de contraseña.")
            }
            .alert("Email Enviado", isPresented: $resetEmailSent) {
                Button("OK") {}
            } message: {
                Text("Revisa tu correo electrónico para el enlace de restablecimiento de contraseña.")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
