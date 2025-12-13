//
//  MainView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/11/25.
//

import SwiftUI
import Supabase

// MARK: - Main View

struct MainView: View {
    @State private var selectedTab = 0
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        ZStack {
            // Persistent background
            AppBackground()
            
            VStack(spacing: 0) {
                // Header
                MainHeaderView(title: tabTitle)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    TimerView(selectedTab: $selectedTab)
                        .tag(0)
                    
                    ChatView()
                        .tag(1)
                    
                    LibraryView()
                        .tag(2)
                    
                    CommunityView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom Tab Bar
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
    
    private var tabTitle: String {
        switch selectedTab {
        case 0: return "Timer"
        case 1: return "Chat"
        case 2: return "Library"
        case 3: return "Community"
        default: return ""
        }
    }
}

// MARK: - Main Header View

struct MainHeaderView: View {
    let title: String
    
    @StateObject private var userData = UserData.shared
    @State private var showingProfile = false
    @State private var showingMilestones = false
    
    var body: some View {
        ZStack {
            // Centered logo
            HStack {
                Spacer()
                Image("nomaslogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 28)
                Spacer()
            }
            
            // Left and right items
            HStack {
                // Title on the left
                Text(title)
                    .font(.titleSmall)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                // Streak + Profile
                HStack(spacing: 12) {
                    // Streak button (opens milestones)
                    Button(action: {
                        showingMilestones = true
                    }) {
                        HStack(spacing: 6) {
                            // Gradient flame icon
                            Image(systemName: "flame.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(userData.currentMilestone.gradient)
                            
                            Text("\(userData.daysSinceRelapse)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPrimary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.surfaceBackground)
                        .cornerRadius(16)
                    }
                    
                    // Profile button
                    Button(action: {
                        showingProfile = true
                    }) {
                        ProfileAvatarView(
                            name: userData.displayName,
                            profilePictureURL: userData.profilePictureURL,
                            size: 32
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingMilestones) {
            MilestonesSheetView()
        }
    }
}

// MARK: - Profile Avatar View

struct ProfileAvatarView: View {
    let name: String
    let profilePictureURL: String?
    var size: CGFloat = 32
    
    var body: some View {
        ProfilePictureView(
            userName: name,
            profilePictureURL: profilePictureURL,
            isPublic: true,
            size: size
        )
    }
}

// Legacy initializer for backwards compatibility
extension ProfileAvatarView {
    init(name: String, size: CGFloat = 32) {
        self.name = name
        self.profilePictureURL = nil
        self.size = size
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs: [(icon: String, label: String)] = [
        ("timer", "Timer"),
        ("ellipsis.message.fill", "Chat"),
        ("book.pages.fill", "Library"),
        ("person.3.fill", "Community")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabBarButton(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            Color.backgroundGradientEnd
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .accentGradientStart : .textTertiary)
                
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .accentGradientStart : .textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Tab Views (Placeholders)
// NOTE: TimerView has been moved to TimerView.swift
// NOTE: CommunityView has been moved to CommunityView.swift

struct ChatView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "ellipsis.message.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentGradientStart)
                
                Text("Chat")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("AI-powered support coming soon")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
}

struct LibraryView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentGradientStart)
                
                Text("Library")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Recovery resources coming soon")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Profile View (with Your Posts)

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var showingSettings = false
    @State private var userPosts: [Post] = []
    @State private var isLoadingPosts = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card
                        VStack(spacing: 16) {
                            // Profile Picture
                            ProfilePictureView(
                                userName: userData.displayName,
                                profilePictureURL: userData.profilePictureURL,
                                isPublic: true,
                                size: 100
                            )
                            
                            // Name
                            Text(userData.displayName.isEmpty ? "User" : userData.displayName)
                                .font(.titleLarge)
                                .foregroundColor(.textPrimary)
                            
                            // Bio (if exists)
                            if let bio = userData.bio, !bio.isEmpty {
                                Text(bio)
                                    .font(.body)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Instagram (if exists)
                            if let instagram = userData.instagramHandle, !instagram.isEmpty {
                                Button {
                                    if let url = URL(string: "https://instagram.com/\(instagram)") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                            .font(.caption)
                                        Text("@\(instagram)")
                                            .font(.bodySmall)
                                    }
                                    .foregroundColor(.accentGradientStart)
                                }
                            }
                            
                            // Privacy indicator
                            HStack(spacing: 6) {
                                Image(systemName: userData.isProfilePublic ? "eye" : "eye.slash")
                                    .font(.system(size: 12))
                                Text(userData.isProfilePublic ? "Public Profile" : "Private Profile")
                                    .font(.captionSmall)
                            }
                            .foregroundColor(.textTertiary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(Color.surfaceBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Stats
                        HStack(spacing: 16) {
                            StatBox(value: "\(userData.daysSinceRelapse)", label: "Days Clean")
                            StatBox(value: userData.currentMilestone.displayName, label: "Milestone")
                        }
                        .padding(.horizontal, 20)
                        
                        // Recovery Stats
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recovery Stats")
                                .font(.titleSmall)
                                .foregroundColor(.textPrimary)
                            
                            VStack(spacing: 12) {
                                StatRow(label: "Days in App", value: "\(userData.daysInApp)")
                                StatRow(label: "Current Streak", value: "\(userData.daysSinceRelapse) days")
                                StatRow(label: "Best Streak", value: "\(userData.effectiveBestStreak) days")
                                StatRow(label: "Times Relapsed", value: "\(userData.timesRelapsed)")
                                StatRow(label: "Dependency Score", value: "\(Int(userData.dependencyScore))%")
                                if let projectedDate = userData.projectedRecoveryDate {
                                    StatRow(label: "Projected Recovery", value: projectedDate.formatted(date: .abbreviated, time: .omitted))
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.surfaceBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // Your Posts Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Posts")
                                .font(.titleSmall)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 20)
                            
                            if isLoadingPosts {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.textPrimary)
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            } else if userPosts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 40))
                                        .foregroundColor(.textTertiary)
                                    Text("You haven't posted anything yet")
                                        .foregroundColor(.textSecondary)
                                        .font(.bodySmall)
                                    Text("Share your journey in the Community tab")
                                        .foregroundColor(.textTertiary)
                                        .font(.captionSmall)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
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
                                            ProfilePostCardView(post: $userPosts[index])
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textPrimary)
                            .font(.system(size: 16))
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Your Profile")
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.textPrimary)
                            .font(.system(size: 16))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await loadUserPosts()
            }
        }
    }
    
    private func loadUserPosts() async {
        guard let userId = userData.supabaseUserId else {
            print("❌ No user ID for loading posts")
            return
        }
        
        isLoadingPosts = true
        
        do {
            let response: [PostResponse] = try await supabase
                .from("posts")
                .select("*, users(display_name, profile_picture_url, is_profile_public)")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            userPosts = response.compactMap { $0.toPost() }
            print("✅ Loaded \(userPosts.count) user posts")
            isLoadingPosts = false
        } catch {
            print("❌ Failed to load user posts: \(error)")
            isLoadingPosts = false
        }
    }
}

// MARK: - Profile Post Card (for ProfileView)

struct ProfilePostCardView: View {
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

// MARK: - Stat Components

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.textPrimary)
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
