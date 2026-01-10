import SwiftUI

// MARK: - Quiz Interstitial View

struct QuizInterstitialView: View {
    let interstitial: QuizInterstitial
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            // Background image with dark overlay
            GeometryReader { geometry in
                Image("bg67")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.6))
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button at top
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                Spacer()
                
                // Content
                VStack(spacing: 24) {
                    // Caption
                    Text(interstitial.caption)
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    // Header text
                    Text(interstitial.headerText)
                        .font(.titleMedium)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Source logo
                    Image(interstitial.sourceLogoImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 60)
                        .padding(.top, 16)
                    
                    // Source text
                    Text(interstitial.sourceText)
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue button
                QuizContinueButton(
                    title: "Continue",
                    isEnabled: true,
                    action: onContinue
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Quiz Header (Progress Bar + Back Button)

struct QuizHeader: View {
    @ObservedObject var quizState: QuizState
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * quizState.currentStep.progress, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: quizState.currentStep)
                }
            }
            .frame(height: 8)
            
            // Back button + Question counter
            HStack {
                // Back button - HIDDEN on first question, shown otherwise
                if quizState.canGoBack {
                    Button(action: { quizState.goBack() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.9))
                    }
                } else {
                    // Invisible spacer to maintain layout
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.clear)
                }
                
                Spacer()
                
                // Question counter - changed to "Question #X" format
                Text("Question #\(quizState.currentStep.questionNumber)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

// MARK: - Quiz Question Title

struct QuizQuestionTitle: View {
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.titleMedium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            if let subtitle = subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Single Choice Option Button (Auto-Advance)

struct QuizOptionButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.12)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Yes/No Button Pair

struct QuizYesNoButtons: View {
    let selection: Bool?
    let onSelect: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            QuizYesNoButton(
                text: "Yes",
                isSelected: selection == true,
                action: { onSelect(true) }
            )
            
            QuizYesNoButton(
                text: "No",
                isSelected: selection == false,
                action: { onSelect(false) }
            )
        }
    }
}

struct QuizYesNoButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.white.opacity(0.12)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
                )
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gender Selection Buttons

struct QuizGenderButtons: View {
    let selection: Gender?
    let onSelect: (Gender) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach([Gender.male, Gender.female], id: \.self) { gender in
                QuizGenderButton(
                    gender: gender,
                    isSelected: selection == gender,
                    action: { onSelect(gender) }
                )
            }
        }
    }
}

struct QuizGenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        gender == .male ? "figure.stand" : "figure.stand.dress"
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                Text(gender.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.white.opacity(0.12)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Frequency Response Buttons (Frequently/Occasionally/Rarely)

struct QuizFrequencyButtons: View {
    let selection: FrequencyResponse?
    let onSelect: (FrequencyResponse) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(FrequencyResponse.allCases) { response in
                QuizOptionButton(
                    text: response.displayName,
                    isSelected: selection == response,
                    action: { onSelect(response) }
                )
            }
        }
    }
}

// MARK: - Continue Button

struct QuizContinueButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .opacity(isEnabled ? 1.0 : 0.4)
                )
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Monthly Spending Slider

struct QuizMonthlySpendingSlider: View {
    @Binding var selection: MonthlySpending?
    let onSelect: (MonthlySpending) -> Void
    
    @State private var sliderValue: Double = 0
    
    private let stops = MonthlySpending.allCases
    private let stopCount = MonthlySpending.allCases.count
    
    var body: some View {
        VStack(spacing: 24) {
            // Current value display
            Text(currentDisplayValue)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: sliderValue)
            
            // Slider
            VStack(spacing: 12) {
                // Custom slider track with snap points
                GeometryReader { geometry in
                    let trackWidth = geometry.size.width
                    let stepWidth = trackWidth / CGFloat(stopCount - 1)
                    
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Filled portion
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(sliderValue) * stepWidth, height: 8)
                        
                        // Stop markers
                        HStack(spacing: 0) {
                            ForEach(0..<stopCount, id: \.self) { index in
                                Circle()
                                    .fill(index <= Int(sliderValue.rounded()) ? Color.accentGradientEnd : Color.white.opacity(0.4))
                                    .frame(width: 12, height: 12)
                                if index < stopCount - 1 {
                                    Spacer()
                                }
                            }
                        }
                        
                        // Draggable thumb
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentGradientStart, Color.accentGradientEnd]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .shadow(color: Color.accentGradientStart.opacity(0.5), radius: 8, x: 0, y: 4)
                            .offset(x: CGFloat(sliderValue) * stepWidth - 14)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let newValue = value.location.x / stepWidth
                                        sliderValue = min(max(0, newValue), Double(stopCount - 1))
                                    }
                                    .onEnded { _ in
                                        // Snap to nearest stop
                                        let snappedIndex = Int(sliderValue.rounded())
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            sliderValue = Double(snappedIndex)
                                        }
                                        let spending = MonthlySpending.fromSliderIndex(snappedIndex)
                                        onSelect(spending)
                                    }
                            )
                    }
                }
                .frame(height: 28)
                .padding(.horizontal, 14) // Account for thumb width
                
                // Labels
                HStack {
                    ForEach(0..<stopCount, id: \.self) { index in
                        Text(stops[index].displayName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(index == Int(sliderValue.rounded()) ? .white : .white.opacity(0.5))
                        if index < stopCount - 1 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            if let selection = selection {
                sliderValue = Double(selection.sliderIndex)
            }
        }
    }
    
    private var currentDisplayValue: String {
        let index = Int(sliderValue.rounded())
        return MonthlySpending.fromSliderIndex(index).displayName
    }
}

// MARK: - Date Picker Style

struct QuizDatePicker: View {
    @Binding var selection: Date
    let title: String
    
    var body: some View {
        VStack(spacing: 16) {
            DatePicker(
                title,
                selection: $selection,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(Color.accentGradientStart)
            .colorScheme(.dark)
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - Text Input Field

struct QuizTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
            .font(.system(size: 18))
            .foregroundColor(.white)
            .keyboardType(keyboardType)
            .padding(20)
            .background(Color.white.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(16)
    }
}

// MARK: - Number Input Field (for Age)

struct QuizNumberField: View {
    let placeholder: String
    @Binding var value: Int?
    
    @State private var textValue: String = ""
    
    var body: some View {
        TextField("", text: $textValue, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
            .font(.system(size: 18))
            .foregroundColor(.white)
            .keyboardType(.numberPad)
            .padding(20)
            .background(Color.white.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .cornerRadius(16)
            .onChange(of: textValue) { _, newValue in
                // Filter to only digits
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    textValue = filtered
                }
                // Convert to Int
                value = Int(filtered)
            }
            .onAppear {
                // Initialize text from value
                if let value = value {
                    textValue = String(value)
                }
            }
    }
}

// MARK: - Background View

struct QuizBackground: View {
    var body: some View {
        AppBackground()
    }
}

// MARK: - Previews

#Preview("Option Button") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            QuizOptionButton(text: "More than once a day", isSelected: true, action: {})
            QuizOptionButton(text: "Once a day", isSelected: false, action: {})
            QuizOptionButton(text: "A few times a week", isSelected: false, action: {})
        }
        .padding()
    }
}

#Preview("Yes/No Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        QuizYesNoButtons(selection: true, onSelect: { _ in })
            .padding()
    }
}

#Preview("Gender Buttons") {
    ZStack {
        Color.black.ignoresSafeArea()
        QuizGenderButtons(selection: .male, onSelect: { _ in })
            .padding()
    }
}

#Preview("Continue Button") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 16) {
            QuizContinueButton(title: "Continue", isEnabled: true, action: {})
            QuizContinueButton(title: "Continue", isEnabled: false, action: {})
        }
        .padding()
    }
}

#Preview("Interstitial") {
    QuizInterstitialView(
        interstitial: .adolescentBrain,
        onContinue: {},
        onBack: {}
    )
}

#Preview("Monthly Spending Slider") {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            QuizMonthlySpendingSlider(
                selection: .constant(.thirty),
                onSelect: { _ in }
            )
            .padding()
        }
    }
}
