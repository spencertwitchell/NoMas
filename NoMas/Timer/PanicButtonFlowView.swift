//
//  PanicButtonFlowView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  PanicButtonFlowView.swift
//  NoMas
//
//  Full-screen panic intervention with camera, animated phrases, and action buttons
//

import SwiftUI
import Supabase
import AVFoundation

struct PanicButtonFlowView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int
    
    @State private var phrases: [String] = []
    @State private var currentPhraseIndex = 0
    @State private var revealedCharacterCount = 0
    @State private var isLoadingPhrases = true
    @State private var showingResetFlow = false
    @State private var showingMightBreakFlow = false
    @State private var isAnimationActive = true
    @State private var cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    
    // Fallback phrases if Supabase fails
    let fallbackPhrases = [
        "Recuerda por qué empezaste este camino.",
        "No cambies tu progreso por un alivio temporal.",
        "Este impulso es temporal. Lo superarás.",
        "Detente y respira profundamente.",
        "Ceder ahora solo traerá culpa después.",
        "Haz lo que tu yo futuro desearía.",
        "Esta sensación pasará. Has llegado hasta aquí.",
        "Piensa en lo orgulloso que estarás mañana.",
        "Mereces algo mejor que esta adicción.",
        "La sanación no es lineal, pero cada día cuenta.",
        "El impulso es temporal. El arrepentimiento dura más.",
        "Eres más fuerte que este momento de debilidad.",
        "Tu cerebro intenta engañarte. No caigas en la trampa.",
        "Un día a la vez. Un momento a la vez.",
        "Ya has superado impulsos antes. Puedes hacerlo de nuevo."
    ]

    
    let characterDelay: Double = 0.05
    
    var currentText: String {
        guard currentPhraseIndex < phrases.count, !phrases.isEmpty else { return "" }
        let phrase = phrases[currentPhraseIndex]
        let endIndex = phrase.index(phrase.startIndex, offsetBy: min(revealedCharacterCount, phrase.count))
        return String(phrase[..<endIndex])
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background video
                LoopingVideoBackground(videoName: "bg8")
                
                // Dark overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.backgroundGradientStart.opacity(0.5),
                        Color.backgroundGradientEnd.opacity(0.5)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with back button and logo
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        Image("nomaslogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 28)
                        
                        Spacer()
                        
                        // Invisible spacer to balance the back button
                        Spacer()
                            .frame(width: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    
                    // Camera and text combined in ZStack for overlay
                    ZStack(alignment: .bottom) {
                        // Camera area
                        Group {
                            switch cameraStatus {
                            case .authorized:
                                CameraPreviewSelfie()
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                
                            default: // .denied / .restricted / .notDetermined
                                // Show placeholder with settings link
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.black.opacity(0.4))
                                    
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white.opacity(0.3))
                                        
                                        Text("Cámara desactivada")
                                            .font(.bodySmall)
                                            .foregroundColor(.textSecondary)
                                        
                                        Button(action: {
                                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(url)
                                            }
                                        }) {
                                            Text("Habilitar en Configuración")
                                                .font(.buttonSmall)
                                                .foregroundColor(.accentGradientStart)
                                        }
                                    }
                                    .offset(y: -40)
                                }
                            }
                        }
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                        .padding(.horizontal, 24)
                        
                        // Animated text overlay
                        if !isLoadingPhrases && !phrases.isEmpty {
                            VStack {
                                Text(currentText.uppercased())
                                    .font(.titleSmall)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .frame(minHeight: 100)
                            }
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient.accent
                                    .opacity(0.7)
                            )
                            .cornerRadius(16)
                            .padding(.horizontal, 40)
                            .offset(y: -20)
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Action buttons at bottom
                    VStack(spacing: 12) {
                        Button(action: {
                            isAnimationActive = false
                            showingResetFlow = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16))
                                Text("Recaí — Reiniciar Timer")
                                    .font(.button)
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LinearGradient.accent)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            isAnimationActive = false
                            showingMightBreakFlow = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16))
                                Text("Podría Ceder")
                                    .font(.button)
                            }
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LinearGradient.accent)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingResetFlow, onDismiss: {
            // When Reset flow ends, close panic button entirely
            dismiss()
        }) {
            ResetTimerFlowView(selectedTab: $selectedTab)
        }
        .fullScreenCover(isPresented: $showingMightBreakFlow, onDismiss: {
            // When MightBreak flow ends, close panic button entirely
            dismiss()
        }) {
            MightBreakFlowView(selectedTab: $selectedTab)
        }
        .onAppear {
            cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
            isAnimationActive = true
            loadPhrasesAndStart()
        }
        .onChange(of: showingResetFlow) { _, isShowing in
            if isShowing { isAnimationActive = false }
        }
        .onChange(of: showingMightBreakFlow) { _, isShowing in
            if isShowing { isAnimationActive = false }
        }
        .onDisappear {
            isAnimationActive = false
        }
    }
    
    // MARK: - Supabase + Animation Logic
    
    private func loadPhrasesAndStart() {
        Task {
            do {
                // Fetch from Supabase
                struct PanicPhrase: Decodable {
                    let text: String
                }
                
                let response: [PanicPhrase] = try await supabase
                    .from("panic_phrases")
                    .select()
                    .execute()
                    .value
                
                if !response.isEmpty {
                    // Shuffle and take 12 random phrases
                    let shuffled = response.map { $0.text }.shuffled()
                    self.phrases = Array(shuffled.prefix(12))
                } else {
                    // Use fallback if table is empty
                    self.phrases = Array(fallbackPhrases.shuffled().prefix(12))
                }
                
                print("✅ Loaded \(self.phrases.count) panic phrases")
                
            } catch {
                print("⚠️ Failed to load panic phrases from Supabase: \(error)")
                // Use fallback
                self.phrases = Array(fallbackPhrases.shuffled().prefix(12))
            }
            
            isLoadingPhrases = false
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        animateCurrentPhrase()
    }
    
    private func animateCurrentPhrase() {
        guard isAnimationActive else { return }
        
        guard currentPhraseIndex < phrases.count else {
            // Loop back to start for continuous play
            currentPhraseIndex = 0
            animateCurrentPhrase()
            return
        }
        
        let phrase = phrases[currentPhraseIndex]
        revealedCharacterCount = 0
        
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        
        // Character-by-character reveal
        for (index, _) in phrase.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * characterDelay) { [self] in
                guard isAnimationActive else { return }
                
                revealedCharacterCount = index + 1
                haptic.impactOccurred(intensity: 0.5)
                
                // After last character, wait then move to next phrase
                if index == phrase.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
                        guard isAnimationActive else { return }
                        currentPhraseIndex += 1
                        animateCurrentPhrase()
                    }
                }
            }
        }
    }
}

// MARK: - Camera Preview (Front-facing, Mirrored)

private struct CameraPreviewSelfie: UIViewRepresentable {
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
    
    private let session = AVCaptureSession()
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.videoLayer.videoGravity = .resizeAspectFill
        
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Use the FRONT camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        
        session.commitConfiguration()
        view.videoLayer.session = session
        
        // Mirror so it feels like a reflection
        if let conn = view.videoLayer.connection, conn.isVideoMirroringSupported {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    
    static func dismantleUIView(_ uiView: PreviewView, coordinator: ()) {
        uiView.videoLayer.session?.stopRunning()
    }
}

#Preview {
    PanicButtonFlowView(selectedTab: .constant(0))
}
