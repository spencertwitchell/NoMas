//
//  PastEntriesView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  PastEntriesView.swift
//  NoMas
//
//  View for browsing past journal entries
//

import SwiftUI

struct PastEntriesView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: JournalViewModel
    @State private var selectedEntry: JournalEntry?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if viewModel.groupedEntries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Reflections")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry, viewModel: viewModel)
        }
        .task {
            await viewModel.fetchEntries()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.textTertiary)
            
            Text("No journal entries yet")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            Text("Start reflecting to see your entries here")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
    }
    
    // MARK: - Entries List
    
    private var entriesList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.groupedEntries) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title)
                            .font(.titleSmall)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        ForEach(group.entries) { entry in
                            EntryCard(entry: entry) {
                                selectedEntry = entry
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Total count
                Text("\(viewModel.entries.count) \(viewModel.entries.count == 1 ? "Entry" : "Entries") Total")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
            }
            .padding(.top, 20)
        }
    }
}

// MARK: - Entry Card Component

struct EntryCard: View {
    let entry: JournalEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                if let promptText = entry.promptText {
                    Text("\"\(promptText)\"")
                        .font(.buttonSmall)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                
                Text(entry.entryText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Text(formatDate(entry.createdAt))
                    .font(.captionSmall)
                    .foregroundColor(.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.accent)
                    .opacity(0.75)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy - h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    PastEntriesView(viewModel: JournalViewModel())
}
