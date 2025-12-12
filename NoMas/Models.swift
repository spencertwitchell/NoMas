import Foundation
import SwiftUI

// MARK: - Gender

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

// MARK: - Viewing Frequency

enum ViewingFrequency: String, Codable, CaseIterable, Identifiable {
    case moreThanOnceDaily = "more_than_once_daily"
    case onceDaily = "once_daily"
    case fewTimesWeekly = "few_times_weekly"
    case lessThanWeekly = "less_than_weekly"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .moreThanOnceDaily: return "More than once a day"
        case .onceDaily: return "Once a day"
        case .fewTimesWeekly: return "A few times a week"
        case .lessThanWeekly: return "Less than once a week"
        }
    }
    
    var scoreWeight: Double {
        switch self {
        case .moreThanOnceDaily: return 8
        case .onceDaily: return 6
        case .fewTimesWeekly: return 4
        case .lessThanWeekly: return 2
        }
    }
}

// MARK: - Age First Exposure

enum AgeFirstExposure: String, Codable, CaseIterable, Identifiable {
    case twelveOrYounger = "12_or_younger"
    case thirteenToSixteen = "13_to_16"
    case seventeenToTwentyFour = "17_to_24"
    case twentyFiveOrOlder = "25_or_older"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .twelveOrYounger: return "12 or younger"
        case .thirteenToSixteen: return "13 to 16"
        case .seventeenToTwentyFour: return "17 to 24"
        case .twentyFiveOrOlder: return "25 or older"
        }
    }
    
    var scoreWeight: Double {
        switch self {
        case .twelveOrYounger: return 6
        case .thirteenToSixteen: return 4
        case .seventeenToTwentyFour: return 2
        case .twentyFiveOrOlder: return 0
        }
    }
}

// MARK: - Frequency Response (for behavioral questions)

enum FrequencyResponse: String, Codable, CaseIterable, Identifiable {
    case frequently = "frequently"
    case occasionally = "occasionally"
    case rarelyOrNever = "rarely_or_never"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .frequently: return "Frequently"
        case .occasionally: return "Occasionally"
        case .rarelyOrNever: return "Rarely or Never"
        }
    }
    
    /// Base weight - specific questions may modify this
    func scoreWeight(for question: BehavioralQuestion) -> Double {
        switch self {
        case .frequently:
            return question.frequentlyWeight
        case .occasionally:
            return question.occasionallyWeight
        case .rarelyOrNever:
            return 0
        }
    }
}

// MARK: - Behavioral Question Types

enum BehavioralQuestion {
    case arousalDifficulty
    case copingEmotional
    case stressResponse
    case boredomResponse
    
    var frequentlyWeight: Double {
        switch self {
        case .arousalDifficulty: return 5
        case .copingEmotional: return 4
        case .stressResponse: return 4
        case .boredomResponse: return 3
        }
    }
    
    var occasionallyWeight: Double {
        switch self {
        case .arousalDifficulty: return 3
        case .copingEmotional: return 2
        case .stressResponse: return 2
        case .boredomResponse: return 2
        }
    }
}

// MARK: - Yes/No Response

enum YesNoResponse: String, Codable, CaseIterable, Identifiable {
    case yes = "yes"
    case no = "no"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .yes: return "Yes"
        case .no: return "No"
        }
    }
    
    var boolValue: Bool {
        self == .yes
    }
    
    init(from bool: Bool) {
        self = bool ? .yes : .no
    }
}

// MARK: - Milestones (Streak Progress)

enum Milestone: String, Codable, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple
    case pink
    case white
    
    var id: String { rawValue }
    
    /// Days required to reach this milestone
    var daysRequired: Int {
        switch self {
        case .red: return 0
        case .orange: return 7
        case .yellow: return 14
        case .green: return 30
        case .blue: return 60
        case .purple: return 90
        case .pink: return 180
        case .white: return 365
        }
    }
    
    /// Display name for the milestone
    var displayName: String {
        switch self {
        case .red: return "Day 1"
        case .orange: return "Week 1"
        case .yellow: return "Week 2"
        case .green: return "Month 1"
        case .blue: return "Month 2"
        case .purple: return "Month 3"
        case .pink: return "6 Months"
        case .white: return "1 Year"
        }
    }
    
    /// Motivational title for the milestone
    var title: String {
        switch self {
        case .red: return "The First Step"
        case .orange: return "Building Momentum"
        case .yellow: return "Finding Your Rhythm"
        case .green: return "Gaining Strength"
        case .blue: return "Breaking Free"
        case .purple: return "New Habits Forming"
        case .pink: return "Transformation"
        case .white: return "Freedom"
        }
    }
    
    /// Description of what this milestone represents
    var description: String {
        switch self {
        case .red:
            return "Every journey begins with a single step. You've made the decision to change â€” that takes courage."
        case .orange:
            return "One week of commitment. Your brain is already starting to rewire itself. The hardest part is behind you."
        case .yellow:
            return "Two weeks strong. You're proving to yourself that you have control. Keep building on this foundation."
        case .green:
            return "A full month. This is a major achievement. You're developing new patterns and breaking old ones."
        case .blue:
            return "Two months of freedom. The urges are weakening as new neural pathways strengthen."
        case .purple:
            return "90 days â€” a complete reset cycle. You've fundamentally changed your relationship with temptation."
        case .pink:
            return "Six months of growth. You're not just abstaining â€” you're thriving. This is who you are now."
        case .white:
            return "One year. You've achieved what many thought impossible. Your freedom is complete and self-sustaining."
        }
    }
    
    /// Color for this milestone
    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return Color(red: 1.0, green: 0.4, blue: 0.7)
        case .white: return .white
        }
    }
    
    /// SF Symbol name for this milestone
    var iconName: String {
        return "flame.fill"
    }
    
    /// Get milestone for a given day count
    static func forDays(_ days: Int) -> Milestone {
        let sorted = Milestone.allCases.sorted { $0.daysRequired > $1.daysRequired }
        return sorted.first { days >= $0.daysRequired } ?? .red
    }
    
    /// Next milestone after this one
    var next: Milestone? {
        guard let currentIndex = Milestone.allCases.firstIndex(of: self),
              currentIndex < Milestone.allCases.count - 1 else {
            return nil
        }
        return Milestone.allCases[currentIndex + 1]
    }
}

// MARK: - Quiz Scoring Configuration

struct QuizScoringConfig {
    static let baseScore: Double = 55.0
    static let maxScore: Double = 94.0
    
    // Binary question weights
    static let escalationYesWeight: Double = 5.0
    static let spentMoneyYesWeight: Double = 4.0
}

// MARK: - Supabase Table Models (for decoding)

struct SupabaseUser: Codable {
    let id: UUID
    let authId: UUID?
    let deviceId: String
    let displayName: String?
    let age: Int?
    let gender: String?
    let bio: String?
    let instagramHandle: String?
    let profilePictureUrl: String?
    let isProfilePublic: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case authId = "auth_id"
        case deviceId = "device_id"
        case displayName = "display_name"
        case age
        case gender
        case bio
        case instagramHandle = "instagram_handle"
        case profilePictureUrl = "profile_picture_url"
        case isProfilePublic = "is_profile_public"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseQuizData: Codable {
    let id: UUID
    let userId: UUID
    let lastRelapseDate: Date?
    let viewingFrequency: String?
    let escalationToExtreme: Bool?
    let ageFirstExposure: String?
    let arousalDifficulty: String?
    let copingEmotional: String?
    let stressResponse: String?
    let boredomResponse: String?
    let spentMoney: Bool?
    let dependencyScore: Double?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case lastRelapseDate = "last_relapse_date"
        case viewingFrequency = "viewing_frequency"
        case escalationToExtreme = "escalation_to_extreme"
        case ageFirstExposure = "age_first_exposure"
        case arousalDifficulty = "arousal_difficulty"
        case copingEmotional = "coping_emotional"
        case stressResponse = "stress_response"
        case boredomResponse = "boredom_response"
        case spentMoney = "spent_money"
        case dependencyScore = "dependency_score"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseUserProgress: Codable {
    let id: UUID
    let userId: UUID
    let hasCompletedOnboarding: Bool?
    let appJoinDate: Date?
    let streakStartDate: Date?
    let currentMilestone: String?
    let projectedRecoveryDate: Date?
    let subscriptionStatus: Bool?
    let subscriptionExpiry: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case hasCompletedOnboarding = "has_completed_onboarding"
        case appJoinDate = "app_join_date"
        case streakStartDate = "streak_start_date"
        case currentMilestone = "current_milestone"
        case projectedRecoveryDate = "projected_recovery_date"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiry = "subscription_expiry"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
