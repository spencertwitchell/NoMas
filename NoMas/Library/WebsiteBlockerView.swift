//
//  WebsiteBlockerView.swift
//  NoMas
//
//  Website blocker setup view with power button interface
//

import SwiftUI

struct WebsiteBlockerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var blockerManager = WebsiteBlockerManager.shared
    
    // Animation state
    @State private var isPulsing = false
    @State private var showConfirmDisable = false
    @State private var showComingSoon = false

    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 0) {
                // Header
                header
                
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    // Status text
                    statusSection
                    
                    // Power button
                    powerButton
                    
                    // Description
                    descriptionSection
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Footer info
                footerInfo
            }
        }
        .alert("Disable Blocker?", isPresented: $showConfirmDisable) {
            Button("Cerrar", role: .cancel) { }
            Button("Desactivar", role: .destructive) {
                blockerManager.disableBlocker()
            }
        } message: {
            Text("Esto eliminará todas las restricciones de sitios web. ¿Estás seguro de que deseas continuar?")
        }
        .alert("Coming Soon!", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Website blocking is waiting for Apple approval. This feature will be available in an upcoming update!")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Bloqueador de sitios web")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            Text(blockerManager.isBlockerEnabled ? "PROTECTION ACTIVE" : "PROTECTION OFF")
                .font(.titleCustom(size: 14))
                .tracking(2)
                .foregroundColor(blockerManager.isBlockerEnabled ? .green : .textTertiary)
            
            if blockerManager.isBlockerEnabled && blockerManager.blockedDomainsCount > 0 {
                Text("\(blockerManager.blockedDomainsCount) custom sites blocked")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
    }
    
    // MARK: - Power Button
    
    private var powerButton: some View {
        Button(action: handlePowerButtonTap) {
            ZStack {
                // Outer glow ring (when enabled)
                if blockerManager.isBlockerEnabled {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.green.opacity(0.6), Color.green.opacity(0.2)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 180, height: 180)
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .opacity(isPulsing ? 0.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }
                
                // Main button circle
                Circle()
                    .fill(
                        blockerManager.isBlockerEnabled
                            ? LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 160, height: 160)
                
                // Border
                Circle()
                    .stroke(
                        blockerManager.isBlockerEnabled
                            ? Color.green.opacity(0.5)
                            : Color.white.opacity(0.2),
                        lineWidth: 2
                    )
                    .frame(width: 160, height: 160)
                
                // Power icon or loading
                if blockerManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    Image(systemName: "power")
                        .font(.system(size: 60, weight: .thin))
                        .foregroundColor(blockerManager.isBlockerEnabled ? .green : .white.opacity(0.7))
                }
            }
        }
        .disabled(blockerManager.isLoading)
        .onAppear {
            if blockerManager.isBlockerEnabled {
                isPulsing = true
            }
        }
        .onChange(of: blockerManager.isBlockerEnabled) { _, enabled in
            isPulsing = enabled
        }
    }
    
    // MARK: - Description Section
    
    private var descriptionSection: some View {
        VStack(spacing: 16) {
            Text(blockerManager.isBlockerEnabled
                 ? "Contenido adulto bloqueado en todas las apps y navegadores"
                 : "Toca para bloquear contenido adulto en todas las apps y navegadores")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            if let error = blockerManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Footer Info
    
    private var footerInfo: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.accentGradientStart)
                Text("Bloquea más de 60 sitios para adultos")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.accentGradientStart)
                Text("Funciona en Safari, Chrome y todas las apps")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "eye.slash.fill")
                    .foregroundColor(.accentGradientStart)
                Text("La navegación privada también está bloqueada")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.bottom, 50)
    }
    
    // MARK: - Actions
    
    private func handlePowerButtonTap() {
        if blockerManager.isBlockerEnabled {
            // Show confirmation before disabling
            showConfirmDisable = true
        } else {
            
            showComingSoon = true
            
            // Enable blocker (uncomment when apple approves)
            //Task {
             //   await blockerManager.enableBlocker()
            //}
        }
    }
}

// MARK: - Preview

#Preview {
    WebsiteBlockerView()
}
