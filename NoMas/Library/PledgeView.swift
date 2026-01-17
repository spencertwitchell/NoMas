//
//  PledgeView.swift
//  NoMas
//
//  Daily sobriety pledge view
//

import SwiftUI

struct PledgeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var pledgeManager = PledgeManager.shared
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Video Background
                LoopingVideoBackground(videoName: "bg flow")
                
                // Dark overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                if pledgeManager.isPledgedToday {
                    alreadyPledgedView
                } else {
                    pledgeContentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Compromiso")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("¿Compromiso para hoy?", isPresented: $showingConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Compromiso") {
                pledgeManager.makePledge()
                // Brief delay then dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        } message: {
            Text("Te comprometes a mantenerte fuerte durante las próximas 24 horas. ¡Tú puedes!")
        }
    }
    
    // MARK: - Pledge Content View
    
    private var pledgeContentView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Hand icon
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
            
            // Title
            Text("Compromiso de sobriedad")
                .font(.titleLarge)
                .foregroundColor(.white)
            
            // Description
            Text("Haz un compromiso contigo mismo para mantenerte fuerte hoy. Mañana revisarás cómo te fue.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
Spacer()
            
            // Benefits card
            benefitsCard
            
            Spacer()
            
            // Pledge button
            Button(action: {
                showingConfirmation = true
            }) {
                Text("Comprometerme ahora")
                    .font(.button)
                    .foregroundColor(.backgroundGradientEnd)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Benefits Card
    
    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            benefitRow(
                icon: "checkmark.circle",
                title: "Meta Alcanzable",
                description: "Al comprometerte, aceptas mantenerte fuerte por hoy."
            )
            
            benefitRow(
                icon: "sparkles",
                title: "Tómalo con calma",
                description: "Simplemente vive el día con normalidad y, después de comprometerte, no cambies de opinión."
            )
            
            benefitRow(
                icon: "crown",
                title: "El éxito es inevitable",
                description: "Mantente fuerte: los primeros días o semanas serán difíciles, pero después será más fácil."
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 24)
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.buttonSmall)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Already Pledged View
    
    private var alreadyPledgedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Checkmark icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("¡Te has comprometido!")
                .font(.titleLarge)
                .foregroundColor(.white)
            
            Text("Hiciste un compromiso para mantenerte fuerte hoy. Sigue adelante, ¡tú puedes!")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let timeRemaining = pledgeManager.timeRemainingString {
                Text(timeRemaining)
                    .font(.caption)
                    .foregroundColor(.accentGradientStart)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Close button
            Button(action: { dismiss() }) {
                Text("Cerrar")
                    .font(.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient.accent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    PledgeView()
}
