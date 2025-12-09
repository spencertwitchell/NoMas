import Foundation
import SwiftUI
import Combine

// MARK: - Quiz Step Enum

enum QuizStep: Int, CaseIterable {
    case gender = 0
    case lastRelapseDate
    case viewingFrequency
    case escalationToExtreme
    case ageFirstExposure
    case arousalDifficulty
    case copingEmotional
    case stressResponse
    case boredomResponse
    case spentMoney
    case personalInfo
    
    // MARK: - Navigation
    
    var next: QuizStep? {
        QuizStep(rawValue: rawValue + 1)
    }
    
    var previous: QuizStep? {
        guard rawValue > 0 else { return nil }
        return QuizStep(rawValue: rawValue - 1)
    }
    
    // MARK: - Step Properties
    
    /// Question number (1-based)
    var questionNumber: Int {
        rawValue + 1
    }
    
    /// Total number of questions
    static var totalQuestions: Int {
        allCases.count
    }
    
    /// Progress percentage (0.0 - 1.0)
    var progress: Double {
        Double(questionNumber) / Double(QuizStep.totalQuestions)
    }
    
    /// Whether this step auto-advances on selection (vs requiring continue button)
    var autoAdvances: Bool {
        switch self {
        case .gender,
             .viewingFrequency,
             .escalationToExtreme,
             .ageFirstExposure,
             .arousalDifficulty,
             .copingEmotional,
             .stressResponse,
             .boredomResponse,
             .spentMoney:
            return true
        case .lastRelapseDate,
             .personalInfo:
            return false
        }
    }
    
    /// Whether this step shows a continue button
    var showsContinueButton: Bool {
        !autoAdvances
    }
    
    /// Question title text
    var questionTitle: String {
        switch self {
        case .gender:
            return "What is your gender?"
        case .lastRelapseDate:
            return "When did you last view pornography?"
        case .viewingFrequency:
            return "How often do you typically view pornography?"
        case .escalationToExtreme:
            return "Have you noticed a shift towards more extreme or graphic material?"
        case .ageFirstExposure:
            return "At what age did you first come across explicit content?"
        case .arousalDifficulty:
            return "Do you find it difficult to achieve sexual arousal without pornography or fantasy?"
        case .copingEmotional:
            return "Do you use pornography as a way to cope with emotional discomfort or pain?"
        case .stressResponse:
            return "Do you turn to pornography when feeling stressed?"
        case .boredomResponse:
            return "Do you watch pornography out of boredom?"
        case .spentMoney:
            return "Have you ever spent money on accessing explicit content?"
        case .personalInfo:
            return "Lastly, a little more about you"
        }
    }
    
    /// Optional subtitle/helper text
    var questionSubtitle: String? {
        switch self {
        case .lastRelapseDate:
            return "This helps us track your progress from the start"
        case .personalInfo:
            return "This helps personalize your experience"
        default:
            return nil
        }
    }
}

// MARK: - Quiz State Manager

@MainActor
class QuizState: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var currentStep: QuizStep = .gender {
        didSet {
            print("❓ Quiz step: \(oldValue.questionNumber) → \(currentStep.questionNumber)")
        }
    }
    
    @Published private(set) var isTransitioning: Bool = false
    @Published var navigationDirection: NavigationDirection = .forward
    
    enum NavigationDirection {
        case forward
        case back
    }
    
    // MARK: - Dependencies (computed to avoid Swift 6 isolation issues)
    
    private var userData: UserData { UserData.shared }
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    // MARK: - Init
    
    init() {}
    
    // MARK: - Navigation
    
    /// Advance to the next question
    func advance() {
        guard !isTransitioning else { return }
        
        if let next = currentStep.next {
            // More questions remaining
            navigationDirection = .forward
            transitionTo(next)
        } else {
            // Quiz complete - move to calculating screen
            completeQuiz()
        }
    }
    
    /// Go back to the previous question
    func goBack() {
        guard !isTransitioning else { return }
        guard let prev = currentStep.previous else { return }
        
        navigationDirection = .back
        transitionTo(prev)
    }
    
    /// Internal transition with animation lock
    private func transitionTo(_ step: QuizStep) {
        isTransitioning = true
        
        withAnimation(.easeInOut(duration: 0.30)) {
            currentStep = step
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            self.isTransitioning = false
        }
    }
    
    /// Can go back from current step
    var canGoBack: Bool {
        currentStep.rawValue > 0
    }
    
    // MARK: - Quiz Completion
    
    private func completeQuiz() {
        // Calculate and save the dependency score
        userData.finalizeQuizResults()
        
        // Move onboarding to calculating phase
        onboardingState.jumpTo(.quizCalculating)
    }
    
    /// Reset quiz to start (for retaking)
    func reset() {
        currentStep = .gender
        navigationDirection = .forward
    }
    
    // MARK: - Validation
    
    /// Check if current step has a valid answer
    var canContinue: Bool {
        switch currentStep {
        case .gender:
            return userData.gender != nil
        case .lastRelapseDate:
            return true // Date picker always has a value
        case .viewingFrequency:
            return userData.viewingFrequency != nil
        case .escalationToExtreme:
            return userData.escalationToExtreme != nil
        case .ageFirstExposure:
            return userData.ageFirstExposure != nil
        case .arousalDifficulty:
            return userData.arousalDifficulty != nil
        case .copingEmotional:
            return userData.copingEmotional != nil
        case .stressResponse:
            return userData.stressResponse != nil
        case .boredomResponse:
            return userData.boredomResponse != nil
        case .spentMoney:
            return userData.spentMoney != nil
        case .personalInfo:
            // Age is required, display name is optional
            return userData.age != nil
        }
    }
    
    // MARK: - Transition Helper
    
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

// MARK: - Quiz Scoring Summary

extension QuizState {
    
    /// Get a summary of all answers for the results screen
    var answerSummary: QuizAnswerSummary {
        QuizAnswerSummary(
            gender: userData.gender,
            lastRelapseDate: userData.lastRelapseDate,
            daysSinceRelapse: userData.daysSinceRelapse,
            viewingFrequency: userData.viewingFrequency,
            escalationToExtreme: userData.escalationToExtreme,
            ageFirstExposure: userData.ageFirstExposure,
            arousalDifficulty: userData.arousalDifficulty,
            copingEmotional: userData.copingEmotional,
            stressResponse: userData.stressResponse,
            boredomResponse: userData.boredomResponse,
            spentMoney: userData.spentMoney,
            dependencyScore: userData.dependencyScore
        )
    }
}

// MARK: - Answer Summary Struct

struct QuizAnswerSummary {
    let gender: Gender?
    let lastRelapseDate: Date
    let daysSinceRelapse: Int
    let viewingFrequency: ViewingFrequency?
    let escalationToExtreme: Bool?
    let ageFirstExposure: AgeFirstExposure?
    let arousalDifficulty: FrequencyResponse?
    let copingEmotional: FrequencyResponse?
    let stressResponse: FrequencyResponse?
    let boredomResponse: FrequencyResponse?
    let spentMoney: Bool?
    let dependencyScore: Double
    
    /// Text description of the score severity
    var severityText: String {
        if dependencyScore >= 85 {
            return "a severe dependency"
        } else if dependencyScore >= 75 {
            return "a significant dependency"
        } else if dependencyScore >= 65 {
            return "a moderate dependency"
        } else {
            return "some level of dependency"
        }
    }
    
    /// How much higher than average (40%)
    var aboveAveragePercent: Int {
        Int(dependencyScore - 40)
    }
}

// MARK: - Preview Helper

#if DEBUG
extension QuizState {
    static func preview(at step: QuizStep) -> QuizState {
        let state = QuizState()
        state.currentStep = step
        return state
    }
}
#endif
