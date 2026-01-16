//
//  CreatePostView.swift
//  NoMas
//
//  View for creating new community posts
//

import SwiftUI
import Supabase

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var postBody = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var userData: UserData { UserData.shared }
    
    let onPostCreated: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 0) {
                    // Scrollable content area
                    ScrollView {
                        VStack(spacing: 20) {
                            // Title input
                            TextField("", text: $title)
                                .placeholder(when: title.isEmpty) {
                                    Text("Ingresa un título...")
                                        .foregroundColor(.textTertiary)
                                }
                                .foregroundColor(.textPrimary)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.surfaceBackground)
                                .cornerRadius(12)
                            
                            // Body input
                            ZStack(alignment: .topLeading) {
                                if postBody.isEmpty {
                                    Text("Comparte tus pensamientos, dificultades o logros...")
                                        .foregroundColor(.textTertiary)
                                        .font(.body)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                }
                                
                                TextEditor(text: $postBody)
                                    .foregroundColor(.textPrimary)
                                    .font(.body)
                                    .scrollContentBackground(.hidden)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                            }
                            .frame(height: 200)
                            .background(Color.surfaceBackground)
                            .cornerRadius(12)
                            
                            // Privacy reminder
                            HStack(spacing: 8) {
                                Image(systemName: userData.isProfilePublic ? "eye" : "eye.slash")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textTertiary)
                                
                                Text(userData.isProfilePublic
                                    ? "Tu nombre será visible en este post"
                                    : "Estás posteando de forma anónima")
                                    .font(.captionSmall)
                                    .foregroundColor(.textSecondary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding(20)
                        .padding(.bottom, 90)
                    }
                    
                    // Floating submit button
                    Button {
                        Task {
                            await submitPost()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(LinearGradient.accent)
                                .frame(height: 56)
                                .shadow(color: Color.accentGradientStart.opacity(0.4), radius: 8, y: 4)
                            
                            if isSubmitting {
                                ProgressView()
                                    .tint(.textPrimary)
                            } else {
                                Text("Postear")
                                    .foregroundColor(.textPrimary)
                                    .font(.button)
                            }
                        }
                    }
                    .disabled(title.isEmpty || postBody.isEmpty || isSubmitting)
                    .opacity((title.isEmpty || postBody.isEmpty) ? 0.5 : 1.0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.backgroundGradientEnd.opacity(0),
                                Color.backgroundGradientEnd
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .offset(y: -30)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create Post")
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textPrimary)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitPost() async {
        guard let userId = userData.supabaseUserId else {
            errorMessage = "Debes iniciar sesión para publicar"
            showError = true
            return
        }
        
        guard !title.isEmpty && !postBody.isEmpty else {
            errorMessage = "Por favor, completa tanto el título como el contenido."
            showError = true
            return
        }
        
        isSubmitting = true
        
        do {
            struct PostInsert: Encodable {
                let user_id: String
                let title: String
                let body: String
            }
            
            let post = PostInsert(
                user_id: userId.uuidString,
                title: title,
                body: postBody
            )
            
            try await supabase
                .from("posts")
                .insert(post)
                .execute()
            
            print("✅ Post created successfully")
            onPostCreated()
            dismiss()
        } catch {
            print("❌ Failed to create post: \(error)")
            errorMessage = "No se pudo crear la publicación. Por favor, inténtalo de nuevo."
            showError = true
            isSubmitting = false
        }
    }
}

// MARK: - Preview

#Preview {
    CreatePostView(onPostCreated: {})
}
