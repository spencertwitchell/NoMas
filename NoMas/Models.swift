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
    case bronze
    case silver
    case gold
    case platinum
    case diamond
    case ruby
    case elite
    case master
    case grandmaster
    
    var id: String { rawValue }
    
    /// Days required to reach this milestone
    var daysRequired: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 3
        case .gold: return 7
        case .platinum: return 10
        case .diamond: return 15
        case .ruby: return 30
        case .elite: return 45
        case .master: return 60
        case .grandmaster: return 90
        }
    }
    
    /// Display name for the milestone
    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        case .ruby: return "Ruby"
        case .elite: return "Elite"
        case .master: return "Master"
        case .grandmaster: return "Grandmaster"
        }
    }
    
    /// Motivational title for the milestone
    var title: String {
        switch self {
        case .bronze: return "The Journey Begins"
        case .silver: return "Building Foundation"
        case .gold: return "First Week Victory"
        case .platinum: return "Growing Stronger"
        case .diamond: return "Breaking Through"
        case .ruby: return "One Month Milestone"
        case .elite: return "Elite Status"
        case .master: return "Master Level"
        case .grandmaster: return "Grandmaster Achievement"
        }
    }
    
    /// Description of what this milestone represents
    var description: String {
        switch self {
        case .bronze:
            return "Every journey begins with a single step. You've made the commitment to change — that takes real courage."
        case .silver:
            return "Three days of dedication. Your brain is already beginning to recognize new patterns. Keep pushing forward."
        case .gold:
            return "One full week accomplished. You're proving that you have the strength to take control of your life."
        case .platinum:
            return "Ten days of progress. The initial challenges are behind you, and you're building real momentum now."
        case .diamond:
            return "Two weeks of commitment. Your resolve is hardening like a diamond — unbreakable and brilliant."
        case .ruby:
            return "A full month of recovery. This is a major achievement that shows your dedication to lasting change."
        case .elite:
            return "45 days of transformation. You've entered elite territory — few make it this far. Be proud."
        case .master:
            return "Two months of mastery. You've developed new habits and your brain is rewiring itself for success."
        case .grandmaster:
            return "90 days of freedom. You've achieved grandmaster status — a complete recovery cycle. You are transformed."
        }
    }
    
    /// Color for this milestone (placeholder - will be replaced with Lottie animations)
    var color: Color {
        return .red
    }
    
    /// SF Symbol name for this milestone
    var iconName: String {
        return "flame.fill"
    }
    
    /// Get milestone for a given day count
    static func forDays(_ days: Int) -> Milestone {
        let sorted = Milestone.allCases.sorted { $0.daysRequired > $1.daysRequired }
        return sorted.first { days >= $0.daysRequired } ?? .bronze
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
    
    // Recovery calculation
    static let baseRecoveryDays: Double = 90.0
    static let averageScore: Double = 70.0
    
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
    let totalRecoveryDays: Int?
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
        case totalRecoveryDays = "total_recovery_days"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiry = "subscription_expiry"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
