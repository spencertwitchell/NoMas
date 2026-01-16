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
            return "¿Sabías que?"
        case .boredomTrigger:
            return "¿Sabías que?"
        case .financialImpact:
            return "¿Sabías que?"
        }
    }
    
    /// Main header text
    var headerText: String {
        switch self {
        case .adolescentBrain:
            return "La exposición temprana a la pornografía se ha asociado con efectos duraderos en el desarrollo del cerebro y el control de los impulsos."
        case .boredomTrigger:
            return "La investigación psicológica muestra que la pornografía a menudo se utiliza como un mecanismo de afrontamiento para el estrés, el aburrimiento, la soledad o el malestar emocional, no solo por deseo sexual."
        case .financialImpact:
            return "Las investigaciones muestran que pagar por pornografía está relacionado con la pérdida de control y una mayor dificultad para dejarla, un indicador clave de comportamiento adictivo."
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
            return "Fuente: Harvard Health Publishing – \"How pornography affects the adolescent brain\""
        case .boredomTrigger:
            return "Fuente: American Psychological Association – \"Stress, coping, and compulsive sexual behaviors\""
        case .financialImpact:
            return "Fuente: World Health Organization (WHO) – \"Compulsive Sexual Behavior Disorder\""
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
            return "¿Cuál es tu género?"
        case .lastRelapseDate:
            return "¿Cuándo fue la última vez que viste pornografía?"
        case .viewingFrequency:
            return "¿Con qué frecuencia sueles ver pornografía?"
        case .ageFirstExposure:
            return "¿A qué edad tuviste tu primer contacto con contenido explícito?"
        case .escalationToExtreme:
            return "¿Has notado un cambio hacia pornografía más extrema o gráfica?"
        case .arousalDifficulty:
            return "¿Te resulta difícil lograr excitación sexual sin pornografía o fantasía?"
        case .copingEmotional:
            return "¿Usas la pornografía como una forma de lidiar con el malestar o dolor emocional?"
        case .stressResponse:
            return "¿Recurres a la pornografía cuando te sientes estresado?"
        case .boredomResponse:
            return "¿Ves pornografía por aburrimiento?"
        case .spentMoney:
            return "Aproximadamente, ¿cuánto gastas al mes en contenido explícito?"
        case .personalInfo:
            return "Por último, un poco más sobre ti"
        }
        }

        /// Optional subtitle/helper text
        var questionSubtitle: String? {
            switch self {
            case .lastRelapseDate:
                return "Esto nos ayuda a seguir tu progreso desde el inicio"
            case .personalInfo:
                return "Esto ayuda a personalizar tu experiencia"
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
            return userData.monthlySpending != nil
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
            monthlySpending: userData.monthlySpending,
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
    let monthlySpending: MonthlySpending?
    let dependencyScore: Double
    
    /// Text description of the score severity
    var severityText: String {
        if dependencyScore >= 85 {
            return "una dependencia grave"
        } else if dependencyScore >= 75 {
            return "una dependencia significativa"
        } else if dependencyScore >= 65 {
            return "una dependencia moderada"
        } else {
            return "algún nivel de dependencia"
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
