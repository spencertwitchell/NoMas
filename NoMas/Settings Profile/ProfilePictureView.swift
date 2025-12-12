//
//  ProfilePictureView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/11/25.
//


//
//  ProfilePictureView.swift
//  NoMas
//
//  Reusable profile picture component used throughout the app
//

import SwiftUI
import Combine

struct ProfilePictureView: View {
    let userName: String?
    let profilePictureURL: String?
    let isPublic: Bool
    let size: CGFloat
    
    // For generating initials as fallback
    private var initials: String {
        guard let name = userName, !name.isEmpty else { return "?" }
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
    
    var body: some View {
        if let url = profilePictureURL, !url.isEmpty, isPublic {
            // Has profile picture - use AsyncImage
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .empty:
                    // Loading state
                    ZStack {
                        Circle()
                            .fill(LinearGradient.accent)
                            .frame(width: size, height: size)
                        
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(size > 60 ? 1.0 : 0.7)
                    }
                    
                case .success(let image):
                    // Success state
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                    
                case .failure(_):
                    // Failed to load - show initials
                    initialsView
                    
                @unknown default:
                    initialsView
                }
            }
        } else {
            // No profile picture - show initials
            initialsView
        }
    }
    
    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.accent)
                .frame(width: size, height: size)
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppBackground()
        
        VStack(spacing: 20) {
            // Large profile picture (like in profile pages)
            ProfilePictureView(
                userName: "Test User",
                profilePictureURL: nil,
                isPublic: true,
                size: 100
            )
            
            // Medium profile picture (like in posts)
            ProfilePictureView(
                userName: "Test User",
                profilePictureURL: nil,
                isPublic: true,
                size: 40
            )
            
            // Small profile picture (like in comments)
            ProfilePictureView(
                userName: "Test User",
                profilePictureURL: nil,
                isPublic: true,
                size: 32
            )
        }
    }
}
