//
//  OnboardingState.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Onboarding Phase Enum

/// Represents each phase of the onboarding flow.
///
/// Flow: welcome → optionalAuth → quiz → ... → paywall → complete
///
/// Note:
/// - Splash is NOT included here (runs on every app launch)
/// - Auth after paywall is handled WITHIN the paywall phase (conditional based on skippedEarlyAuth)
/// - The paywall phase doesn't advance until BOTH payment and auth (if needed) are complete
enum OnboardingPhase: Int, CaseIterable, Codable {
    case welcome = 0
    case optionalAuth      // NEW: Optional sign-in with skip button
    case quiz
    case quizCalculating
    case quizResults
    case symptoms
    case negativeEffects
    case transition
    case science
    case benefits
    case testimonials
    case reviews
    case commitment
    case motivation
    case paywall           // Handles: paywall display + forced auth if skipped earlier
    case complete
    
    // MARK: - Navigation
    
    var next: OnboardingPhase? {
        OnboardingPhase(rawValue: rawValue + 1)
    }
    
    var previous: OnboardingPhase? {
        guard rawValue > 0 else { return nil }
        return OnboardingPhase(rawValue: rawValue - 1)
    }
    
    // MARK: - Phase Properties
    
    /// Phases that allow going back
    var canGoBack: Bool {
        switch self {
        case .welcome, .optionalAuth, .quizCalculating, .quizResults, .paywall, .complete:
            return false
        default:
            return true
        }
    }
    
    /// Phases that show in progress indicator
    var isVisibleStep: Bool {
        switch self {
        case .optionalAuth, .quizCalculating, .paywall, .complete:
            return false
        default:
            return true
        }
    }
    
    /// Total visible steps for progress calculation
    static var totalVisibleSteps: Int {
        allCases.filter { $0.isVisibleStep }.count
    }
    
    /// Current step number (1-based) for progress
    var stepNumber: Int? {
        guard isVisibleStep else { return nil }
        let visiblePhases = OnboardingPhase.allCases.filter { $0.isVisibleStep }
        return visiblePhases.firstIndex(of: self).map { $0 + 1 }
    }
    
    /// Progress percentage (0.0 - 1.0)
    var progress: Double {
        guard let step = stepNumber else { return 0 }
        return Double(step) / Double(OnboardingPhase.totalVisibleSteps)
    }
    
    /// Display name for debugging
    var displayName: String {
        switch self {
        case .welcome: return "Welcome"
        case .optionalAuth: return "Optional Auth"
        case .quiz: return "Quiz"
        case .quizCalculating: return "Calculating"
        case .quizResults: return "Results"
        case .symptoms: return "Symptoms"
        case .negativeEffects: return "Negative Effects"
        case .transition: return "Transition"
        case .science: return "Science"
        case .benefits: return "Benefits"
        case .testimonials: return "Testimonials"
        case .reviews: return "Reviews"
        case .commitment: return "Commitment"
        case .motivation: return "Motivation"
        case .paywall: return "Paywall"
        case .complete: return "Complete"
        }
    }
}

// MARK: - Onboarding State Manager

@MainActor
class OnboardingState: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = OnboardingState()
    
    // MARK: - Published State
    
    @Published private(set) var currentPhase: OnboardingPhase = .welcome {
        didSet {
            persistPhase()
            print("ðŸ“ Onboarding phase: \(oldValue.displayName) â†’ \(currentPhase.displayName)")
        }
    }
    
    @Published private(set) var isTransitioning: Bool = false
    @Published var navigationDirection: NavigationDirection = .forward
    
    enum NavigationDirection {
        case forward
        case back
    }
    
    // MARK: - Dependencies
    
    private var userData: UserData { UserData.shared }
    
    // MARK: - Init
    
    private init() {
        // Restore saved phase if user quit mid-onboarding
        restorePhase()
    }
    
    // MARK: - Navigation Methods
    
    /// Advance to the next phase
    func advance() {
        guard !isTransitioning else { return }
        guard let next = currentPhase.next else {
            print("âš ï¸ No next phase after \(currentPhase.displayName)")
            return
        }
        
        navigationDirection = .forward
        transitionTo(next)
    }
    
    /// Go back to the previous phase
    func goBack() {
        guard !isTransitioning else { return }
        guard currentPhase.canGoBack else {
            print("âš ï¸ Cannot go back from \(currentPhase.displayName)")
            return
        }
        guard let prev = currentPhase.previous else { return }
        
        navigationDirection = .back
        transitionTo(prev)
    }
    
    /// Jump directly to a specific phase
    func jumpTo(_ phase: OnboardingPhase) {
        guard !isTransitioning else { return }
        
        navigationDirection = phase.rawValue > currentPhase.rawValue ? .forward : .back
        transitionTo(phase)
    }
    
    /// Internal transition with animation lock
    private func transitionTo(_ phase: OnboardingPhase) {
        isTransitioning = true
        
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPhase = phase
        }
        
        // Release lock after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.isTransitioning = false
        }
    }
    
    // MARK: - Completion
    
    /// Mark onboarding as complete and transition to main app
    func completeOnboarding() {
        userData.hasCompletedOnboarding = true
        currentPhase = .complete
        clearPersistedPhase()
        print("âœ… Onboarding completed!")
    }
    
    /// Reset onboarding (for testing or re-onboarding)
    func resetOnboarding() {
        userData.hasCompletedOnboarding = false
        userData.skippedEarlyAuth = false
        userData.hasActiveSubscription = false
        currentPhase = .welcome
        clearPersistedPhase()
        print("ðŸ”„ Onboarding reset")
    }
    
    // MARK: - Persistence
    
    private let phaseKey = "onboarding_phase"
    
    private func persistPhase() {
        // Don't persist terminal states
        guard currentPhase != .complete else { return }
        UserDefaults.standard.set(currentPhase.rawValue, forKey: phaseKey)
    }
    
    private func restorePhase() {
        // If already completed onboarding, skip to complete
        if userData.hasCompletedOnboarding {
            currentPhase = .complete
            return
        }
        
        // Restore saved phase
        if let savedRaw = UserDefaults.standard.object(forKey: phaseKey) as? Int,
           let savedPhase = OnboardingPhase(rawValue: savedRaw) {
            currentPhase = savedPhase
            print("ðŸ“ Restored onboarding phase: \(savedPhase.displayName)")
        }
    }
    
    private func clearPersistedPhase() {
        UserDefaults.standard.removeObject(forKey: phaseKey)
    }
    
    // MARK: - Convenience Checks
    
    var isInQuiz: Bool {
        currentPhase == .quiz
    }
    
    var isShowingResults: Bool {
        currentPhase == .quizResults
    }
    
    var isPostQuiz: Bool {
        currentPhase.rawValue > OnboardingPhase.quizResults.rawValue &&
        currentPhase.rawValue < OnboardingPhase.paywall.rawValue
    }
    
    var isComplete: Bool {
        currentPhase == .complete
    }
}

// MARK: - Transition Helpers

extension OnboardingState {
    
    /// Get the appropriate slide transition based on navigation direction
    var slideTransition: AnyTransition {
        switch navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .back:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension OnboardingState {
    /// Create a preview instance at a specific phase
    static func preview(at phase: OnboardingPhase) -> OnboardingState {
        let state = OnboardingState.shared
        state.currentPhase = phase
        return state
    }
}
#endif
