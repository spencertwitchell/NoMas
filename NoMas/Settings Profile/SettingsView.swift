//
//  SettingsView.swift
//  NoMas
//
//  Profile settings and account management
//

import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userData = UserData.shared
    @StateObject private var uploader = ProfilePictureUploader()
    @StateObject private var authManager = AuthManager.shared
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var versionTapCount = 0
    @State private var lastTapTime: Date = Date()
    @State private var showDeveloperReset = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteFinalConfirmation = false
    @State private var deleteConfirmationText = ""
    @State private var isDeletingAccount = false
    @State private var deleteError: String?
    
    // Local state for isUploading to avoid concurrency issues
    @State private var isCurrentlyUploading = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picture Section
                        VStack(spacing: 12) {
                            ZStack {
                                ProfilePictureView(
                                    userName: userData.displayName,
                                    profilePictureURL: userData.profilePictureURL,
                                    isPublic: true,
                                    size: 100
                                )
                                
                                if isCurrentlyUploading {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 100, height: 100)
                                    
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.5)
                                }
                            }
                            
                            // Only show photo picker if user is authenticated
                            if authManager.isAuthenticated {
                                PhotosPicker(
                                    selection: $selectedPhoto,
                                    matching: .images
                                ) {
                                    Text(isCurrentlyUploading ? "Uploading..." : "Change Photo")
                                        .font(.bodySmall)
                                        .foregroundColor(isCurrentlyUploading ? .textTertiary : .accentGradientStart)
                                }
                                .disabled(isCurrentlyUploading)
                                .onChange(of: selectedPhoto) { oldValue, newValue in
                                    if let newValue = newValue {
                                        Task {
                                            isCurrentlyUploading = true
                                            let success = await uploader.uploadProfilePicture(from: newValue)
                                            isCurrentlyUploading = false
                                            if success {
                                                selectedPhoto = nil
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Show sign-in prompt for non-authenticated users
                                Text("Sign in to change photo")
                                    .font(.bodySmall)
                                    .foregroundColor(.textTertiary)
                            }
                            
                            if let error = uploader.uploadError {
                                Text(error)
                                    .font(.captionSmall)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Personal Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsSectionHeader(title: "Personal Info")
                            
                            SettingsTextField(
                                label: "Display Name",
                                value: $userData.displayName
                            )
                            
                            SettingsTextEditor(
                                label: "Bio",
                                value: Binding(
                                    get: { userData.bio ?? "" },
                                    set: { userData.bio = $0.isEmpty ? nil : $0 }
                                )
                            )
                            
                            SettingsTextField(
                                label: "Instagram Handle",
                                placeholder: "@username",
                                value: Binding(
                                    get: { userData.instagramHandle ?? "" },
                                    set: { userData.instagramHandle = $0.isEmpty ? nil : $0 }
                                )
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Privacy Section
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsSectionHeader(title: "Privacy")
                            
                            SettingsToggle(
                                label: "Public Profile",
                                description: "Allow others to see your profile in the community",
                                isOn: Binding(
                                    get: { userData.isProfilePublic },
                                    set: { userData.isProfilePublic = $0 }
                                )
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsSectionHeader(title: "Account")
                            
                            // Auth status
                            if authManager.isAuthenticated {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Signed In")
                                            .font(.bodySmall)
                                            .foregroundColor(.textPrimary)
                                        if let email = authManager.currentUserEmail {
                                            Text(email)
                                                .font(.captionSmall)
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                .padding(16)
                                .background(Color.surfaceBackground)
                                .cornerRadius(12)
                            }
                            
                            // Delete Account Button
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.body)
                                    Text("Delete Account")
                                        .font(.body)
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding(16)
                                .background(Color.surfaceBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Version (with hidden developer tap)
                        Text("Version \(appVersion)")
                            .font(.captionSmall)
                            .foregroundColor(.textTertiary)
                            .padding(.top, 20)
                            .onTapGesture {
                                handleVersionTap()
                            }
                        
                        // Developer Reset (hidden by default)
                        if showDeveloperReset {
                            VStack(spacing: 12) {
                                Text("🛠 Developer Tools")
                                    .font(.captionSmall)
                                    .foregroundColor(.orange)
                                
                                Button(action: {
                                    performDeveloperReset()
                                }) {
                                    Text("Reset All Data")
                                        .font(.captionSmall)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            // Delete Account - First Confirmation
            .alert("Delete Account", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showDeleteFinalConfirmation = true
                }
            } message: {
                Text("This will permanently delete your account and all your data. This action cannot be undone.")
            }
            // Delete Account - Final Confirmation
            .alert("Confirm Deletion", isPresented: $showDeleteFinalConfirmation) {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Delete Forever", role: .destructive) {
                    if deleteConfirmationText.uppercased() == "DELETE" {
                        performAccountDeletion()
                    }
                }
                .disabled(deleteConfirmationText.uppercased() != "DELETE")
            } message: {
                Text("Type DELETE to confirm you want to permanently delete your account.")
            }
        }
    }
    
    // MARK: - Version Tap Handler
    
    private func handleVersionTap() {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
        
        // Reset if more than 1 second between taps
        if timeSinceLastTap > 1.0 {
            versionTapCount = 1
        } else {
            versionTapCount += 1
        }
        
        lastTapTime = now
        
        // Show developer tools after 7 quick taps
        if versionTapCount >= 7 {
            withAnimation {
                showDeveloperReset = true
            }
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }
    
    // MARK: - Developer Reset
    
    private func performDeveloperReset() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        Task {
            // Use nukeEverything for complete reset
            await userData.nukeEverything()
            
            // Dismiss settings and let app handle re-onboarding
            dismiss()
        }
    }
    
    // MARK: - Account Deletion
    
    private func performAccountDeletion() {
        isDeletingAccount = true
        deleteError = nil
        
        Task {
            do {
                try await authManager.deleteAccount()
                
                // Use nukeEverything for complete local reset
                await userData.nukeEverything()
                
                // Dismiss settings
                dismiss()
            } catch {
                deleteError = error.localizedDescription
            }
            isDeletingAccount = false
        }
    }
}

// MARK: - Settings Section Header

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.titleSmall)
            .foregroundColor(.textPrimary)
    }
}

// MARK: - Settings Text Field

struct SettingsTextField: View {
    let label: String
    var placeholder: String = ""
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
            
            TextField("", text: $value, prompt: Text(placeholder.isEmpty ? label : placeholder).foregroundColor(.textTertiary))
                .font(.body)
                .foregroundColor(.textPrimary)
                .padding(16)
                .background(Color.surfaceBackground)
                .cornerRadius(12)
        }
    }
}

// MARK: - Settings Text Editor

struct SettingsTextEditor: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $value)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(12)
                    .background(Color.surfaceBackground)
                    .cornerRadius(12)
                
                if value.isEmpty {
                    Text("Write something about yourself...")
                        .font(.body)
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Settings Toggle

struct SettingsToggle: View {
    let label: String
    var description: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                
                if let description = description {
                    Text(description)
                        .font(.captionSmall)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.accentGradientStart)
        }
        .padding(16)
        .background(Color.surfaceBackground)
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
