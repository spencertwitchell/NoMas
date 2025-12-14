//
//  PostDetailView.swift
//  NoMas
//
//  Detailed view of a single post with comments
//

import SwiftUI
import Supabase

struct PostDetailView: View {
    @State var post: Post
    var onUpvoteChanged: ((Int) -> Void)?
    var onPostDeleted: (() -> Void)?
    @Environment(\.dismiss) var dismiss
    
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoadingComments = false
    @State private var isSubmittingComment = false
    @State private var replyingTo: Comment? = nil
    @State private var showingDeletePostAlert = false
    @State private var showingDeleteCommentAlert = false
    @State private var commentToDelete: Comment? = nil
    @State private var isUpvotingPost = false
    @State private var selectedUserId: UUID? = nil
    
    private var userData: UserData { UserData.shared }
    
    var topLevelComments: [Comment] {
        return comments.filter { $0.parentCommentId == nil }
    }
    
    var body: some View {
        ZStack {
            AppBackground()
                
                VStack(spacing: 0) {
                    // Custom header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Post")
                            .font(.titleSmall)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        // Invisible spacer to balance the back button
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Post content
                    ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Post card
                        VStack(alignment: .leading, spacing: 0) {
                            // Header
                            HStack(spacing: 12) {
                                if post.isAnonymous {
                                    ProfilePictureView(
                                        userName: post.userName,
                                        profilePictureURL: post.profilePictureURL,
                                        isPublic: false,
                                        size: 40
                                    )
                                } else {
                                    Button {
                                        selectedUserId = post.userId
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
                                
                                Menu {
                                    if post.userId == userData.supabaseUserId {
                                        Button(role: .destructive) {
                                            showingDeletePostAlert = true
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
                                    .disabled(isUpvotingPost)
                                    
                                    Text("\(post.upvoteCount)")
                                        .foregroundColor(.textPrimary)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(16)
                            
                            // Post content (full, not truncated)
                            VStack(alignment: .leading, spacing: 12) {
                                Text(post.title)
                                    .foregroundColor(.textPrimary)
                                    .font(.titleMedium)
                                
                                Text(post.body)
                                    .foregroundColor(.textPrimary.opacity(0.9))
                                    .font(.bodySmall)
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .background(LinearGradient.accent)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Comments Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Comments")
                                .font(.titleSmall)
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 20)
                                .padding(.top, 24)
                            
                            if isLoadingComments {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.textPrimary)
                                    Spacer()
                                }
                                .padding()
                            } else if topLevelComments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left")
                                        .font(.system(size: 40))
                                        .foregroundColor(.textTertiary)
                                    Text("No comments yet")
                                        .foregroundColor(.textSecondary)
                                        .font(.bodySmall)
                                    Text("Be the first to share your thoughts")
                                        .foregroundColor(.textTertiary)
                                        .font(.captionSmall)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(topLevelComments) { comment in
                                        CommentView(
                                            comment: comment,
                                            allComments: comments,
                                            onReply: { selectedComment in
                                                replyingTo = selectedComment
                                            },
                                            onDelete: { commentToDeleteParam in
                                                commentToDelete = commentToDeleteParam
                                                showingDeleteCommentAlert = true
                                            },
                                            onProfileTap: { userId in
                                                selectedUserId = userId
                                            }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 120) // Space for input
                    }
                }
                
                // Comment input bar
                VStack(spacing: 0) {
                    // Reply indicator
                    if let replyingTo = replyingTo {
                        HStack {
                            Text("Replying to \(replyingTo.displayName)")
                                .foregroundColor(.textSecondary)
                                .font(.captionSmall)
                            
                            Spacer()
                            
                            Button {
                                self.replyingTo = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.textTertiary)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.surfaceBackground)
                    }
                    
                    // Input field
                    HStack(spacing: 12) {
                        TextField("", text: $newCommentText)
                            .placeholder(when: newCommentText.isEmpty) {
                                Text("Add a comment...")
                                    .foregroundColor(.textTertiary)
                            }
                            .foregroundColor(.textPrimary)
                            .font(.body)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.surfaceBackground)
                            .cornerRadius(25)
                        
                        Button {
                            Task {
                                await submitComment()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.accent)
                                    .frame(width: 44, height: 44)
                                
                                if isSubmittingComment {
                                    ProgressView()
                                        .tint(.textPrimary)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.textPrimary)
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                        }
                        .disabled(newCommentText.isEmpty || isSubmittingComment)
                        .opacity(newCommentText.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.backgroundGradientEnd)
                }
            }
        }
        .alert("Delete Post", isPresented: $showingDeletePostAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePost()
                }
            }
        } message: {
            Text("Are you sure you want to delete this post?")
        }
        .alert("Delete Comment", isPresented: $showingDeleteCommentAlert, presenting: commentToDelete) { _ in
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let comment = commentToDelete {
                    Task {
                        await deleteComment(comment)
                    }
                }
            }
        } message: { _ in
            Text("Are you sure you want to delete this comment?")
        }
        .fullScreenCover(item: $selectedUserId) { userId in
            UserProfileView(userId: userId)
        }
        .task {
            await loadComments()
        }
    }
    
    // MARK: - Post Actions
    
    private func upvotePost() async {
        guard !isUpvotingPost else { return }
        isUpvotingPost = true
        
        post.upvoteCount += 1
        onUpvoteChanged?(post.upvoteCount)
        
        do {
            try await supabase
                .rpc("increment_post_upvote", params: ["post_uuid": post.id.uuidString])
                .execute()
            
            print("âœ… Upvoted post")
            isUpvotingPost = false
        } catch {
            post.upvoteCount -= 1
            onUpvoteChanged?(post.upvoteCount)
            print("âŒ Failed to upvote: \(error)")
            isUpvotingPost = false
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
            print("âŒ Failed to report post: \(error)")
        }
    }
    
    private func deletePost() async {
        guard let userId = userData.supabaseUserId else { return }
        guard post.userId == userId else { return }
        
        do {
            try await supabase
                .from("posts")
                .delete()
                .eq("id", value: post.id.uuidString)
                .execute()
            
            print("âœ… Deleted post")
            onPostDeleted?()
            dismiss()
        } catch {
            print("âŒ Failed to delete post: \(error)")
        }
    }
    
    // MARK: - Comment Actions
    
    private func loadComments() async {
        isLoadingComments = true
        
        do {
            let response: [CommentResponse] = try await supabase
                .from("comments")
                .select("*, users(display_name, profile_picture_url, is_profile_public)")
                .eq("post_id", value: post.id.uuidString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            comments = response.compactMap { $0.toComment() }
            print("âœ… Loaded \(comments.count) comments")
            isLoadingComments = false
        } catch {
            print("âŒ Failed to load comments: \(error)")
            isLoadingComments = false
        }
    }
    
    private func submitComment() async {
        guard let userId = userData.supabaseUserId else { return }
        guard !newCommentText.isEmpty else { return }
        
        isSubmittingComment = true
        
        do {
            struct CommentInsert: Encodable {
                let post_id: String
                let user_id: String
                let body: String
                let parent_comment_id: String?
            }
            
            let comment = CommentInsert(
                post_id: post.id.uuidString,
                user_id: userId.uuidString,
                body: newCommentText,
                parent_comment_id: replyingTo?.id.uuidString
            )
            
            try await supabase
                .from("comments")
                .insert(comment)
                .execute()
            
            print("âœ… Comment submitted")
            newCommentText = ""
            replyingTo = nil
            await loadComments()
            isSubmittingComment = false
        } catch {
            print("âŒ Failed to submit comment: \(error)")
            isSubmittingComment = false
        }
    }
    
    private func deleteComment(_ comment: Comment) async {
        guard let userId = userData.supabaseUserId else { return }
        guard comment.userId == userId else { return }
        
        do {
            try await supabase
                .from("comments")
                .delete()
                .eq("id", value: comment.id.uuidString)
                .execute()
            
            print("âœ… Deleted comment")
            await loadComments()
        } catch {
            print("âŒ Failed to delete comment: \(error)")
        }
    }
}

// MARK: - Comment View

struct CommentView: View {
    @State var comment: Comment
    let allComments: [Comment]
    let onReply: (Comment) -> Void
    let onDelete: (Comment) -> Void
    let onProfileTap: (UUID) -> Void
    
    @State private var isUpvoting = false
    
    private var userData: UserData { UserData.shared }
    
    var replies: [Comment] {
        allComments.filter { $0.parentCommentId == comment.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // Profile picture
                if comment.isAnonymous {
                    ProfilePictureView(
                        userName: comment.userName,
                        profilePictureURL: comment.profilePictureURL,
                        isPublic: false,
                        size: 32
                    )
                } else {
                    Button {
                        onProfileTap(comment.userId)
                    } label: {
                        ProfilePictureView(
                            userName: comment.userName,
                            profilePictureURL: comment.profilePictureURL,
                            isPublic: true,
                            size: 32
                        )
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(comment.displayName)
                            .foregroundColor(.textPrimary)
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text(comment.timeAgo)
                            .foregroundColor(.textSecondary)
                            .font(.captionSmall)
                        
                        Spacer()
                        
                        // Menu
                        Menu {
                            if comment.userId == userData.supabaseUserId {
                                Button(role: .destructive) {
                                    onDelete(comment)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            
                            Button(role: .destructive) {
                                Task {
                                    await reportComment()
                                }
                            } label: {
                                Label("Report", systemImage: "flag")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.textTertiary)
                                .font(.system(size: 12))
                        }
                        
                        // Upvote button
                        Button {
                            Task {
                                await upvoteComment()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowtriangle.up.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(LinearGradient.accent)
                                Text("\(comment.upvoteCount)")
                                    .foregroundColor(.textSecondary)
                                    .font(.captionSmall)
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(isUpvoting)
                    }
                    
                    Text(comment.body)
                        .foregroundColor(.textPrimary.opacity(0.9))
                        .font(.caption)
                    
                    Button {
                        onReply(comment)
                    } label: {
                        Text("Reply")
                            .foregroundColor(.textTertiary)
                            .font(.captionSmall)
                    }
                }
            }
            
            // Nested replies
            if !replies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(replies) { reply in
                        CommentView(
                            comment: reply,
                            allComments: allComments,
                            onReply: onReply,
                            onDelete: onDelete,
                            onProfileTap: onProfileTap
                        )
                        .padding(.leading, 44)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func upvoteComment() async {
        guard !isUpvoting else { return }
        isUpvoting = true
        
        comment.upvoteCount += 1
        
        do {
            try await supabase
                .rpc("increment_comment_upvote", params: ["comment_uuid": comment.id.uuidString])
                .execute()
            
            print("âœ… Upvoted comment")
            isUpvoting = false
        } catch {
            comment.upvoteCount -= 1
            print("âŒ Failed to upvote comment: \(error)")
            isUpvoting = false
        }
    }
    
    private func reportComment() async {
        guard let userId = userData.supabaseUserId else { return }
        
        do {
            struct ReportInsert: Encodable {
                let comment_id: String
                let user_id: String
            }
            
            try await supabase
                .from("comment_reports")
                .insert(ReportInsert(
                    comment_id: comment.id.uuidString,
                    user_id: userId.uuidString
                ))
                .execute()
            
            print("âœ… Reported comment")
        } catch {
            print("âŒ Failed to report comment: \(error)")
        }
    }
}

// MARK: - UUID Identifiable Extension

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

// MARK: - Preview

#Preview {
    PostDetailView(post: Post(
        id: UUID(),
        userId: UUID(),
        title: "Test Post",
        body: "This is a test post body with some content to show how it looks.",
        upvoteCount: 10,
        reportCount: 0,
        createdAt: Date(),
        userName: "TestUser",
        profilePictureURL: nil,
        isProfilePublic: true
    ))
}
