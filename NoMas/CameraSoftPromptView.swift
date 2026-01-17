import SwiftUI
import Lottie
import AVFoundation

struct CameraSoftPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userData = UserData.shared
    
    var body: some View {
        ZStack {
            AppBackground()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Lottie animation
                LottieView(animation: .named("cameraperms"))
                    .playing(loopMode: .loop)
                    .frame(width: 200, height: 200)
                
                // Header
                Text("Desbloquear acceso a la cámara")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("Usamos tu cámara para funciones opcionales que mejoran tu experiencia en NoMás. Puedes habilitarla ahora o más tarde en Configuración. (Opcional)")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue button
                Button {
                    requestCameraPermission()
                } label: {
                    Text("Continuar")
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.accent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            // Dismiss on main thread regardless of user's choice
            DispatchQueue.main.async {
                // Mark that the user has seen the camera prompt so it never shows again
                userData.hasSeenCameraPrompt = true
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CameraSoftPromptView()
}
