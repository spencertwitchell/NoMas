import Foundation
import SwiftUI
import Combine

// MARK: - Quiz Interstitial

/// Informational pages shown between certain quiz questions
enum QuizInterstitial: String, CaseIterable {
    case adolescentBrain
    case boredomTrigger
    case financialImpact
    
    /// Which question this interstitial appears AFTER
    var appearsAfter: QuizStep {
        switch self {
        case .adolescentBrain:
            return .ageFirstExposure
        case .boredomTrigger:
            return .boredomResponse
        case .financialImpact:
            return .spentMoney
        }
    }
    
    /// Caption text (small text above header)
    var caption: String {
        switch self {
        case .adolescentBrain:
            return "Did you know?"
        case .boredomTrigger:
            return "Did you know?"
        case .financialImpact:
            return "Did you know?"
        }
    }
    
    /// Main header text
    var headerText: String {
        switch self {
        case .adolescentBrain:
            return "Early exposure to pornography has been associated with lasting effects on brain development and impulse control."
        case .boredomTrigger:
            return "Psychological research shows that pornography is often used as a coping mechanism for stress, boredom, loneliness, or emotional discomfort — not just sexual desire."
        case .financialImpact:
            return "Research shows that paying for pornography is linked to loss of control and increased difficulty stopping — a key marker of addictive behavior."
        }
    }
    
    /// Image asset name for source logo
    var sourceLogoImage: String {
        switch self {
        case .adolescentBrain:
            return "harvard logo"
        case .boredomTrigger:
            return "APAlogo" // Update with actual source
        case .financialImpact:
            return "whologo" // Update with actual source
        }
    }
    
    /// Source attribution text
    var sourceText: String {
        switch self {
        case .adolescentBrain:
            return "Source: Harvard Health Publishing – \"How pornography affects the adolescent brain\""
        case .boredomTrigger:
            return "Source: American Psychological Association – \"Stress, coping, and compulsive sexual behaviors\""
        case .financialImpact:
            return "Source: World Health Organization (WHO) – \"Compulsive Sexual Behavior Disorder\""
        }
    }
    
    /// Get interstitial that should appear after a given step (if any)
    static func interstitial(after step: QuizStep) -> QuizInterstitial? {
        return allCases.first { $0.appearsAfter == step }
    }
}

// MARK: - Quiz Step Enum

enum QuizStep: Int, CaseIterable {
    case gender = 0
    case lastRelapseDate
    case viewingFrequency
    case ageFirstExposure
    case escalationToExtreme
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
             .ageFirstExposure,
             .escalationToExtreme,
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
        case .ageFirstExposure:
            return "At what age did you first come across explicit content?"
        case .escalationToExtreme:
            return "Have you noticed a shift towards more extreme or graphic material?"
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
            print("Quiz step: \(oldValue.questionNumber) -> \(currentStep.questionNumber)")
        }
    }
    
    /// Currently showing interstitial (nil if showing a question)
    @Published private(set) var currentInterstitial: QuizInterstitial? = nil
    
    @Published private(set) var isTransitioning: Bool = false
    @Published var navigationDirection: NavigationDirection = .forward
    
    enum NavigationDirection {
        case forward
        case back
    }
    
    // MARK: - Dependencies (computed to avoid Swift 6 isolation issues)
    
    private var userData: UserData { UserData.shared }
    private var onboardingState: OnboardingState { OnboardingState.shared }
    
    // MARK: - Computed Properties
    
    /// Whether currently showing an interstitial
    var isShowingInterstitial: Bool {
        currentInterstitial != nil
    }
    
    // MARK: - Init
    
    init() {}
    
    // MARK: - Navigation
    
    /// Advance to the next question (or interstitial)
    func advance() {
        guard !isTransitioning else { return }
        
        // If currently on an interstitial, move to next question
        if currentInterstitial != nil {
            navigationDirection = .forward
            moveToNextQuestion()
            return
        }
        
        // Check if there's an interstitial after current step
        if let interstitial = QuizInterstitial.interstitial(after: currentStep) {
            navigationDirection = .forward
            transitionToInterstitial(interstitial)
            return
        }
        
        // Normal advance to next question
        if let next = currentStep.next {
            navigationDirection = .forward
            transitionTo(next)
        } else {
            // Quiz complete
            completeQuiz()
        }
    }
    
    /// Go back to the previous question (or interstitial)
    func goBack() {
        guard !isTransitioning else { return }
        
        navigationDirection = .back
        
        // If currently on an interstitial, go back to the question before it
        if let interstitial = currentInterstitial {
            transitionTo(interstitial.appearsAfter)
            return
        }
        
        // Check if there's an interstitial before current step
        if let prev = currentStep.previous,
           let interstitial = QuizInterstitial.interstitial(after: prev) {
            transitionToInterstitial(interstitial)
            return
        }
        
        // Normal go back
        guard let prev = currentStep.previous else { return }
        transitionTo(prev)
    }
    
    /// Move to the question after current interstitial
    private func moveToNextQuestion() {
        guard let interstitial = currentInterstitial else { return }
        
        if let nextStep = interstitial.appearsAfter.next {
            transitionTo(nextStep)
        } else {
            completeQuiz()
        }
    }
    
    /// Internal transition to a question
    private func transitionTo(_ step: QuizStep) {
        isTransitioning = true
        
        withAnimation(.easeInOut(duration: 0.30)) {
            currentInterstitial = nil
            currentStep = step
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            self.isTransitioning = false
        }
    }
    
    /// Internal transition to an interstitial
    private func transitionToInterstitial(_ interstitial: QuizInterstitial) {
        isTransitioning = true
        
        withAnimation(.easeInOut(duration: 0.30)) {
            currentInterstitial = interstitial
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            self.isTransitioning = false
        }
    }
    
    /// Can go back from current step
    var canGoBack: Bool {
        // Can go back if on interstitial or if not on first question
        currentInterstitial != nil || currentStep.rawValue > 0
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
        currentInterstitial = nil
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
        case .ageFirstExposure:
            return userData.ageFirstExposure != nil
        case .escalationToExtreme:
            return userData.escalationToExtreme != nil
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
