//
//  CommunityView.swift
//  NoMas
//
//  Main community feed view
//

import SwiftUI
import Supabase

struct CommunityView: View {
    @State private var posts: [Post] = []
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var showingCreatePost = false
    @State private var showingDeleteAlert = false
    @State private var postToDelete: Post?
    @State private var selectedPost: Post?
    
    private var userData: UserData { UserData.shared }
    
    var filteredPosts: [Post] {
        if searchText.isEmpty {
            return posts
        }
        return posts.filter { post in
            post.title.localizedCaseInsensitiveContains(searchText) ||
            post.body.localizedCaseInsensitiveContains(searchText) ||
            post.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Background handled by MainView
            
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textTertiary)
                        .font(.system(size: 16))
                    
                    TextField("", text: $searchText)
                        .placeholder(when: searchText.isEmpty) {
                            Text("Search posts...")
                                .foregroundColor(.textTertiary)
                        }
                        .foregroundColor(.textPrimary)
                        .font(.body)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.surfaceBackground)
                .cornerRadius(25)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Posts feed
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.textPrimary)
                    Spacer()
                } else if filteredPosts.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.textTertiary)
                        Text(searchText.isEmpty ? "No posts yet" : "No results found")
                            .foregroundColor(.textSecondary)
                            .font(.bodyLarge)
                        if searchText.isEmpty {
                            Text("Be the first to share your journey")
                                .foregroundColor(.textTertiary)
                                .font(.bodySmall)
                        }
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(filteredPosts.enumerated()), id: \.element.id) { _, post in
                                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                                    Button {
                                        selectedPost = posts[index]
                                    } label: {
                                        PostCardView(
                                            post: $posts[index],
                                            onDelete: {
                                                postToDelete = posts[index]
                                                showingDeleteAlert = true
                                            },
                                            onRefresh: {
                                                Task { await loadPosts() }
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await loadPosts()
                    }
                }
            }
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showingCreatePost = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(LinearGradient.accent)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView(onPostCreated: {
                Task {
                    await loadPosts()
                }
            })
        }
        .alert("Delete Post", isPresented: $showingDeleteAlert, presenting: postToDelete) { post in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePost(post)
                }
            }
        } message: { _ in
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .fullScreenCover(item: $selectedPost) { post in
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                PostDetailView(
                    post: posts[index],
                    onUpvoteChanged: { newCount in
                        posts[index].upvoteCount = newCount
                    },
                    onPostDeleted: {
                        selectedPost = nil
                        Task { await loadPosts() }
                    }
                )
            }
        }
        .task {
            await loadPosts()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadPosts() async {
        isLoading = true
        
        do {
            print("ðŸ”µ Loading posts from Supabase...")
            
            let response: [PostResponse] = try await supabase
                .from("posts")
                .select("*, users(display_name, profile_picture_url, is_profile_public)")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            print("ðŸ”µ Raw response count: \(response.count)")
            
            posts = response.compactMap { postResponse in
                let post = postResponse.toPost()
                if post == nil {
                    print("âŒ Failed to convert post: \(postResponse.id)")
                }
                return post
            }
            
            print("âœ… Successfully loaded \(posts.count) posts")
            isLoading = false
        } catch {
            print("âŒ Failed to load posts: \(error)")
            isLoading = false
        }
    }
    
    private func deletePost(_ post: Post) async {
        guard let userId = userData.supabaseUserId else { return }
        guard post.userId == userId else { return }
        
        do {
            try await supabase
                .from("posts")
                .delete()
                .eq("id", value: post.id.uuidString)
                .execute()
            
            print("âœ… Deleted post")
            await loadPosts()
        } catch {
            print("âŒ Failed to delete post: \(error)")
        }
    }
}

// MARK: - Post Card View

struct PostCardView: View {
    @Binding var post: Post
    @State private var isUpvoting = false
    @State private var showingUserProfile = false
    let onDelete: () -> Void
    let onRefresh: () -> Void
    
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with user info
            HStack(spacing: 12) {
                // Profile picture - opens user profile if public
                if post.isAnonymous {
                    ProfilePictureView(
                        userName: post.userName,
                        profilePictureURL: post.profilePictureURL,
                        isPublic: false,
                        size: 40
                    )
                } else {
                    Button {
                        showingUserProfile = true
                    } label: {
                        ProfilePictureView(
                            userName: post.userName,
                            profilePictureURL: post.profilePictureURL,
                            isPublic: true,
                            size: 40
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.displayName)
                        .foregroundColor(.textPrimary)
                        .font(.titleSmall)
                    
                    Text(post.timeAgo)
                        .foregroundColor(.textSecondary)
                        .font(.captionSmall)
                }
                
                Spacer()
                
                // Menu button
                Menu {
                    if post.userId == userData.supabaseUserId {
                        Button(role: .destructive) {
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await reportPost()
                        }
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.textPrimary)
                        .font(.system(size: 16, weight: .bold))
                }
                
                // Upvote button
                VStack(spacing: 4) {
                    Button {
                        Task {
                            await upvotePost()
                        }
                    } label: {
                        Image(systemName: "arrowtriangle.up.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                    }
                    .disabled(isUpvoting)
                    
                    Text("\(post.upvoteCount)")
                        .foregroundColor(.textPrimary)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .padding(16)
            
            // Post content
            VStack(alignment: .leading, spacing: 12) {
                Text(post.title)
                    .foregroundColor(.textPrimary)
                    .font(.titleMedium)
                    .lineLimit(2)
                
                Text(post.body)
                    .foregroundColor(.textPrimary.opacity(0.9))
                    .font(.bodySmall)
                    .lineLimit(4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Arrow indicator
            HStack {
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(.textSecondary)
                    .font(.system(size: 16))
                    .padding(.trailing, 16)
                    .padding(.bottom, 12)
            }
        }
        .background(LinearGradient.accent)
        .cornerRadius(16)
        .fullScreenCover(isPresented: $showingUserProfile) {
            UserProfileView(userId: post.userId)
        }
    }
    
    private func upvotePost() async {
        guard !isUpvoting else { return }
        isUpvoting = true
        
        // Immediately update local count for instant feedback
        post.upvoteCount += 1
        
        do {
            try await supabase
                .rpc("increment_post_upvote", params: ["post_uuid": post.id.uuidString])
                .execute()
            
            print("âœ… Upvoted post - new count: \(post.upvoteCount)")
            isUpvoting = false
        } catch {
            post.upvoteCount -= 1
            print("âŒ Failed to upvote: \(error)")
            isUpvoting = false
        }
    }
    
    private func reportPost() async {
        guard let userId = userData.supabaseUserId else { return }
        
        do {
            struct ReportInsert: Encodable {
                let post_id: String
                let user_id: String
            }
            
            try await supabase
                .from("post_reports")
                .insert(ReportInsert(
                    post_id: post.id.uuidString,
                    user_id: userId.uuidString
                ))
                .execute()
            
            print("âœ… Reported post")
        } catch {
            if error.localizedDescription.contains("duplicate") || error.localizedDescription.contains("unique") {
                print("âš ï¸ You've already reported this post")
            } else {
                print("âŒ Failed to report post: \(error)")
            }
        }
    }
}

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppBackground()
        CommunityView()
    }
}
