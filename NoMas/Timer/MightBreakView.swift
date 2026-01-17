//
//  MightBreakView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  MightBreakView.swift
//  NoMas
//
//  Main "I Might Break" page with reflection questions and action links
//

import SwiftUI
import Lottie

struct MightBreakView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int
    @State private var currentQuestionIndex = 0
    @State private var showingPledge = false
    
    let questions: [String] = [
        "\"Si cedo ahora mismo, ¿me dará paz real — o solo unos minutos de alivio seguidos de culpa?\"",
        "\"¿Estoy buscando conexión o solo huyendo de la incomodidad? ¿Qué es lo que realmente necesito ahora mismo?\"",
        "\"¿La versión futura de mí — en la que estoy trabajando para convertirme — tomaría esta decisión?\"",
        "\"¿Qué detonó este impulso? ¿Aburrimiento? ¿Estrés? ¿Soledad? ¿Puedo abordar eso en su lugar?\"",
        "\"Si me mantengo firme solo durante los próximos 10 minutos, ¿este impulso seguirá sintiéndose tan fuerte?\""
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .center, spacing: 16) {
                            // Header section
                            VStack(alignment: .center, spacing: 12) {
                                Text("Los impulsos no significan\nque estés fallando.")
                                    .font(.titleLarge)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                                
                                // Lottie animation
                                LottieView(animation: .named("doubting"))
                                    .playing(loopMode: .loop)
                                    .frame(width: 175, height: 175)
                                
                                Text("Sentir el impulso es una parte normal de la recuperación. Lo que importa es lo que haces a continuación. Cada impulso que superas hace que el siguiente sea más fácil de resistir.")
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(5)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                            
                            // Questions section
                            VStack(alignment: .center, spacing: 2) {
                                Text("Preguntas para reflexionar:")
                                    .font(.titleMedium)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                // Questions carousel
                                TabView(selection: $currentQuestionIndex) {
                                    ForEach(0..<questions.count, id: \.self) { index in
                                        MightBreakQuestionCard(question: questions[index])
                                            .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 140)
                                
                                // Page dots
                                HStack(spacing: 8) {
                                    ForEach(0..<questions.count, id: \.self) { index in
                                        Circle()
                                            .fill(currentQuestionIndex == index ? Color.accentGradientStart : Color.textTertiary)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 1)
                                .padding(.bottom, 16)
                            }
                            
                            // Things to do instead section
                            VStack(alignment: .center, spacing: 16) {
                                Text("Cosas que hacer en su lugar:")
                                    .font(.titleMedium)
                                    .foregroundColor(.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 10) {
                                    MightBreakActionButton(
                                        icon: "ellipsis.message.fill",
                                        title: "Habla con Nomi",
                                        action: {
                                            dismiss()
                                            selectedTab = 1 // Chat tab
                                        }
                                    )
                                    
                                    MightBreakActionButton(
                                        icon: "hand.raised.fill",
                                        title: "Haz un compromiso para hoy",
                                        action: {
                                            showingPledge = true
                                        }
                                    )
                                    
                                    MightBreakActionButton(
                                        icon: "person.3.fill",
                                        title: "Conéctate con la comunidad",
                                        action: {
                                            dismiss()
                                            selectedTab = 3 // Community tab
                                        }
                                    )
                                    
                                    MightBreakActionButton(
                                        icon: "sparkles",
                                        title: "Enfócate en ti mismo",
                                        action: {
                                            dismiss()
                                            selectedTab = 2 // Library tab
                                        }
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Return button
                            VStack(spacing: 12) {
                                Button(action: { dismiss() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 16))
                                        Text("Volver al Timer")
                                            .font(.button)
                                    }
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(LinearGradient.accent)
                                    .cornerRadius(12)
                                }
                                
                                Text("Este impulso pasará. Mantente fuerte — estás reconfigurando tu cerebro.")
                                    .font(.captionSmall)
                                    .foregroundColor(.textTertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPledge) {
                PledgeView()
            }
            // When pledge sheet is dismissed, also dismiss this view
            .onChange(of: showingPledge) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    // Pledge sheet was dismissed, dismiss this flow too
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Question Card

struct MightBreakQuestionCard: View {
    let question: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question)
                .font(.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient.accent
                .opacity(0.5)
        )
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// MARK: - Action Button

struct MightBreakActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.textPrimary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.buttonSmall)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(
                LinearGradient.accent
                    .opacity(0.5)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MightBreakView(selectedTab: .constant(0))
}
