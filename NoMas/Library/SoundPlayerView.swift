//
//  SoundPlayerView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/16/25.
//


//
//  SoundPlayerView.swift
//  NoMas
//
//  Full-screen audio player for relaxation sounds
//

import SwiftUI

struct SoundPlayerView: View {
    let sound: RelaxationSound
    @StateObject private var audioManager = RelaxationAudioManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Full background cover image from URL
            AsyncImage(url: URL(string: sound.coverImageUrl)) { phase in
                switch phase {
                case .empty:
                    Color.backgroundGradientEnd
                        .overlay(ProgressView().tint(.white))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Color.backgroundGradientEnd
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.textTertiary)
                        )
                @unknown default:
                    Color.backgroundGradientEnd
                }
            }
            .ignoresSafeArea()
            
            // Dark overlay for readability
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack {
                // Top section with back button
                HStack {
                    Button(action: {
                        audioManager.stop()
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Sound name
                Text(sound.name)
                    .font(.titleLarge)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                // Timer display
                Text(formatTime(audioManager.currentTime))
                    .font(.system(size: 48, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 40)
                
                // Play/Pause button with loading state
                Button(action: {
                    if !audioManager.isLoading {
                        audioManager.togglePlayPause()
                    }
                }) {
                    ZStack {
                        if audioManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2.0)
                        } else {
                            Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        }
                    }
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .disabled(audioManager.isLoading)
                .padding(.bottom, 80)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard let audioURL = URL(string: sound.audioUrl) else {
                print("❌ Invalid audio URL: \(sound.audioUrl)")
                return
            }
            audioManager.playSound(from: audioURL, named: sound.name)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview {
    SoundPlayerView(sound: RelaxationSound.fallbackSounds[0])
}