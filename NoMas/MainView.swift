//
//  MainView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/11/25.
//
//  UPDATED: Integrated NomiConversationsListView to replace ChatView placeholder
//

import SwiftUI
import Supabase
import Combine
import Lottie

// MARK: - Main View

struct MainView: View {
    @State private var selectedTab = 0
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var nomiViewModel = NomiViewModel() // Added for Nomi chat
    
    // Computed property to determine if header should be hidden
    private var shouldHideHeader: Bool {
        selectedTab == 1 && !nomiViewModel.hasCompletedQuiz
    }
    
    var body: some View {
        ZStack {
            // Persistent background
            AppBackground()
            
            VStack(spacing: 0) {
                // Header - conditionally hidden for Nomi welcome state
                if !shouldHideHeader {
                    MainHeaderView(title: tabTitle)
                }
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    TimerView(selectedTab: $selectedTab)
                        .tag(0)
                    
                    // UPDATED: Replace ChatView with NomiConversationsListView
                    NomiConversationsListView(viewModel: nomiViewModel)
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

// MARK: - Profile View

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var userData = UserData.shared
    @State private var showingSettings = false
    @State private var userPosts: [Post] = []
    @State private var isLoadingPosts = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Card (matching UserProfileView styling)
                        ProfileCardView(
                            userName: userData.displayName,
                            bio: userData.bio,
                            instagramHandle: userData.instagramHandle,
                            profilePictureURL: userData.profilePictureURL
                        )
                        .padding(.top, 20)
                        
                        // Recovery Stats with Milestone Styling
                        RecoveryStatsCard(userData: userData)
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

// MARK: - Recovery Stats Card (with Milestone Styling)

struct RecoveryStatsCard: View {
    @ObservedObject var userData: UserData
    
    private var milestone: Milestone {
        userData.currentMilestone
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Rank Section: Animation on left, text on right
            HStack(spacing: 16) {
                // Lottie Animation
                LottieView(animation: .named(milestone.animationName))
                    .playing(loopMode: .loop)
                    .animationSpeed(0.67)
                    .frame(width: 70, height: 70)
                    .scaleEffect(1.2)
                
                // Current Rank Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Rank")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(milestone.displayName)
                        .font(.titleMedium)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Text(milestone.title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 8)
            
            // Stats Rows
            VStack(spacing: 12) {
                RecoveryStatRow(label: "Days in App", value: "\(userData.daysInApp)")
                RecoveryStatRow(label: "Current Streak", value: "\(userData.daysSinceRelapse) days")
                RecoveryStatRow(label: "Best Streak", value: "\(userData.effectiveBestStreak) days")
                RecoveryStatRow(label: "Times Relapsed", value: "\(userData.timesRelapsed)")
                RecoveryStatRow(label: "Dependency Score", value: "\(Int(userData.dependencyScore))%")
                if let projectedDate = userData.projectedRecoveryDate {
                    RecoveryStatRow(label: "Projected Recovery", value: projectedDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Gradient layer
                RoundedRectangle(cornerRadius: 16)
                    .fill(milestone.gradient)
                
                // Dark overlay for readability
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.35))
            }
        )
        .overlay(
            // 3pt gradient border
            RoundedRectangle(cornerRadius: 16)
                .stroke(milestone.gradient, lineWidth: 3)
        )
    }
}

// MARK: - Recovery Stat Row

struct RecoveryStatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.white)
                .fontWeight(.medium)
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

// MARK: - Stat Components (kept for backwards compatibility)

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
