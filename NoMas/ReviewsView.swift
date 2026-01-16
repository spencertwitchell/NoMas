//
//  ReviewsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import StoreKit

// MARK: - Reviews View

struct ReviewsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    @Environment(\.requestReview) private var requestReview
    @State private var isRequestingReview = false
    
    private let reviews = [
        AppReview(
            name: "Juanes",
            text: "Ahora estoy más presente, y la app tuvo mucho que ver. En conversaciones, en momentos, en relaciones. Antes mi mente siempre estaba en otro lugar. Hoy puedo mirar a las personas a los ojos, escuchar de verdad y conectar. Mi familia y mis amigos han notado el cambio desde que empecé a usarla.",
            imageName: "juanes"
        ),
        AppReview(
            name: "Miguel",
            text: "La vida volvió a tener color desde que empecé con la app. Durante años todo se sentía gris, automático, sin emoción. Hoy me despierto con ilusión por el futuro. La app me ayudó a reconectar conmigo, a retomar hobbies que había olvidado y a volver a creer en mí. Por primera vez en mucho tiempo, me siento vivo otra vez.",
            imageName: "miguelo"
        ),
        AppReview(
            name: "Geros",
            text: "Tomar la decisión de usar esta app cambió mi vida de formas que nunca imaginé. No fue fácil, hubo días muy duros, pero cada ejercicio, cada reflexión, cada paso valió la pena. Hoy tengo más confianza, más claridad y más paz.",
            imageName: "marcel"
        ),
        AppReview(
            name: "Liam",
            text: "Pensé que nunca podría salir de ese ciclo. Me sentía atrapado, avergonzado y cansado de mí mismo. La app me ayudó a entender que no estaba roto, solo estaba herido. Hoy me trato con más compasión y tengo herramientas reales para seguir adelante.",
            imageName: "liam"
        ),
        AppReview(
            name: "José",
            text: "Volví a disfrutar las cosas simples: una conversación, una caminata, una risa sincera. Dejé de esconderme de mí mismo.",
            imageName: "morebro"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background image
            Image("bg67")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                OnboardingHeader(
                    showBackButton: true,
                    onBack: { onboardingState.goBack() }
                )
                .padding(.bottom, 12)
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(minHeight: 24)
                        
                        // Title
                        Text("Ayuda a Otros\nEncuentra Libertad")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                            .frame(minHeight: 16)
                        
                        // Reviews image
                        Image("nomasreviews")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200)
                        
                        Spacer()
                            .frame(minHeight: 16)
                        
                        // Description
                        VStack(spacing: 8) {
                            Text("Al dejar una calificación positiva, ayudas a que otras personas que luchan contra la adicción encuentren esta app y comiencen su camino de recuperación.")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                            
                            Text("¡Agradecemos tu apoyo!")
                                .font(.titleSmall)
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                            .frame(minHeight: 32)
                        
                        // Reviews list
                        VStack(spacing: 16) {
                            ForEach(reviews) { review in
                                AppReviewCard(review: review)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Bottom padding for floating button
                        Spacer()
                            .frame(minHeight: 120)
                    }
                }
            }
            
            // Floating Continue Button
            VStack {
                Spacer()
                
                Button(action: {
                    if !isRequestingReview {
                        isRequestingReview = true
                        requestReview()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            onboardingState.advance()
                        }
                    }
                }) {
                    Text("Continuar")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: -4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .disabled(isRequestingReview)
                .opacity(isRequestingReview ? 0.6 : 1.0)
            }
        }
    }
    
    // MARK: - Review Model
    
    struct AppReview: Identifiable {
        let id = UUID()
        let name: String
        let text: String
        let imageName: String
    }
    
    // MARK: - Review Card
    
    struct AppReviewCard: View {
        let review: AppReview
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header: Avatar + Name + Stars
                HStack(spacing: 12) {
                    Image(review.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    
                    Text(review.name)
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    // 5 Stars
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.captionSmall)
                                .foregroundStyle(LinearGradient.accent)
                        }
                    }
                }
                
                // Review text
                Text("\"\(review.text)\"")
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surfaceBackground)
                    .cornerRadius(12)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReviewsView()
}
