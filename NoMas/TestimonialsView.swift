//
//  TestimonialsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Testimonials View

struct TestimonialsView: View {
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    private let testimonials = [
        Testimonial(
            name: "Terry Crews",
            quote: "Mi problema fue, y sigue siendo, con la pornografía: cambia la forma en que ves a las personas. Las personas se convierten en objetos, en partes del cuerpo; se convierten en cosas que se usan en lugar de personas a las que se ama.",
            imageName: "terrycrews"
        ),
        Testimonial(
            name: "Javier “Chicharito” Hernández",
            quote: "La adicción no es solo al alcohol o a las drogas. También puede ser a la pornografía, al sexo, a la validación. La adicción es un escape del dolor, y solo sanas cuando decides enfrentarte a ti mismo.",
            imageName: "chicharito"
        ),
        Testimonial(
            name: "Chris Rock",
            quote: "Cuando ves demasiado porno, ¿sabes qué pasa? Te desensibilizas. Al principio, cualquier porno sirve. Luego, más adelante, ya estás todo jodido y necesitas un cóctel perfecto de porno para excitarte. Yo estaba muy jodido… ahora estoy mucho mejor.",
            imageName: "chrisrock"
        ),
        Testimonial(
            name: "Angélica Jaramillo",
            quote: "La adicción no es falta de fuerza, es una herida que nadie ve. Cuando aprendes a mirarte con honestidad, empieza la verdadera libertad.",
            imageName: "angelica"
        ),
        Testimonial(
            name: "Luis Miguel",
            quote: "La adicción no empieza en la copa, empieza en el vacío. Mientras no sanas lo que llevas dentro, siempre vas a buscar algo afuera que te anestesie.",
            imageName: "luismiguel"
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
                    VStack(spacing: 24) {
                        // Title
                        Text("Lo que otros están diciendo")
                            .font(.titleLarge)
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 24)
                        
                        
                        // Subtitle
                        Text("Millones de personas han experimentado una recuperación efectiva al comprometerse a dejar la pornografía,este enfoque promueve una sanación duradera.")
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                        
                        // Testimonials list
                        VStack(spacing: 16) {
                            ForEach(testimonials, id: \.name) { testimonial in
                                TestimonialCardView(testimonial: testimonial)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                        .padding(.bottom, 120) // Space for button
                    }
                }
                .padding(.horizontal, 12)
                
                Spacer(minLength: 0)
            }
            
            // Continue button (fixed at bottom)
            VStack {
                Spacer()
                
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

// MARK: - Testimonial Model

struct Testimonial {
    let name: String
    let quote: String
    let imageName: String
}

// MARK: - Testimonial Card View

struct TestimonialCardView: View {
    let testimonial: Testimonial
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile row
            HStack(spacing: 12) {
                // Profile image
                Image(testimonial.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                
                // Name
                Text(testimonial.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            // Quote card
            Text("\"\(testimonial.quote)\"")
                .font(.body)
                .foregroundColor(.textPrimary.opacity(0.95))
                .lineSpacing(5)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.12))
                .cornerRadius(16)
        }
    }
}

// MARK: - Preview

#Preview {
    TestimonialsView()
}
