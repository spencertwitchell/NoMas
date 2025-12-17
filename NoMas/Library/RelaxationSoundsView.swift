//
//  RelaxationSoundsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/16/25.
//


//
//  RelaxationSoundsView.swift
//  NoMas
//
//  Grid view for selecting relaxation/meditation sounds
//

import SwiftUI
import Supabase

struct RelaxationSoundsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var sounds: [RelaxationSound] = RelaxationSound.fallbackSounds
    @State private var isLoading = false
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(sounds) { sound in
                                NavigationLink(destination: SoundPlayerView(sound: sound)) {
                                    SoundCard(sound: sound)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Guided Meditation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Guided Meditation")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.bodySmall)
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                await fetchSounds()
            }
        }
    }
    
    private func fetchSounds() async {
        isLoading = true
        
        do {
            let fetchedSounds: [RelaxationSound] = try await supabase
                .from("relaxation_sounds")
                .select()
                .order("sort")
                .execute()
                .value
            
            if !fetchedSounds.isEmpty {
                sounds = fetchedSounds
            }
            print("✅ Loaded \(sounds.count) relaxation sounds")
        } catch {
            print("⚠️ Using fallback sounds: \(error.localizedDescription)")
            // Keep using fallback sounds
        }
        
        isLoading = false
    }
}

// MARK: - Sound Card

struct SoundCard: View {
    let sound: RelaxationSound
    
    var body: some View {
        VStack(spacing: 0) {
            // Cover image from URL
            AsyncImage(url: URL(string: sound.coverImageUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.surfaceBackground)
                        .frame(height: 200)
                        .overlay(ProgressView().tint(.white))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.surfaceBackground)
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.textTertiary)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.surfaceBackground)
                        .frame(height: 200)
                }
            }
            .cornerRadius(12, corners: [.topLeft, .topRight])
            
            // Sound name
            VStack(spacing: 8) {
                Text(sound.name)
                    .font(.buttonSmall)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color.surfaceBackground)
            .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Selective Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    RelaxationSoundsView()
}
