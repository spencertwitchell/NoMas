//
//  MainView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/11/25.
//

import SwiftUI

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

// MARK: - Tab Views
// NOTE: TimerView has been moved to TimerView.swift

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

struct CommunityView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentGradientStart)
                
                Text("Community")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Connect with others coming soon")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Placeholder Sheet Views

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userData = UserData.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var showingSettings = false
    
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
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                    Text("@\(instagram)")
                                        .font(.bodySmall)
                                }
                                .foregroundColor(.accentGradientStart)
                            }
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
        }
    }
}

// MARK: - Stat Row

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
