import Foundation
import Supabase

// MARK: - Supabase Client Singleton

/// Note: The warning about "Initial session emitted after attempting to refresh" is informational.
/// It's about upcoming behavior changes in the next major version of the Supabase Swift SDK.
/// The current implementation works correctly - the warning can be safely ignored until migration.
/// See: https://github.com/supabase/supabase-swift/pull/822

let supabase = SupabaseClient(
    supabaseURL: URL(string: AppConfig.supabaseURL)!,
    supabaseKey: AppConfig.supabaseAnonKey,
    options: SupabaseClientOptions(
        db: .init(encoder: .postgresEncoder, decoder: .postgresDecoder),
        auth: .init(
            redirectToURL: URL(string: AppConfig.authRedirectURL)
        ),
        global: .init(headers: [:])
    )
)

// MARK: - App Configuration

enum AppConfig {
    static let supabaseURL = "https://gxnnjgqmvynyllgyibhx.supabase.co"
    static let supabaseAnonKey = "sb_publishable_yPniFSk_JofE3J9RCA9W6Q_19F603ZA"
    
    // Deep link URL scheme for OAuth callbacks
    static let authRedirectURL = "nomas://auth-callback"
    
    // Superwall API Key
    static let superwallAPIKey = "YOUR_SUPERWALL_KEY"
}

// MARK: - Postgres Encoder/Decoder Configuration

extension JSONEncoder {
    static var postgresEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        // NOTE: Do NOT use .convertToSnakeCase here!
        // The Supabase models have explicit CodingKeys that handle snake_case conversion.
        // Using both causes a conflict.
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var postgresDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        // NOTE: Do NOT use .convertFromSnakeCase here!
        // The Supabase models have explicit CodingKeys that handle snake_case conversion.
        // Using both causes a conflict where Swift looks for the wrong keys.
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds first
            if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: dateString) {
                return date
            }
            
            // Try standard ISO8601
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            // Try date-only format (for DATE columns)
            let dateOnlyFormatter = DateFormatter()
            dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
            dateOnlyFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = dateOnlyFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }
        return decoder
    }
}

extension ISO8601DateFormatter {
    static var withFractionalSeconds: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

// MARK: - Encodable Update Structs

struct UserInsert: Encodable {
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
    }
}

struct UserUpdate: Encodable {
    var displayName: String?
    var age: Int?
    var gender: String?
    var authId: String?
    var bio: String?
    var instagramHandle: String?
    var profilePictureUrl: String?
    var isProfilePublic: Bool?
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case age
        case gender
        case authId = "auth_id"
        case bio
        case instagramHandle = "instagram_handle"
        case profilePictureUrl = "profile_picture_url"
        case isProfilePublic = "is_profile_public"
    }
}

struct QuizDataInsert: Encodable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct QuizDataUpdate: Encodable {
    var lastRelapseDate: String?
    var viewingFrequency: String?
    var escalationToExtreme: Bool?
    var ageFirstExposure: String?
    var arousalDifficulty: String?
    var copingEmotional: String?
    var stressResponse: String?
    var boredomResponse: String?
    var spentMoney: Bool?
    var dependencyScore: Double?
    
    enum CodingKeys: String, CodingKey {
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
    }
}

struct ProgressInsert: Encodable {
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct ProgressUpdate: Encodable {
    var hasCompletedOnboarding: Bool?
    var appJoinDate: String?
    var streakStartDate: String?
    var currentMilestone: String?
    var projectedRecoveryDate: String?
    var totalRecoveryDays: Int?
    var bestStreak: Int?
    var timesRelapsed: Int?
    var subscriptionStatus: Bool?
    
    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding = "has_completed_onboarding"
        case appJoinDate = "app_join_date"
        case streakStartDate = "streak_start_date"
        case currentMilestone = "current_milestone"
        case projectedRecoveryDate = "projected_recovery_date"
        case totalRecoveryDays = "total_recovery_days"
        case bestStreak = "best_streak"
        case timesRelapsed = "times_relapsed"
        case subscriptionStatus = "subscription_status"
    }
}

// MARK: - Database Service

@MainActor
class DatabaseService {
    static let shared = DatabaseService()
    
    /// Date formatter for Supabase TIMESTAMP columns
    /// Uses ISO8601 format with time to preserve hours/minutes/seconds
    /// NOTE: Ensure Supabase columns are TIMESTAMP/TIMESTAMPTZ, not DATE
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
    
    private init() {}
    
    // MARK: - User Operations
    
    /// Create or fetch user by device ID
    func getOrCreateUser(deviceId: String) async throws -> SupabaseUser {
        // First, try to fetch existing user
        let existingUsers: [SupabaseUser] = try await supabase
            .from("users")
            .select()
            .eq("device_id", value: deviceId)
            .execute()
            .value
        
        if let existingUser = existingUsers.first {
            // Ensure related records exist (in case previous creation was interrupted)
            await ensureRelatedRecordsExist(userId: existingUser.id)
            return existingUser
        }
        
        // Create new user
        let newUser: SupabaseUser = try await supabase
            .from("users")
            .insert(UserInsert(deviceId: deviceId))
            .select()
            .single()
            .execute()
            .value
        
        // Create empty quiz data record
        try await supabase
            .from("user_quiz_data")
            .insert(QuizDataInsert(userId: newUser.id.uuidString))
            .execute()
        
        // Create empty progress record
        try await supabase
            .from("user_progress")
            .insert(ProgressInsert(userId: newUser.id.uuidString))
            .execute()
        
        return newUser
    }
    
    /// Ensure quiz_data and progress records exist for a user
    /// (handles case where user was created but related records weren't)
    private func ensureRelatedRecordsExist(userId: UUID) async {
        // Check and create quiz data if missing
        do {
            let existingQuizData: [SupabaseQuizData] = try await supabase
                .from("user_quiz_data")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if existingQuizData.isEmpty {
                try await supabase
                    .from("user_quiz_data")
                    .insert(QuizDataInsert(userId: userId.uuidString))
                    .execute()
                print("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ Created missing quiz_data record")
            }
        } catch {
            print("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â Failed to ensure quiz_data exists: \(error)")
        }
        
        // Check and create progress if missing
        do {
            let existingProgress: [SupabaseUserProgress] = try await supabase
                .from("user_progress")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if existingProgress.isEmpty {
                try await supabase
                    .from("user_progress")
                    .insert(ProgressInsert(userId: userId.uuidString))
                    .execute()
                print("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ Created missing progress record")
            }
        } catch {
            print("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â Failed to ensure progress exists: \(error)")
        }
    }
    
    /// Update user profile
    func updateUser(userId: UUID, displayName: String?, age: Int?, gender: Gender?, bio: String? = nil, instagramHandle: String? = nil, profilePictureUrl: String? = nil, isProfilePublic: Bool? = nil) async throws {
        let update = UserUpdate(
            displayName: displayName,
            age: age,
            gender: gender?.rawValue,
            bio: bio,
            instagramHandle: instagramHandle,
            profilePictureUrl: profilePictureUrl,
            isProfilePublic: isProfilePublic
        )
        
        try await supabase
            .from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    /// Update user profile picture URL only
    func updateProfilePicture(userId: UUID, url: String) async throws {
        let update = UserUpdate(profilePictureUrl: url)
        
        try await supabase
            .from("users")
            .update(update)
            .eq("id", value: userId.uuidString)
            .execute()
    }
    
    /// Link anonymous user to authenticated account
    func linkToAuthAccount(deviceId: String, authId: UUID) async throws {
        let update = UserUpdate(authId: authId.uuidString)
        
        try await supabase
            .from("users")
            .update(update)
            .eq("device_id", value: deviceId)
            .execute()
    }
    
    // MARK: - Quiz Data Operations
    
    /// Save quiz answers
    func saveQuizData(userId: UUID, quizData: QuizDataInput) async throws {
        var update = QuizDataUpdate()
        
        if let lastRelapseDate = quizData.lastRelapseDate {
            update.lastRelapseDate = dateFormatter.string(from: lastRelapseDate)
        }
        if let viewingFrequency = quizData.viewingFrequency {
            update.viewingFrequency = viewingFrequency.rawValue
        }
        if let escalation = quizData.escalationToExtreme {
            update.escalationToExtreme = escalation
        }
        if let ageFirstExposure = quizData.ageFirstExposure {
            update.ageFirstExposure = ageFirstExposure.rawValue
        }
        if let arousalDifficulty = quizData.arousalDifficulty {
            update.arousalDifficulty = arousalDifficulty.rawValue
        }
        if let copingEmotional = quizData.copingEmotional {
            update.copingEmotional = copingEmotional.rawValue
        }
        if let stressResponse = quizData.stressResponse {
            update.stressResponse = stressResponse.rawValue
        }
        if let boredomResponse = quizData.boredomResponse {
            update.boredomResponse = boredomResponse.rawValue
        }
        if let spentMoney = quizData.spentMoney {
            update.spentMoney = spentMoney
        }
        if let dependencyScore = quizData.dependencyScore {
            update.dependencyScore = dependencyScore
        }
        
        try await supabase
            .from("user_quiz_data")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Fetch quiz data for user
    func fetchQuizData(userId: UUID) async throws -> SupabaseQuizData? {
        let results: [SupabaseQuizData] = try await supabase
            .from("user_quiz_data")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return results.first
    }
    
    // MARK: - Progress Operations
    
    /// Update user progress
    func updateProgress(userId: UUID, progress: ProgressInput) async throws {
        var update = ProgressUpdate()
        
        if let hasCompletedOnboarding = progress.hasCompletedOnboarding {
            update.hasCompletedOnboarding = hasCompletedOnboarding
        }
        if let appJoinDate = progress.appJoinDate {
            update.appJoinDate = dateFormatter.string(from: appJoinDate)
        }
        if let streakStartDate = progress.streakStartDate {
            update.streakStartDate = dateFormatter.string(from: streakStartDate)
        }
        if let currentMilestone = progress.currentMilestone {
            update.currentMilestone = currentMilestone.rawValue
        }
        if let projectedRecoveryDate = progress.projectedRecoveryDate {
            update.projectedRecoveryDate = dateFormatter.string(from: projectedRecoveryDate)
        }
        if let totalRecoveryDays = progress.totalRecoveryDays {
            update.totalRecoveryDays = totalRecoveryDays
        }
        if let bestStreak = progress.bestStreak {
            update.bestStreak = bestStreak
        }
        if let timesRelapsed = progress.timesRelapsed {
            update.timesRelapsed = timesRelapsed
        }
        if let subscriptionStatus = progress.subscriptionStatus {
            update.subscriptionStatus = subscriptionStatus
        }
        
        try await supabase
            .from("user_progress")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    /// Fetch user progress
    func fetchProgress(userId: UUID) async throws -> SupabaseUserProgress? {
        let results: [SupabaseUserProgress] = try await supabase
            .from("user_progress")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return results.first
    }
    
    // MARK: - Full Data Fetch
    
    /// Fetch all user data at once
    func fetchAllUserData(deviceId: String) async throws -> (user: SupabaseUser, quiz: SupabaseQuizData?, progress: SupabaseUserProgress?)? {
        let users: [SupabaseUser] = try await supabase
            .from("users")
            .select()
            .eq("device_id", value: deviceId)
            .execute()
            .value
        
        guard let user = users.first else { return nil }
        
        let quiz = try await fetchQuizData(userId: user.id)
        let progress = try await fetchProgress(userId: user.id)
        
        return (user, quiz, progress)
    }
}

// MARK: - Input Structs (for type-safe function parameters)

struct QuizDataInput {
    var lastRelapseDate: Date?
    var viewingFrequency: ViewingFrequency?
    var escalationToExtreme: Bool?
    var ageFirstExposure: AgeFirstExposure?
    var arousalDifficulty: FrequencyResponse?
    var copingEmotional: FrequencyResponse?
    var stressResponse: FrequencyResponse?
    var boredomResponse: FrequencyResponse?
    var spentMoney: Bool?
    var dependencyScore: Double?
}

struct ProgressInput {
    var hasCompletedOnboarding: Bool?
    var appJoinDate: Date?
    var streakStartDate: Date?
    var currentMilestone: Milestone?
    var projectedRecoveryDate: Date?
    var totalRecoveryDays: Int?
    var bestStreak: Int?
    var timesRelapsed: Int?
    var subscriptionStatus: Bool?
}
