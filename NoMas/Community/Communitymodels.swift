//
//  CommunityModels.swift
//  NoMas
//
//  Community feature data models
//

import Foundation

// MARK: - Post Model

struct Post: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let body: String
    var upvoteCount: Int
    var reportCount: Int
    let createdAt: Date
    
    // Profile data (joined from users table)
    var userName: String?
    var profilePictureURL: String?
    var isProfilePublic: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case body
        case upvoteCount = "upvote_count"
        case reportCount = "report_count"
        case createdAt = "created_at"
        case userName = "display_name"
        case profilePictureURL = "profile_picture_url"
        case isProfilePublic = "is_profile_public"
    }
    
    var timeAgo: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .month], from: createdAt, to: now)
        
        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
    
    var displayName: String {
        if isProfilePublic == true, let name = userName, !name.isEmpty {
            return name
        }
        return "Anonymous"
    }
    
    var isAnonymous: Bool {
        return isProfilePublic != true
    }
}

// MARK: - Comment Model

struct Comment: Identifiable, Codable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let body: String
    var upvoteCount: Int
    var reportCount: Int
    let parentCommentId: UUID?
    let createdAt: Date
    
    // Profile data (joined from users table)
    var userName: String?
    var profilePictureURL: String?
    var isProfilePublic: Bool?
    
    // For nested comments
    var replies: [Comment] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case body
        case upvoteCount = "upvote_count"
        case reportCount = "report_count"
        case parentCommentId = "parent_comment_id"
        case createdAt = "created_at"
        case userName = "display_name"
        case profilePictureURL = "profile_picture_url"
        case isProfilePublic = "is_profile_public"
    }
    
    var timeAgo: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .month], from: createdAt, to: now)
        
        if let month = components.month, month > 0 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        } else if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
    
    var displayName: String {
        if isProfilePublic == true, let name = userName, !name.isEmpty {
            return name
        }
        return "Anonymous"
    }
    
    var isAnonymous: Bool {
        return isProfilePublic != true
    }
}

// MARK: - Database Response Models

struct PostResponse: Codable {
    let id: UUID
    let user_id: UUID
    let title: String
    let body: String
    let upvote_count: Int
    let report_count: Int
    let created_at: String
    let users: UserProfileData?
    
    struct UserProfileData: Codable {
        let display_name: String?
        let profile_picture_url: String?
        let is_profile_public: Bool?
    }
    
    func toPost() -> Post? {
        // Try ISO8601 format first, then fallback to other formats
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date: Date?
        if let parsedDate = formatter.date(from: created_at) {
            date = parsedDate
        } else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: created_at)
        }
        
        guard let validDate = date else {
            print("❌ Failed to parse date: \(created_at)")
            return nil
        }
        
        return Post(
            id: id,
            userId: user_id,
            title: title,
            body: body,
            upvoteCount: upvote_count,
            reportCount: report_count,
            createdAt: validDate,
            userName: users?.display_name,
            profilePictureURL: users?.profile_picture_url,
            isProfilePublic: users?.is_profile_public
        )
    }
}

struct CommentResponse: Codable {
    let id: UUID
    let post_id: UUID
    let user_id: UUID
    let body: String
    let upvote_count: Int
    let report_count: Int
    let parent_comment_id: UUID?
    let created_at: String
    let users: UserProfileData?
    
    struct UserProfileData: Codable {
        let display_name: String?
        let profile_picture_url: String?
        let is_profile_public: Bool?
    }
    
    func toComment() -> Comment? {
        // Try ISO8601 format first, then fallback to other formats
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date: Date?
        if let parsedDate = formatter.date(from: created_at) {
            date = parsedDate
        } else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: created_at)
        }
        
        guard let validDate = date else {
            print("❌ Failed to parse comment date: \(created_at)")
            return nil
        }
        
        return Comment(
            id: id,
            postId: post_id,
            userId: user_id,
            body: body,
            upvoteCount: upvote_count,
            reportCount: report_count,
            parentCommentId: parent_comment_id,
            createdAt: validDate,
            userName: users?.display_name,
            profilePictureURL: users?.profile_picture_url,
            isProfilePublic: users?.is_profile_public
        )
    }
}

// MARK: - User Profile Model (for UserProfileView)

struct CommunityUserProfile {
    let id: UUID
    let userName: String
    let bio: String?
    let instagramHandle: String?
    let profilePictureURL: String?
}
