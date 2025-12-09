import SwiftUI

// MARK: - Quiz Flow Container

struct OnboardingQuizFlow: View {
    @StateObject private var quizState = QuizState()
    @StateObject private var userData = UserData.shared  // Observe userData to update Continue button
    
    var body: some View {
        ZStack {
            // Background
            AppBackground()
            
            // Content
            VStack(spacing: 0) {
                // Header with progress bar and back button
                QuizHeader(quizState: quizState)
                
                // Question content (slides left/right)
                ScrollView(showsIndicators: false) {
                    questionContent
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 100) // Space for continue button
                }
                .id(quizState.currentStep) // Force refresh on step change
                .transition(quizState.slideTransition)
                .animation(.easeInOut(duration: 0.30), value: quizState.currentStep)
            }
            
            // Continue button (fixed at bottom for non-auto-advance questions)
            if quizState.currentStep.showsContinueButton {
                VStack {
                    Spacer()
                    
                    QuizContinueButton(
                        title: "Continue",
                        isEnabled: canContinue,  // Use local computed property that reads from userData
                        action: { quizState.advance() }
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    // MARK: - Validation (reads directly from observed userData)
    
    /// Check if current step has a valid answer
    /// This is computed here so it updates when userData changes
    private var canContinue: Bool {
        switch quizState.currentStep {
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
    
    // MARK: - Question Router
    
    @ViewBuilder
    private var questionContent: some View {
        switch quizState.currentStep {
        case .gender:
            GenderQuestion(quizState: quizState)
        case .lastRelapseDate:
            LastRelapseDateQuestion(quizState: quizState)
        case .viewingFrequency:
            ViewingFrequencyQuestion(quizState: quizState)
        case .escalationToExtreme:
            EscalationQuestion(quizState: quizState)
        case .ageFirstExposure:
            AgeFirstExposureQuestion(quizState: quizState)
        case .arousalDifficulty:
            ArousalDifficultyQuestion(quizState: quizState)
        case .copingEmotional:
            CopingEmotionalQuestion(quizState: quizState)
        case .stressResponse:
            StressResponseQuestion(quizState: quizState)
        case .boredomResponse:
            BoredomResponseQuestion(quizState: quizState)
        case .spentMoney:
            SpentMoneyQuestion(quizState: quizState)
        case .personalInfo:
            PersonalInfoQuestion(quizState: quizState)
        }
    }
}

// MARK: - Question 1: Gender

struct GenderQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 32) {
            QuizQuestionTitle(
                title: QuizStep.gender.questionTitle
            )
            
            QuizGenderButtons(
                selection: userData.gender,
                onSelect: { gender in
                    userData.gender = gender
                    // Small delay for visual feedback before advancing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        quizState.advance()
                    }
                }
            )
        }
    }
}

// MARK: - Question 2: Last Relapse Date

struct LastRelapseDateQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 24) {
            QuizQuestionTitle(
                title: QuizStep.lastRelapseDate.questionTitle,
                subtitle: QuizStep.lastRelapseDate.questionSubtitle
            )
            
            QuizDatePicker(
                selection: Binding(
                    get: { userData.lastRelapseDate },
                    set: { userData.lastRelapseDate = $0 }
                ),
                title: ""
            )
        }
    }
}

// MARK: - Question 3: Viewing Frequency

struct ViewingFrequencyQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 24) {
            QuizQuestionTitle(
                title: QuizStep.viewingFrequency.questionTitle
            )
            
            VStack(spacing: 12) {
                ForEach(ViewingFrequency.allCases) { frequency in
                    QuizOptionButton(
                        text: frequency.displayName,
                        isSelected: userData.viewingFrequency == frequency,
                        action: {
                            userData.viewingFrequency = frequency
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                quizState.advance()
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Question 4: Escalation to Extreme Content

struct EscalationQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 32) {
            QuizQuestionTitle(
                title: QuizStep.escalationToExtreme.questionTitle
            )
            
            QuizYesNoButtons(
                selection: userData.escalationToExtreme,
                onSelect: { value in
                    userData.escalationToExtreme = value
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        quizState.advance()
                    }
                }
            )
        }
    }
}

// MARK: - Question 5: Age of First Exposure

struct AgeFirstExposureQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 24) {
            QuizQuestionTitle(
                title: QuizStep.ageFirstExposure.questionTitle
            )
            
            VStack(spacing: 12) {
                ForEach(AgeFirstExposure.allCases) { age in
                    QuizOptionButton(
                        text: age.displayName,
                        isSelected: userData.ageFirstExposure == age,
                        action: {
                            userData.ageFirstExposure = age
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                quizState.advance()
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Question 6: Arousal Difficulty

struct ArousalDifficultyQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 24) {
            QuizQuestionTitle(
                title: QuizStep.arousalDifficulty.questionTitle
            )
            
            QuizFrequencyButtons(
                selection: userData.arousalDifficulty,
                onSelect: { response in
                    userData.arousalDifficulty = response
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        quizState.advance()
                    }
                }
            )
        }
    }
}

// MARK: - Question 7: Coping with Emotional Pain

struct CopingEmotionalQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 24) {
            QuizQuestionTitle(
                title: QuizStep.copingEmotional.questionTitle
            )
            
            QuizFrequencyButtons(
                selection: userData.copingEmotional,
                onSelect: { response in
                    userData.copingEmotional = response
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        quizState.advance()
                    }
                }
            )
        }
    }
}

// MARK: - Question 8: Stress Response

struct StressResponseQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 24) {
            QuizQuestionTitle(
                title: QuizStep.stressResponse.questionTitle
            )
            
            QuizFrequencyButtons(
                selection: userData.stressResponse,
                onSelect: { response in
                    userData.stressResponse = response
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        quizState.advance()
                    }
                }
            )
        }
    }
}

// MARK: - Question 9: Boredom Response

struct BoredomResponseQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 24) {
            QuizQuestionTitle(
                title: QuizStep.boredomResponse.questionTitle
            )
            
            QuizFrequencyButtons(
                selection: userData.boredomResponse,
                onSelect: { response in
                    userData.boredomResponse = response
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        quizState.advance()
                    }
                }
            )
        }
    }
}

// MARK: - Question 10: Spent Money

struct SpentMoneyQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    var body: some View {
        VStack(spacing: 32) {
            QuizQuestionTitle(
                title: QuizStep.spentMoney.questionTitle
            )
            
            QuizYesNoButtons(
                selection: userData.spentMoney,
                onSelect: { value in
                    userData.spentMoney = value
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        quizState.advance()
                    }
                }
            )
        }
    }
}

// MARK: - Question 11: Personal Info

struct PersonalInfoQuestion: View {
    @ObservedObject var quizState: QuizState
    private var userData: UserData { UserData.shared }
    
    @State private var displayName: String = ""
    @State private var age: Int? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            QuizQuestionTitle(
                title: QuizStep.personalInfo.questionTitle,
                subtitle: QuizStep.personalInfo.questionSubtitle
            )
            
            VStack(spacing: 24) {
                // Display Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    QuizTextField(
                        placeholder: "Optional",
                        text: $displayName
                    )
                }
                
                // Age
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                    
                    QuizNumberField(
                        placeholder: "Required",
                        value: $age
                    )
                }
            }
        }
        .onAppear {
            displayName = userData.displayName
            age = userData.age
        }
        .onChange(of: displayName) { _, newValue in
            userData.displayName = newValue
        }
        .onChange(of: age) { _, newValue in
            userData.age = newValue
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingQuizFlow()
}
