//
//  NomiQuizView.swift
//  NoMas
//
//  Quiz flow for Nomi AI context gathering
//  Structure matches NoContact AIQuizView for proper keyboard handling
//

import SwiftUI
import Lottie

struct NomiQuizView: View {
    @ObservedObject var viewModel: NomiViewModel
    @Binding var isPresented: Bool
    
    @State private var currentPage = 0
    @State private var isSaving = false
    
    // Pages: 0 = Welcome, 1-7 = Questions, 8 = Thank You
    private let totalPages = 8
    
    var body: some View {
        ZStack {
            // Base gradient background
            AppBackground()
                .ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Progress header (shown for questions only, not welcome or thank you)
                    if currentPage > 0 && currentPage < totalPages {
                        progressHeader
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            pageContent
                                .id(currentPage) // Triggers transition on page change
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, currentPage == 0 ? 40 : 20)
                        .padding(.bottom, 40)
                    }
                }
                .background(
                    ZStack {
                        Image("bg7")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                    }
                )
                // safeAreaInset keeps button above keyboard
                .safeAreaInset(edge: .bottom) {
                    if currentPage > 0 && currentPage < totalPages {
                        navigationButtons
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .background(.clear)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if currentPage > 0 {
                            currentPage -= 1
                        } else {
                            isPresented = false
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.accent)
                            .frame(width: geometry.size.width * progress, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 6)
                
                Spacer()
                
                // Symmetry spacer
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    private var progress: CGFloat {
        CGFloat(currentPage) / CGFloat(totalPages)
    }
    
    // MARK: - Page Content
    
    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            welcomePage
        case 1:
            questionPage(
                title: "¿Cuánto tiempo has estado luchando con el consumo de pornografía?",
                subtitle: "Semanas, meses o años — comparte lo que sientas que es más preciso.",
                binding: $viewModel.quizData.struggleDuration
            )
        case 2:
            questionPage(
                title: "¿Cómo describirías tu relación con la pornografía en este momento?",
                subtitle: "¿Ocasional pero difícil de controlar, o algo que se siente compulsivo? Describe tu patrón actual.",
                binding: $viewModel.quizData.currentRelationship
            )
        case 3:
            questionPage(
                title: "¿Qué suele desencadenar el impulso de ver pornografía?",
                subtitle: "Aburrimiento, estrés, soledad, noches tardías, emociones o hábitos — identificar los detonantes te ayuda a recuperar el control.",
                binding: $viewModel.quizData.triggers
            )
        case 4:
            questionPage(
                title: "¿Cuándo es más probable que cedas al impulso?",
                subtitle: "Hora del día, lugar, estado de ánimo o situaciones específicas en las que suele ocurrir.",
                binding: $viewModel.quizData.vulnerableSituations
            )
        case 5:
            questionPage(
                title: "¿Cómo suele hacerte sentir el consumo de pornografía después?",
                subtitle: "Alivio, insensibilidad, culpa, frustración u otra cosa — sé honesto sobre lo que aparece.",
                binding: $viewModel.quizData.postUseFeelings
            )
        case 6:
            questionPage(
                title: "¿Qué efectos negativos ha tenido esto en tu vida?",
                subtitle: "Motivación, confianza, relaciones, salud mental, enfoque o energía — lo que te resulte más relevante.",
                binding: $viewModel.quizData.negativeEffects
            )
        case 7:
            questionPage(
                title: "¿Qué te motiva a querer cambiar en este momento?",
                subtitle: "Una relación, tu yo futuro, claridad mental, confianza o estar cansado del ciclo — ¿qué te impulsó a actuar?",
                binding: $viewModel.quizData.motivationForChange
            )
        case 8:
            thankYouPage
        default:
            EmptyView()
        }
    }
    
    // MARK: - Welcome Page
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Lottie animation placeholder
            LottieView(animation: .named("nomasnormal"))
                .playing(loopMode: .loop)
                .frame(width: 200, height: 200)
            
            VStack(spacing: 12) {
                Text("Vamos a conocerte")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Responde algunas preguntas para que Nomi pueda entender mejor tu situación y ofrecerte apoyo más personalizado.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentPage = 1
                }
            } label: {
                Text("Continuar")
                    .font(.button)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient.accent)
                    .cornerRadius(26)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Question Page
    
    private func questionPage(title: String, subtitle: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // TextEditor for long-form answers
            TextEditor(text: binding)
                .font(.body)
                .foregroundColor(.textPrimary)
                .frame(minHeight: 150)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.25))
                .cornerRadius(12)
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Thank You Page
    
    private var thankYouPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Lottie animation placeholder
            LottieView(animation: .named("nomaswink"))
                .playing(loopMode: .loop)
                .frame(width: 200, height: 200)
            
            VStack(spacing: 12) {
                Text("Gracias por compartir")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Abrirte no es fácil, pero es el primer paso hacia un cambio real. Nomi ahora comprende mejor tu camino y está lista para apoyarte.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Button {
                Task {
                    await saveAndDismiss()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient.accent)
                        .cornerRadius(26)
                } else {
                    Text("Comienza a chatear con Nomi")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient.accent)
                        .cornerRadius(26)
                }
            }
            .disabled(isSaving)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Save and Dismiss
    
    private func saveAndDismiss() async {
        isSaving = true
        
        do {
            try await viewModel.saveQuizData()
            await viewModel.loadConversations()
        } catch {
            print("❌ Failed to save quiz data: \(error)")
            viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
        }
        
        isSaving = false
        
        // Always dismiss, even if there was an error saving
        // The quiz data is marked complete in saveQuizData
        await MainActor.run {
            isPresented = false
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.captionSmall)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            } label: {
                Text("Continuar")
                    .font(.button)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Group {
                            if canContinue {
                                LinearGradient.accent
                            } else {
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .cornerRadius(26)
            }
            .disabled(!canContinue)
        }
    }
    
    private var canContinue: Bool {
        switch currentPage {
        case 1: return !viewModel.quizData.struggleDuration.trimmed.isEmpty
        case 2: return !viewModel.quizData.currentRelationship.trimmed.isEmpty
        case 3: return !viewModel.quizData.triggers.trimmed.isEmpty
        case 4: return !viewModel.quizData.vulnerableSituations.trimmed.isEmpty
        case 5: return !viewModel.quizData.postUseFeelings.trimmed.isEmpty
        case 6: return !viewModel.quizData.negativeEffects.trimmed.isEmpty
        case 7: return !viewModel.quizData.motivationForChange.trimmed.isEmpty
        default: return true
        }
    }
}

// MARK: - String Extension

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        NomiQuizView(viewModel: NomiViewModel(), isPresented: .constant(true))
    }
}
