//
//  NomiQuizView.swift
//  NoMas
//
//  Quiz flow for Nomi AI context gathering
//  Structure matches NoContact AIQuizView for proper keyboard handling
//

import SwiftUI

struct NomiQuizView: View {
    @ObservedObject var viewModel: NomiViewModel
    @Binding var isPresented: Bool
    
    @State private var currentPage = 0
    @State private var isSaving = false
    
    // Pages: 0 = Welcome, 1-7 = Questions, 8 = Thank You
    private let totalPages = 8
    
    var body: some View {
        ZStack {
            // Base gradient background
            AppBackground()
                .ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 0) {
                    // Progress header (shown for questions only, not welcome or thank you)
                    if currentPage > 0 && currentPage < totalPages {
                        progressHeader
                    }
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            pageContent
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, currentPage == 0 ? 40 : 20)
                        .padding(.bottom, 40)
                    }
                }
                .background(
                    ZStack {
                        Image("bg7")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                        
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                    }
                )
                // safeAreaInset keeps button above keyboard
                .safeAreaInset(edge: .bottom) {
                    if currentPage > 0 && currentPage < totalPages {
                        navigationButtons
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                            .background(.clear)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if currentPage > 0 {
                            currentPage -= 1
                        } else {
                            isPresented = false
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient.accent)
                            .frame(width: geometry.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
                
                Spacer()
                
                // Symmetry spacer
                Color.clear
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }
    
    private var progress: CGFloat {
        CGFloat(currentPage) / CGFloat(totalPages)
    }
    
    // MARK: - Page Content
    
    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            welcomePage
        case 1:
            questionPage(
                title: "How long have you been struggling with porn use?",
                subtitle: "Weeks, months, or years — just share what feels accurate.",
                binding: $viewModel.quizData.struggleDuration
            )
        case 2:
            questionPage(
                title: "How would you describe your relationship with porn right now?",
                subtitle: "Occasional but hard to control, or something that feels compulsive? Describe your current pattern.",
                binding: $viewModel.quizData.currentRelationship
            )
        case 3:
            questionPage(
                title: "What usually triggers the urge to watch porn?",
                subtitle: "Boredom, stress, loneliness, late nights, emotions, or habits — noticing triggers helps you regain control.",
                binding: $viewModel.quizData.triggers
            )
        case 4:
            questionPage(
                title: "When are you most likely to give in to the urge?",
                subtitle: "Time of day, location, mood, or specific situations where it tends to happen.",
                binding: $viewModel.quizData.vulnerableSituations
            )
        case 5:
            questionPage(
                title: "How does porn use tend to make you feel afterward?",
                subtitle: "Relief, numbness, guilt, frustration, or something else — be honest about what comes up.",
                binding: $viewModel.quizData.postUseFeelings
            )
        case 6:
            questionPage(
                title: "What negative effects has this had on your life?",
                subtitle: "Motivation, confidence, relationships, mental health, focus, or energy — whatever feels most relevant.",
                binding: $viewModel.quizData.negativeEffects
            )
        case 7:
            questionPage(
                title: "What's motivating you to want change right now?",
                subtitle: "A relationship, your future self, mental clarity, confidence, or being tired of the cycle — what pushed you to act?",
                binding: $viewModel.quizData.motivationForChange
            )
        case 8:
            thankYouPage
        default:
            EmptyView()
        }
    }
    
    // MARK: - Welcome Page
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Placeholder animation (replace with Lottie later)
            Image("heart_blue")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            
            VStack(spacing: 12) {
                Text("Let's Get to Know You")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                
                Text("Answer a few questions so Nomi can better understand your situation and provide more personalized support.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentPage = 1
                }
            } label: {
                Text("Enter Details")
                    .font(.button)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient.accent)
                    .cornerRadius(26)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Question Page
    
    private func questionPage(title: String, subtitle: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // TextEditor for long-form answers
            TextEditor(text: binding)
                .font(.body)
                .foregroundColor(.textPrimary)
                .frame(minHeight: 150)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.25))
                .cornerRadius(12)
            
            Spacer(minLength: 0)
        }
    }
    
    // MARK: - Thank You Page
    
    private var thankYouPage: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Placeholder animation (replace with Lottie later)
            Image("heart_blue")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
            
            VStack(spacing: 12) {
                Text("Thank You for Sharing")
                    .font(.titleLarge)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Opening up isn't easy, but it's the first step toward real change. Nomi now has a better understanding of your journey and is ready to support you.")
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            Button {
                Task {
                    isSaving = true
                    do {
                        try await viewModel.saveQuizData()
                        await viewModel.loadConversations()
                        await MainActor.run {
                            isPresented = false
                        }
                    } catch {
                        viewModel.errorMessage = "Failed to save: \(error.localizedDescription)"
                    }
                    isSaving = false
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient.accent)
                        .cornerRadius(26)
                } else {
                    Text("Start Chatting with Nomi")
                        .font(.button)
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LinearGradient.accent)
                        .cornerRadius(26)
                }
            }
            .disabled(isSaving)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.captionSmall)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    currentPage += 1
                }
            } label: {
                Text("Continue")
                    .font(.button)
                    .foregroundColor(.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Group {
                            if canContinue {
                                LinearGradient.accent
                            } else {
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .cornerRadius(26)
            }
            .disabled(!canContinue)
        }
    }
    
    private var canContinue: Bool {
        switch currentPage {
        case 1: return !viewModel.quizData.struggleDuration.trimmed.isEmpty
        case 2: return !viewModel.quizData.currentRelationship.trimmed.isEmpty
        case 3: return !viewModel.quizData.triggers.trimmed.isEmpty
        case 4: return !viewModel.quizData.vulnerableSituations.trimmed.isEmpty
        case 5: return !viewModel.quizData.postUseFeelings.trimmed.isEmpty
        case 6: return !viewModel.quizData.negativeEffects.trimmed.isEmpty
        case 7: return !viewModel.quizData.motivationForChange.trimmed.isEmpty
        default: return true
        }
    }
}

// MARK: - String Extension

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.4).ignoresSafeArea()
        NomiQuizView(viewModel: NomiViewModel(), isPresented: .constant(true))
    }
}
