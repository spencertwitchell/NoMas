//
//  ReflectionJournalView.swift
//  NoMas
//
//  Main view for the reflection journal feature
//

import SwiftUI

struct ReflectionJournalView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = JournalViewModel()
    @State private var entryText = ""
    @State private var showingPastEntries = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                if viewModel.isLoading && viewModel.currentPrompt == nil {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Prompt of the Day
                            promptSection
                            
                            // Text Entry Area
                            entrySection
                            
                            // Action Buttons
                            actionButtons
                            
                            Spacer()
                                .frame(height: 40)
                        }
                        .padding(.top, 4)
                    }
                    .onTapGesture {
                        isTextFieldFocused = false
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Recovery Journal")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingPastEntries) {
            PastEntriesView(viewModel: viewModel)
        }
        .task {
            await viewModel.fetchRandomPrompt()
        }
    }
    
    // MARK: - Prompt Section
    
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt of the Day")
                .font(.titleSmall)
                .foregroundColor(.white)
            
            if let prompt = viewModel.currentPrompt {
                Text("\"\(prompt.promptText)\"")
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient.accent)
                            .opacity(0.75)
                    )
            }
            
            Button(action: {
                viewModel.getNextPrompt()
            }) {
                HStack(spacing: 6) {
                    Text("Show Me Another")
                        .font(.caption)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Entry Section
    
    private var entrySection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $entryText)
                    .font(.body)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .padding(16)
                    .background(Color.black.opacity(0.25))
                    .cornerRadius(12)
                    .focused($isTextFieldFocused)
                
                if entryText.isEmpty {
                    Text("Enter your thoughts here...")
                        .font(.body)
                        .foregroundColor(.textTertiary)
                        .padding(24)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 350)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save to Journal Button
            Button(action: {
                isTextFieldFocused = false
                Task {
                    let success = await viewModel.saveEntry(text: entryText, prompt: viewModel.currentPrompt)
                    if success {
                        entryText = ""
                        await viewModel.fetchRandomPrompt()
                    }
                }
            }) {
                ZStack {
                    HStack(spacing: 8) {
                        Text("Save to Journal")
                            .font(.button)
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .opacity(viewModel.isSaving ? 0 : 1)
                    
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(LinearGradient.accent)
                .cornerRadius(12)
            }
            .disabled(entryText.isEmpty || viewModel.isSaving)
            .opacity(entryText.isEmpty ? 0.5 : 1.0)
            
            // View Past Entries Button
            Button(action: {
                isTextFieldFocused = false
                showingPastEntries = true
            }) {
                HStack(spacing: 8) {
                    Text("View Your Past Journal Entries")
                        .font(.buttonSmall)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.clear)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

#Preview {
    ReflectionJournalView()
}
