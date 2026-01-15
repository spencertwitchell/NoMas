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

// MARK: - Monthly Spending

enum MonthlySpending: String, Codable, CaseIterable, Identifiable {
    case zero = "0"
    case five = "5"
    case fifteen = "15"
    case thirty = "30"
    case sixty = "60"
    case hundred = "100"
    case twoHundredPlus = "200_plus"
    
    var id: String { rawValue }
    
    /// Display text for the slider
    var displayName: String {
        switch self {
        case .zero: return "$0"
        case .five: return "$5"
        case .fifteen: return "$15"
        case .thirty: return "$30"
        case .sixty: return "$60"
        case .hundred: return "$100"
        case .twoHundredPlus: return "$200+"
        }
    }
    
    /// Index for slider position (0-6)
    var sliderIndex: Int {
        switch self {
        case .zero: return 0
        case .five: return 1
        case .fifteen: return 2
        case .thirty: return 3
        case .sixty: return 4
        case .hundred: return 5
        case .twoHundredPlus: return 6
        }
    }
    
    /// Create from slider index
    static func fromSliderIndex(_ index: Int) -> MonthlySpending {
        switch index {
        case 0: return .zero
        case 1: return .five
        case 2: return .fifteen
        case 3: return .thirty
        case 4: return .sixty
        case 5: return .hundred
        case 6: return .twoHundredPlus
        default: return .zero
        }
    }
    
    /// Score weight for dependency calculation
    /// Higher spending = stronger indicator of compulsive behavior
    var scoreWeight: Double {
        switch self {
        case .zero: return 0
        case .five: return 1
        case .fifteen: return 2
        case .thirty: return 3
        case .sixty: return 4
        case .hundred: return 5
        case .twoHundredPlus: return 6
        }
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
        case .grandmaster: return UserData.shared.totalRecoveryDays
        }
    }
    
    /// Display name for the milestone
    var displayName: String {
        switch self {
        case .bronze: return "Cobre"
        case .silver: return "Plata"
        case .gold: return "Oro"
        case .platinum: return "Platinio"
        case .diamond: return "Diamante"
        case .ruby: return "Ruby"
        case .elite: return "Elite"
        case .master: return "Maestro"
        case .grandmaster: return "Legendario"
        }
    }
    
    /// Motivational title for the milestone
    var title: String {
        switch self {
        case .bronze: return "El Viaje Comienza"
        case .silver: return "Armando la Base"
        case .gold: return "Logro de la Primera Semana"
        case .platinum: return "Fortaleciéndote"
        case .diamond: return "Rompiendo límites"
        case .ruby: return "Un mes de progreso"
        case .elite: return "Estatus Élite"
        case .master: return "Nivel Maestro"
        case .grandmaster: return "Rango Legendario"
        }
        }

        /// Description of what this milestone represents
        var description: String {
            switch self {
            case .bronze:
                return "Todo viaje comienza con un primer paso. Decidir cambiar exige verdadera valentía."
            case .silver:
                return "Tres días de dedicación. Tu cerebro ya comienza a reconocer nuevos patrones. Sigue avanzando."
            case .gold:
                return "Una semana completa lograda. Estás demostrando que tienes la fuerza para tomar control de tu vida."
            case .platinum:
                return "Diez días de progreso. Los desafíos iniciales han quedado atrás y ahora estás creando momentum real."
            case .diamond:
                return "Dos semanas de compromiso. Tu determinación se está volviendo tan firme como un diamante — irrompible y brillante."
            case .ruby:
                return "Un mes completo de recuperación. Un logro real que demuestra tu compromiso con el cambio."
            case .elite:
                return "45 días de transformación. Has entrado en territorio élite — pocos llegan tan lejos. Siéntete orgulloso."
            case .master:
                return "Dos meses de dominio. Has desarrollado nuevos hábitos y tu cerebro se está reconfigurando para el éxito."
            case .grandmaster:
                return "90 días de libertad. Has alcanzado el nivel Legendario — un ciclo completo de recuperación. Estás transformado."
            }
        }

    
    /// Color for this milestone (placeholder - will be replaced with Lottie animations)
    var color: Color {
        return .red
    }
    
    /// Gradient for this milestone (used in milestone cards and header)
    var gradient: LinearGradient {
        switch self {
        case .bronze: return LinearGradient.bronze
        case .silver: return LinearGradient.silver
        case .gold: return LinearGradient.gold
        case .platinum: return LinearGradient.platinum
        case .diamond: return LinearGradient.diamond
        case .ruby: return LinearGradient.ruby
        case .elite: return LinearGradient.elite
        case .master: return LinearGradient.master
        case .grandmaster: return LinearGradient.grandmaster
        }
    }
    
    /// Gradient colors array for this milestone (for custom gradient rendering)
    var gradientColors: [Color] {
        switch self {
        case .bronze: return [Color.bronzeGradientStart, Color.bronzeGradientEnd]
        case .silver: return [Color.silverGradientStart, Color.silverGradientEnd]
        case .gold: return [Color.goldGradientStart, Color.goldGradientEnd]
        case .platinum: return [Color.platinumGradientStart, Color.platinumGradientEnd]
        case .diamond: return [Color.diamondGradientStart, Color.diamondGradientEnd]
        case .ruby: return [Color.rubyGradientStart, Color.rubyGradientEnd]
        case .elite: return [Color.eliteGradientStart, Color.eliteGradientEnd]
        case .master: return [Color.masterGradientStart, Color.masterGradientEnd]
        case .grandmaster: return [Color.grandmasterGradientStart, Color.grandmasterGradientMid, Color.grandmasterGradientEnd]
        }
    }
    
    /// SF Symbol name for this milestone
    var iconName: String {
        return "flame.fill"
    }
    
    /// Lottie animation name for this milestone
    var animationName: String {
        switch self {
        case .bronze: return "bronzeb"
        case .silver: return "silverb"
        case .gold: return "goldb"
        case .platinum: return "platinumb"
        case .diamond: return "diamondb"
        case .ruby: return "rubyb"
        case .elite: return "eliteb"
        case .master: return "masterb"
        case .grandmaster: return "grandmasterb"
        }
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
    // Note: monthlySpending now uses MonthlySpending.scoreWeight (0-6 points)
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
    let monthlySpending: String?
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
        case monthlySpending = "monthly_spending"
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
    let lastCelebratedMilestone: String?
    let hasSeenCameraPrompt: Bool?
    let lastCheckInDate: Date?
    let projectedRecoveryDate: Date?
    let totalRecoveryDays: Int?
    let bestStreak: Int?
    let timesRelapsed: Int?
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
        case lastCelebratedMilestone = "last_celebrated_milestone"
        case hasSeenCameraPrompt = "has_seen_camera_prompt"
        case lastCheckInDate = "last_check_in_date"
        case projectedRecoveryDate = "projected_recovery_date"
        case totalRecoveryDays = "total_recovery_days"
        case bestStreak = "best_streak"
        case timesRelapsed = "times_relapsed"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiry = "subscription_expiry"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
