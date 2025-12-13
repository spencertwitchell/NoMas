//
//  UserProfileView.swift
//  NoMas
//
//  View for displaying another user's public profile
//

import SwiftUI
import Supabase

struct UserProfileView: View {
    let userId: UUID
    @Environment(\.dismiss) var dismiss
    @State private var profile: CommunityUserProfile? = nil
    @State private var userPosts: [Post] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            AppBackground()
            
            if isLoading {
                ProgressView()
                    .tint(.textPrimary)
            } else if let profile = profile {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card
                        ProfileCardView(
                            userName: profile.userName,
                            bio: profile.bio,
                            instagramHandle: profile.instagramHandle,
                            profilePictureURL: profile.profilePictureURL
                        )
                        
                        // User's Posts Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(profile.userName)'s Posts")
                                .font(.titleSmall)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 20)
                            
                            if userPosts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 40))
                                        .foregroundColor(.textTertiary)
                                    Text("No posts yet")
                                        .foregroundColor(.textSecondary)
                                        .font(.bodySmall)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 16) {
                                    ForEach(Array(userPosts.enumerated()), id: \.element.id) { index, post in
                                        let onUpvoteChanged: (Int) -> Void = { newCount in
                                            userPosts[index].upvoteCount = newCount
                                        }
                                        NavigationLink(destination: PostDetailView(
                                            post: userPosts[index],
                                            onUpvoteChanged: onUpvoteChanged
                                        )) {
                                            UserPostCardView(post: $userPosts[index])
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.textTertiary)
                    Text("Profile not found or private")
                        .foregroundColor(.textSecondary)
                        .font(.body)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
            }
        }
        .task {
            await loadProfile()
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        
        do {
            // Load profile from users table
            struct ProfileData: Decodable {
                let display_name: String?
                let bio: String?
                let instagram_handle: String?
                let profile_picture_url: String?
                let is_profile_public: Bool?
            }
            
            let profileResponse: [ProfileData] = try await supabase
                .from("users")
                .select("display_name, bio, instagram_handle, profile_picture_url, is_profile_public")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            guard let profileData = profileResponse.first else {
                print("❌ Profile not found")
                isLoading = false
                return
            }
            
            // Only show profile if it's public
            guard profileData.is_profile_public == true else {
                print("❌ Profile is private")
                isLoading = false
                return
            }
            
            profile = CommunityUserProfile(
                id: userId,
                userName: profileData.display_name ?? "Anonymous",
                bio: profileData.bio,
                instagramHandle: profileData.instagram_handle,
                profilePictureURL: profileData.profile_picture_url
            )
            
            // Load user's posts
            let postsResponse: [PostResponse] = try await supabase
                .from("posts")
                .select("*, users(display_name, profile_picture_url, is_profile_public)")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            userPosts = postsResponse.compactMap { $0.toPost() }
            
            print("✅ Loaded profile and \(userPosts.count) posts")
            isLoading = false
        } catch {
            print("❌ Failed to load profile: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Profile Card View

struct ProfileCardView: View {
    let userName: String
    let bio: String?
    let instagramHandle: String?
    let profilePictureURL: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            ProfilePictureView(
                userName: userName,
                profilePictureURL: profilePictureURL,
                isPublic: true,
                size: 100
            )
            
            // Name
            Text(userName)
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            // Bio
            if let bio = bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Instagram
            if let instagram = instagramHandle, !instagram.isEmpty {
                Button {
                    if let url = URL(string: "https://instagram.com/\(instagram)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.system(size: 14))
                        Text("@\(instagram)")
                            .font(.bodySmall)
                    }
                    .foregroundColor(.accentGradientStart)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color.surfaceBackground)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
}

// MARK: - User Post Card (for profile pages)

struct UserPostCardView: View {
    @Binding var post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(post.title)
                    .foregroundColor(.textPrimary)
                    .font(.titleSmall)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "arrowtriangle.up.circle.fill")
                        .foregroundStyle(LinearGradient.accent)
                        .font(.system(size: 20))
                    
                    Text("\(post.upvoteCount)")
                        .foregroundColor(.textPrimary)
                        .font(.captionSmall)
                        .fontWeight(.semibold)
                }
            }
            
            Text(post.body)
                .foregroundColor(.textPrimary.opacity(0.9))
                .font(.bodySmall)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            HStack {
                Text(post.timeAgo)
                    .foregroundColor(.textSecondary)
                    .font(.captionSmall)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.textSecondary)
                    .font(.system(size: 14))
            }
        }
        .padding(16)
        .background(LinearGradient.accent)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView(userId: UUID())
    }
}
