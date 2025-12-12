//
//  UserData.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


import Foundation
import SwiftUI
import Combine
import Security

// MARK: - UserData (Central State Manager)

@MainActor
class UserData: ObservableObject {
    static let shared = UserData()
    
    // MARK: - Dependencies
    
    private let deviceManager = DeviceManager.shared
    private let database = DatabaseService.shared
    
    // MARK: - Supabase Record ID
    
    /// The user's UUID in Supabase (set after getOrCreateUser)
    @Published private(set) var supabaseUserId: UUID?
    
    // MARK: - Onboarding Status
    
    @Published var hasCompletedOnboarding: Bool = false {
        didSet { saveProgressToSupabase() }
    }
    
    /// Tracks if user skipped the optional early auth (so we can force it after paywall)
    @Published var skippedEarlyAuth: Bool = false {
        didSet { saveToUserDefaults() }
    }
    
    /// Tracks if user has an active subscription (verified with StoreKit)
    @Published var hasActiveSubscription: Bool = false {
        didSet {
            subscriptionStatus = hasActiveSubscription
            saveProgressToSupabase()
        }
    }
    
    // MARK: - User Profile
    
    @Published var displayName: String = "" {
        didSet { saveUserToSupabase() }
    }
    
    @Published var age: Int? = nil {
        didSet { saveUserToSupabase() }
    }
    
    @Published var gender: Gender? = nil {
        didSet { saveUserToSupabase() }
    }
    
    @Published var bio: String? = nil {
        didSet { saveUserToSupabase() }
    }
    
    @Published var instagramHandle: String? = nil {
        didSet { saveUserToSupabase() }
    }
    
    @Published var profilePictureURL: String? = nil {
        didSet { saveUserToSupabase() }
    }
    
    @Published var isProfilePublic: Bool = true {
        didSet { saveUserToSupabase() }
    }
    
    // MARK: - Quiz Answers
    
    @Published var lastRelapseDate: Date = Date() {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var viewingFrequency: ViewingFrequency? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var escalationToExtreme: Bool? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var ageFirstExposure: AgeFirstExposure? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var arousalDifficulty: FrequencyResponse? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var copingEmotional: FrequencyResponse? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var stressResponse: FrequencyResponse? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var boredomResponse: FrequencyResponse? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    @Published var spentMoney: Bool? = nil {
        didSet { saveQuizToSupabase() }
    }
    
    // MARK: - Calculated / Progress Data
    
    @Published var dependencyScore: Double = 0.0
    
    @Published var appJoinDate: Date = Date()
    
    @Published var streakStartDate: Date = Date() {
        didSet { saveProgressToSupabase() }
    }
    
    @Published var currentMilestone: Milestone = .red {
        didSet { saveProgressToSupabase() }
    }
    
    @Published var projectedRecoveryDate: Date? = nil
    
    @Published var subscriptionStatus: Bool = false
    
    // MARK: - Loading State
    
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var loadError: String? = nil
    
    // MARK: - Debouncing
    
    private var saveUserTask: Task<Void, Never>?
    private var saveQuizTask: Task<Void, Never>?
    private var saveProgressTask: Task<Void, Never>?
    
    // MARK: - Init
    
    private init() {
        // Load from UserDefaults for immediate UI (before Supabase fetch)
        loadFromUserDefaults()
    }
    
    // MARK: - Computed Properties
    
    var deviceId: String {
        deviceManager.deviceId
    }
    
    /// Days since last relapse (streak count)
    var daysSinceRelapse: Int {
        Calendar.current.dateComponents([.day], from: streakStartDate, to: Date()).day ?? 0
    }
    
    /// Days since joining the app
    var daysInApp: Int {
        Calendar.current.dateComponents([.day], from: appJoinDate, to: Date()).day ?? 0
    }
    
    // MARK: - Score Calculation
    
    func calculateDependencyScore() -> Double {
        var score = QuizScoringConfig.baseScore // 55.0
        
        // Viewing frequency (2-8 points)
        if let frequency = viewingFrequency {
            score += frequency.scoreWeight
        }
        
        // Escalation to extreme content (0 or 5 points)
        if let escalation = escalationToExtreme, escalation {
            score += QuizScoringConfig.escalationYesWeight
        }
        
        // Age of first exposure (0-6 points)
        if let ageExposure = ageFirstExposure {
            score += ageExposure.scoreWeight
        }
        
        // Arousal difficulty (0-5 points)
        if let arousal = arousalDifficulty {
            score += arousal.scoreWeight(for: .arousalDifficulty)
        }
        
        // Coping with emotional pain (0-4 points)
        if let coping = copingEmotional {
            score += coping.scoreWeight(for: .copingEmotional)
        }
        
        // Stress response (0-4 points)
        if let stress = stressResponse {
            score += stress.scoreWeight(for: .stressResponse)
        }
        
        // Boredom response (0-3 points)
        if let boredom = boredomResponse {
            score += boredom.scoreWeight(for: .boredomResponse)
        }
        
        // Spent money (0 or 4 points)
        if let money = spentMoney, money {
            score += QuizScoringConfig.spentMoneyYesWeight
        }
        
        return min(score, QuizScoringConfig.maxScore) // Cap at 94
    }
    
    /// Call this when quiz is complete to finalize score and dates
    func finalizeQuizResults() {
        dependencyScore = calculateDependencyScore()
        appJoinDate = Date()
        streakStartDate = lastRelapseDate
        currentMilestone = Milestone.forDays(daysSinceRelapse)
        calculateProjectedRecoveryDate()
        
        // Save everything
        saveQuizToSupabase()
        saveProgressToSupabase()
    }
    
    func calculateProjectedRecoveryDate() {
        // Estimate 90 days for recovery (can adjust based on score)
        let baseDays = 90
        let adjustedDays = Int(Double(baseDays) * (dependencyScore / 70.0))
        projectedRecoveryDate = Calendar.current.date(byAdding: .day, value: adjustedDays, to: appJoinDate)
    }
    
    /// Update milestone based on current streak
    func updateMilestone() {
        let days = daysSinceRelapse
        let newMilestone = Milestone.forDays(days)
        if newMilestone != currentMilestone {
            currentMilestone = newMilestone
        }
    }
    
    // MARK: - Supabase Operations
    
    /// Initialize user in Supabase (call on app launch)
    func initializeFromSupabase() async {
        isLoading = true
        loadError = nil
        
        do {
            // Get or create user record
            let user = try await database.getOrCreateUser(deviceId: deviceId)
            self.supabaseUserId = user.id
            
            // Fetch all related data
            if let allData = try await database.fetchAllUserData(deviceId: deviceId) {
                populateFromSupabase(user: allData.user, quiz: allData.quiz, progress: allData.progress)
            }
            
            print("âœ… UserData initialized from Supabase")
        } catch {
            print("âŒ Failed to initialize from Supabase: \(error)")
            loadError = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Populate local properties from Supabase data
    private func populateFromSupabase(user: SupabaseUser, quiz: SupabaseQuizData?, progress: SupabaseUserProgress?) {
        // User data
        displayName = user.displayName ?? ""
        age = user.age
        gender = user.gender.flatMap { Gender(rawValue: $0) }
        bio = user.bio
        instagramHandle = user.instagramHandle
        profilePictureURL = user.profilePictureUrl
        isProfilePublic = user.isProfilePublic ?? true
        
        // Quiz data
        if let quiz = quiz {
            lastRelapseDate = quiz.lastRelapseDate ?? Date()
            viewingFrequency = quiz.viewingFrequency.flatMap { ViewingFrequency(rawValue: $0) }
            escalationToExtreme = quiz.escalationToExtreme
            ageFirstExposure = quiz.ageFirstExposure.flatMap { AgeFirstExposure(rawValue: $0) }
            arousalDifficulty = quiz.arousalDifficulty.flatMap { FrequencyResponse(rawValue: $0) }
            copingEmotional = quiz.copingEmotional.flatMap { FrequencyResponse(rawValue: $0) }
            stressResponse = quiz.stressResponse.flatMap { FrequencyResponse(rawValue: $0) }
            boredomResponse = quiz.boredomResponse.flatMap { FrequencyResponse(rawValue: $0) }
            spentMoney = quiz.spentMoney
            dependencyScore = quiz.dependencyScore ?? 0.0
        }
        
        // Progress data
        if let progress = progress {
            hasCompletedOnboarding = progress.hasCompletedOnboarding ?? false
            appJoinDate = progress.appJoinDate ?? Date()
            streakStartDate = progress.streakStartDate ?? Date()
            currentMilestone = progress.currentMilestone.flatMap { Milestone(rawValue: $0) } ?? .red
            projectedRecoveryDate = progress.projectedRecoveryDate
            subscriptionStatus = progress.subscriptionStatus ?? false
        }
        
        // Save to UserDefaults for offline access
        saveToUserDefaults()
    }
    
    // MARK: - Debounced Save Operations
    
    private func saveUserToSupabase() {
        saveUserTask?.cancel()
        saveUserTask = Task {
            try? await Task.sleep(for: .milliseconds(500)) // Debounce
            guard !Task.isCancelled, let userId = supabaseUserId else { return }
            
            do {
                try await database.updateUser(
                    userId: userId,
                    displayName: displayName.isEmpty ? nil : displayName,
                    age: age,
                    gender: gender,
                    bio: bio,
                    instagramHandle: instagramHandle,
                    profilePictureUrl: profilePictureURL,
                    isProfilePublic: isProfilePublic
                )
                print("✅ User data saved to Supabase")
            } catch {
                print("❌ Failed to save user: \(error)")
            }
        }
        
        saveToUserDefaults()
    }
    
    private func saveQuizToSupabase() {
        saveQuizTask?.cancel()
        saveQuizTask = Task {
            try? await Task.sleep(for: .milliseconds(500)) // Debounce
            guard !Task.isCancelled, let userId = supabaseUserId else { return }
            
            let input = QuizDataInput(
                lastRelapseDate: lastRelapseDate,
                viewingFrequency: viewingFrequency,
                escalationToExtreme: escalationToExtreme,
                ageFirstExposure: ageFirstExposure,
                arousalDifficulty: arousalDifficulty,
                copingEmotional: copingEmotional,
                stressResponse: stressResponse,
                boredomResponse: boredomResponse,
                spentMoney: spentMoney,
                dependencyScore: dependencyScore
            )
            
            do {
                try await database.saveQuizData(userId: userId, quizData: input)
                print("âœ… Quiz data saved to Supabase")
            } catch {
                print("âŒ Failed to save quiz: \(error)")
            }
        }
        
        saveToUserDefaults()
    }
    
    private func saveProgressToSupabase() {
        saveProgressTask?.cancel()
        saveProgressTask = Task {
            try? await Task.sleep(for: .milliseconds(500)) // Debounce
            guard !Task.isCancelled, let userId = supabaseUserId else { return }
            
            let input = ProgressInput(
                hasCompletedOnboarding: hasCompletedOnboarding,
                appJoinDate: appJoinDate,
                streakStartDate: streakStartDate,
                currentMilestone: currentMilestone,
                projectedRecoveryDate: projectedRecoveryDate,
                subscriptionStatus: subscriptionStatus
            )
            
            do {
                try await database.updateProgress(userId: userId, progress: input)
                print("âœ… Progress saved to Supabase")
            } catch {
                print("âŒ Failed to save progress: \(error)")
            }
        }
        
        saveToUserDefaults()
    }
    
    // MARK: - UserDefaults (Offline Cache)
    
    private let defaults = UserDefaults.standard
    
    private func saveToUserDefaults() {
        defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        defaults.set(skippedEarlyAuth, forKey: "skippedEarlyAuth")
        defaults.set(hasActiveSubscription, forKey: "hasActiveSubscription")
        defaults.set(displayName, forKey: "displayName")
        defaults.set(age, forKey: "age")
        defaults.set(gender?.rawValue, forKey: "gender")
        defaults.set(bio, forKey: "bio")
        defaults.set(instagramHandle, forKey: "instagramHandle")
        defaults.set(profilePictureURL, forKey: "profilePictureURL")
        defaults.set(isProfilePublic, forKey: "isProfilePublic")
        defaults.set(lastRelapseDate, forKey: "lastRelapseDate")
        defaults.set(viewingFrequency?.rawValue, forKey: "viewingFrequency")
        defaults.set(escalationToExtreme, forKey: "escalationToExtreme")
        defaults.set(ageFirstExposure?.rawValue, forKey: "ageFirstExposure")
        defaults.set(arousalDifficulty?.rawValue, forKey: "arousalDifficulty")
        defaults.set(copingEmotional?.rawValue, forKey: "copingEmotional")
        defaults.set(stressResponse?.rawValue, forKey: "stressResponse")
        defaults.set(boredomResponse?.rawValue, forKey: "boredomResponse")
        defaults.set(spentMoney, forKey: "spentMoney")
        defaults.set(dependencyScore, forKey: "dependencyScore")
        defaults.set(appJoinDate, forKey: "appJoinDate")
        defaults.set(streakStartDate, forKey: "streakStartDate")
        defaults.set(currentMilestone.rawValue, forKey: "currentMilestone")
        defaults.set(subscriptionStatus, forKey: "subscriptionStatus")
    }
    
    private func loadFromUserDefaults() {
        hasCompletedOnboarding = defaults.bool(forKey: "hasCompletedOnboarding")
        skippedEarlyAuth = defaults.bool(forKey: "skippedEarlyAuth")
        hasActiveSubscription = defaults.bool(forKey: "hasActiveSubscription")
        displayName = defaults.string(forKey: "displayName") ?? ""
        age = defaults.object(forKey: "age") as? Int
        gender = defaults.string(forKey: "gender").flatMap { Gender(rawValue: $0) }
        bio = defaults.string(forKey: "bio")
        instagramHandle = defaults.string(forKey: "instagramHandle")
        profilePictureURL = defaults.string(forKey: "profilePictureURL")
        isProfilePublic = defaults.object(forKey: "isProfilePublic") as? Bool ?? true
        lastRelapseDate = defaults.object(forKey: "lastRelapseDate") as? Date ?? Date()
        viewingFrequency = defaults.string(forKey: "viewingFrequency").flatMap { ViewingFrequency(rawValue: $0) }
        escalationToExtreme = defaults.object(forKey: "escalationToExtreme") as? Bool
        ageFirstExposure = defaults.string(forKey: "ageFirstExposure").flatMap { AgeFirstExposure(rawValue: $0) }
        arousalDifficulty = defaults.string(forKey: "arousalDifficulty").flatMap { FrequencyResponse(rawValue: $0) }
        copingEmotional = defaults.string(forKey: "copingEmotional").flatMap { FrequencyResponse(rawValue: $0) }
        stressResponse = defaults.string(forKey: "stressResponse").flatMap { FrequencyResponse(rawValue: $0) }
        boredomResponse = defaults.string(forKey: "boredomResponse").flatMap { FrequencyResponse(rawValue: $0) }
        spentMoney = defaults.object(forKey: "spentMoney") as? Bool
        dependencyScore = defaults.double(forKey: "dependencyScore")
        appJoinDate = defaults.object(forKey: "appJoinDate") as? Date ?? Date()
        streakStartDate = defaults.object(forKey: "streakStartDate") as? Date ?? Date()
        currentMilestone = defaults.string(forKey: "currentMilestone").flatMap { Milestone(rawValue: $0) } ?? .red
        subscriptionStatus = defaults.bool(forKey: "subscriptionStatus")
    }
    
    // MARK: - Reset (for testing)
    
    #if DEBUG
    /// Resets all local data (UserDefaults only) - DEBUG ONLY
    func resetAllData() {
        hasCompletedOnboarding = false
        skippedEarlyAuth = false
        hasActiveSubscription = false
        displayName = ""
        age = nil
        gender = nil
        bio = nil
        instagramHandle = nil
        profilePictureURL = nil
        isProfilePublic = true
        lastRelapseDate = Date()
        viewingFrequency = nil
        escalationToExtreme = nil
        ageFirstExposure = nil
        arousalDifficulty = nil
        copingEmotional = nil
        stressResponse = nil
        boredomResponse = nil
        spentMoney = nil
        dependencyScore = 0.0
        appJoinDate = Date()
        streakStartDate = Date()
        currentMilestone = .red
        projectedRecoveryDate = nil
        subscriptionStatus = false
        supabaseUserId = nil
        
        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        
        print("🗑️ UserDefaults cleared")
    }
    #endif
    
    // MARK: - Full App Reset (Developer Tool)
    
    /// Wipes ALL app data - simulates fresh install
    /// Clears: UserDefaults, Keychain, Supabase session
    /// Available in all builds (hidden behind 7-tap activation in Settings)
    func nukeEverything() async {
        print("☢️ NUKING EVERYTHING...")
        
        // 1. Sign out of Supabase (this clears Supabase's keychain tokens)
        await AuthManager.shared.signOut()
        print("✅ Signed out of Supabase")
        
        // 2. Delete ALL keychain items for this app
        clearAllKeychainItems()
        print("✅ Keychain wiped")
        
        // 3. Clear all UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleId)
            defaults.synchronize()
        }
        print("✅ UserDefaults wiped")
        
        // 4. Reset in-memory state
        hasCompletedOnboarding = false
        skippedEarlyAuth = false
        hasActiveSubscription = false
        displayName = ""
        age = nil
        gender = nil
        bio = nil
        instagramHandle = nil
        profilePictureURL = nil
        isProfilePublic = true
        lastRelapseDate = Date()
        viewingFrequency = nil
        escalationToExtreme = nil
        ageFirstExposure = nil
        arousalDifficulty = nil
        copingEmotional = nil
        stressResponse = nil
        boredomResponse = nil
        spentMoney = nil
        dependencyScore = 0.0
        appJoinDate = Date()
        streakStartDate = Date()
        currentMilestone = .red
        projectedRecoveryDate = nil
        subscriptionStatus = false
        supabaseUserId = nil
        
        print("☢️ NUKE COMPLETE - Restart the app!")
    }
    
    /// Deletes all keychain items for this app
    private func clearAllKeychainItems() {
        let secClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity
        ]
        
        for secClass in secClasses {
            let query: [String: Any] = [kSecClass as String: secClass]
            let status = SecItemDelete(query as CFDictionary)
            if status == errSecSuccess {
                print("   Deleted keychain items of class: \(secClass)")
            } else if status == errSecItemNotFound {
                // No items of this class - that's fine
            } else {
                print("   ⚠️ Failed to delete keychain class \(secClass): \(status)")
            }
        }
    }
}
