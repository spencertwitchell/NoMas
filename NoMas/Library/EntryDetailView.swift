//
//  EntryDetailView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  EntryDetailView.swift
//  NoMas
//
//  Detail view for viewing and editing a journal entry
//

import SwiftUI

struct EntryDetailView: View {
    @Environment(\.dismiss) var dismiss
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @State private var isEditing = false
    @State private var editedText: String
    @State private var showingDeleteConfirmation = false
    
    init(entry: JournalEntry, viewModel: JournalViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        _editedText = State(initialValue: entry.entryText)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Prompt (if exists)
                        if let promptText = entry.promptText {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Guía")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                
                                Text("\"\(promptText)\"")
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
                        }
                        
                        // Entry Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reflexión")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                            
                            if isEditing {
                                TextEditor(text: $editedText)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .padding(12)
                                    .frame(minHeight: 300)
                                    .background(Color.black.opacity(0.25))
                                    .cornerRadius(12)
                            } else {
                                Text(entry.entryText)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(6)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient.accent)
                                            .opacity(0.75)
                                    )
                            }
                        }
                        
                        // Timestamp
                        Text("Escribe el \(formatFullDate(entry.createdAt))")
                            .font(.captionSmall)
                            .foregroundColor(.textTertiary)
                        
                        if entry.updatedAt > entry.createdAt {
                            Text("Último cambio el \(formatFullDate(entry.updatedAt))")
                                .font(.captionSmall)
                                .foregroundColor(.textTertiary)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "Edit Entry" : "Previous Reflection")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        if isEditing {
                            editedText = entry.entryText
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: isEditing ? "xmark" : "chevron.left")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button(action: {
                            Task {
                                let success = await viewModel.updateEntry(id: entry.id, newText: editedText)
                                if success {
                                    isEditing = false
                                    dismiss()
                                }
                            }
                        }) {
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Guardar")
                                    .font(.bodySmall)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(editedText.isEmpty || viewModel.isSaving)
                    } else {
                        Menu {
                            Button(action: {
                                isEditing = true
                            }) {
                                Label("Editar", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                showingDeleteConfirmation = true
                            }) {
                                Label("Borrar", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("Borrar Entrada", isPresented: $showingDeleteConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Borrar", role: .destructive) {
                Task {
                    await viewModel.deleteEntry(id: entry.id)
                    dismiss()
                }
            }
        } message: {
            Text("¿Estás seguro de que deseas eliminar esta entrada del diario? Esta acción no se puede deshacer.")
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    EntryDetailView(
        entry: JournalEntry(
            id: UUID(),
            userId: UUID(),
            promptId: UUID(),
            promptText: "¿Qué te activó hoy y cómo lo manejaste?",
            entryText: "Hoy me sentí activado cuando estaba solo y aburrido. Lo manejé saliendo a caminar y llamando a un amigo.",
            createdAt: Date(),
            updatedAt: Date()
        ),
        viewModel: JournalViewModel()
    )
}
