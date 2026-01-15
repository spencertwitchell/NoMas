//
//  ResetTimerFlowView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/13/25.
//


//
//  ResetTimerFlowView.swift
//  NoMas
//
//  Reset timer entry point with date picker
//

import SwiftUI
import Lottie

// MARK: - Reset Timer Flow View

struct ResetTimerFlowView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userData = UserData.shared
    @Binding var selectedTab: Int
    
    @State private var showingDatePicker = false
    @State private var showingAnimationFlow = false
    @State private var selectedResetDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Title
                    Text("¿Tuviste una recaída?")
                        .font(.titleXL)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    // Lottie Animation (placeholder)
                    LottieView(animation: .named("Heart_Blue"))
                        .playing(loopMode: .loop)
                        .frame(width: 250, height: 180)
                    
                    // Description
                    VStack(spacing: 16) {
                        Text("Está bien. Los tropiezos le pasan a casi todos en este camino.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Lo más importante es que estás aquí, enfrentándolo con honestidad y fortaleza.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Cuando estés listo, toca abajo para reiniciar tu reloj y empezar de nuevo.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Reset Button
                    Button(action: {
                        selectedResetDate = Date() // Default to now
                        showingDatePicker = true
                    }) {
                        Text("Reiniciar reloj")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(LinearGradient.accent)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 32)
                    
                    // Caption below button
                    Text("Esto no es un fracaso — es crecimiento en proceso.")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                ResetDatePickerSheet(
                    selectedDate: $selectedResetDate,
                    onConfirm: {
                        showingDatePicker = false
                        showingAnimationFlow = true
                    }
                )
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $showingAnimationFlow) {
                ResetAnimationFlowView(
                    selectedTab: $selectedTab,
                    resetDate: selectedResetDate
                )
            }
            .onChange(of: showingAnimationFlow) { _, newValue in
                if !newValue {
                    // When animation flow dismisses, also dismiss ResetTimerFlowView
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Date Picker Sheet

struct ResetDatePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("¿Cuándo recaíste?")
                        .font(.titleMedium)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Selecciona la fecha y la hora en que ocurrió")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                
                // Date Picker
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .frame(height: 180)
                .clipped()
                .background(Color.surfaceBackground)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onConfirm()
                    }) {
                        Text("Confirmar reinicio")
                            .font(.button)
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(LinearGradient.accent)
                            .cornerRadius(16)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancelar")
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
                
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview("Reset Timer Flow") {
    ResetTimerFlowView(selectedTab: .constant(0))
}

#Preview("Date Picker Sheet") {
    ResetDatePickerSheet(
        selectedDate: .constant(Date()),
        onConfirm: {}
    )
}
