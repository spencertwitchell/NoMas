//
//  SymptomsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie

// MARK: - Symptoms View

struct SymptomsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    private var userData: UserData { UserData.shared }
    
    // Generate symptoms based on quiz answers
    private var symptoms: [Symptom] {
        var result: [Symptom] = []
        
        // Always show these core symptoms
        result.append(Symptom(
            icon: "brain.head.profile",
            title: "Desregulación de la dopamina",
            description: "El sistema de recompensa de tu cerebro ha sido alterado por la exposición repetida"
        ))
        
        // Add based on frequency
        if let frequency = userData.viewingFrequency {
            switch frequency {
            case .moreThanOnceDaily, .onceDaily:
                result.append(Symptom(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Patrones de comportamiento compulsivo",
                    description: "El uso diario ha creado fuertes vías neuronales habituales"
                ))
            case .fewTimesWeekly:
                result.append(Symptom(
                    icon: "clock.arrow.circlepath",
                    title: "Desencadenantes habituales",
                    description: "El uso regular ha creado patrones de impulso predecibles"
                ))
            case .lessThanWeekly:
                break
            }
        }
        
        // Add based on escalation
        if userData.escalationToExtreme == true {
            result.append(Symptom(
                icon: "exclamationmark.triangle",
                title: "Tolerancia y escalada",
                description: "Has necesitado contenido más extremo para sentir el mismo efecto"
            ))
        }
        
        // Add based on arousal difficulty
        if userData.arousalDifficulty == .frequently {
            result.append(Symptom(
                icon: "heart.slash",
                title: "Dependencia de la excitación",
                description: "Dificultad para la excitación natural sin pornografía"
            ))
        }
        
        // Add based on emotional coping
        if userData.copingEmotional == .frequently || userData.copingEmotional == .occasionally {
            result.append(Symptom(
                icon: "cloud.rain",
                title: "Desconexión emocional",
                description: "Usar la pornografía para escapar de emociones difíciles"
            ))
        }
        
        // Add based on stress/boredom responses
        if userData.stressResponse == .frequently || userData.boredomResponse == .frequently {
            result.append(Symptom(
                icon: "bolt.horizontal",
                title: "Respuesta automática al estrés",
                description: "Tu cerebro recurre automáticamente a la pornografía cuando está estresado o aburrido"
            ))
        }
        
        // Ensure we have at least 3 symptoms
        if result.count < 3 {
            result.append(Symptom(
                icon: "eye.slash",
                title: "Fragmentación de la atención",
                description: "Dificultad para concentrarte en tareas sin pensamientos intrusivos"
            ))
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            // Video background
            LoopingVideoBackground(videoName: "bg4")
            
            // Dark overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                .padding(.bottom, 12)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title
                        Text("Tus síntomas")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        // Subtitle
                        Text("Según tus respuestas, es posible que estés experimentando:")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Symptoms list
                        VStack(spacing: 16) {
                            ForEach(symptoms) { symptom in
                                SymptomRow(symptom: symptom)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Bottom padding for button
                        Spacer()
                            .frame(minHeight: 100)
                    }
                    .padding(.top, 16)
                }
                
                // Continue button
                Button(action: {
                    onboardingState.advance()
                }) {
                    Text("Continuar")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Symptom Model

struct Symptom: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Symptom Row

struct SymptomRow: View {
    let symptom: Symptom
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: symptom.icon)
                .font(.titleMedium)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.accentGradientStart.opacity(0.7))
                .cornerRadius(12)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(symptom.title)
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                
                Text(symptom.description)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.surfaceBackground)
        .cornerRadius(16)
    }
}

// MARK: - Onboarding Header (Reusable)

struct OnboardingHeader: View {
    var showBackButton: Bool = true
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            // Back button
            if showBackButton, let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
            
            Spacer()
            
            // Logo
            Image("nomaslogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 40)
            
            Spacer()
            
            // Spacer for balance
            Spacer()
                .frame(width: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

// MARK: - Preview

#Preview {
    SymptomsView()
}
