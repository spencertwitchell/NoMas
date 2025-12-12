//
//  SettingsView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/11/25.
//


//
//  SettingsView.swift
//  NoMas
//
//  Profile settings and account management
//

import SwiftUI
import PhotosUI
import Combine

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
    @State private var showSignOutConfirmation = false
    
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
                                
                                if uploader.isUploading {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 100, height: 100)
                                    
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(1.5)
                                }
                            }
                            
                            PhotosPicker(
                                selection: $selectedPhoto,
                                matching: .images
                            ) {
                                Text(uploader.isUploading ? "Uploading..." : "Change Photo")
                                    .font(.bodySmall)
                                    .foregroundColor(uploader.isUploading ? .textTertiary : .accentGradientStart)
                            }
                            .disabled(uploader.isUploading)
                            .onChange(of: selectedPhoto) { oldValue, newValue in
                                if let newValue = newValue {
                                    Task {
                                        let success = await uploader.uploadProfilePicture(from: newValue)
                                        if success {
                                            selectedPhoto = nil
                                        }
                                    }
                                }
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
                                value: Binding(
                                    get: { userData.instagramHandle ?? "" },
                                    set: { userData.instagramHandle = $0.isEmpty ? nil : $0 }
                                ),
                                prefix: "@",
                                disableAutocorrection: true
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Privacy Section
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsSectionHeader(title: "Privacy")
                            
                            Toggle(isOn: $userData.isProfilePublic) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Public Profile")
                                        .foregroundColor(.textPrimary)
                                        .font(.body)
                                    Text("Your name, bio, photo, and Instagram will be visible in the community")
                                        .foregroundColor(.textSecondary)
                                        .font(.captionSmall)
                                }
                            }
                            .tint(.accentGradientStart)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.surfaceBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsSectionHeader(title: "Account")
                            
                            if let email = authManager.currentUserEmail {
                                HStack {
                                    Text("Email")
                                        .foregroundColor(.textSecondary)
                                        .font(.body)
                                    Spacer()
                                    Text(email)
                                        .foregroundColor(.textPrimary)
                                        .font(.body)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.surfaceBackground)
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showSignOutConfirmation = true
                            }) {
                                Text("Sign Out")
                                    .font(.body)
                                    .foregroundColor(.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.surfaceBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Developer Reset (only shows after 7 fast taps)
                        if showDeveloperReset {
                            VStack(alignment: .leading, spacing: 16) {
                                SettingsSectionHeader(title: "Developer Tools")
                                
                                Button {
                                    Task {
                                        await userData.nukeEverything()
                                        dismiss()
                                    }
                                } label: {
                                    Text("☢️ Nuke Everything (Fresh Install)")
                                        .font(.body)
                                        .foregroundColor(.orange)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(Color.orange.opacity(0.15))
                                        .cornerRadius(12)
                                }
                                
                                Text("Clears all local data, keychain, and Supabase session. App will restart as if freshly installed.")
                                    .font(.captionSmall)
                                    .foregroundColor(.textTertiary)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Danger Zone
                        VStack(alignment: .leading, spacing: 16) {
                            SettingsSectionHeader(title: "Danger Zone")
                            
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                VStack(spacing: 8) {
                                    Text("Delete Account & Data")
                                        .font(.body)
                                        .foregroundColor(.red)
                                    
                                    Text("Permanently delete your account and all data. This cannot be undone.")
                                        .font(.captionSmall)
                                        .foregroundColor(.textTertiary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Version Number (tap 7 times fast to show developer reset)
                        Button {
                            let now = Date()
                            let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
                            
                            // Reset count if more than 1 second between taps
                            if timeSinceLastTap > 1.0 {
                                versionTapCount = 1
                            } else {
                                versionTapCount += 1
                            }
                            
                            lastTapTime = now
                            
                            if versionTapCount >= 7 {
                                withAnimation {
                                    showDeveloperReset = true
                                }
                                // Haptic feedback
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            }
                        } label: {
                            Text("Version \(appVersion)")
                                .font(.captionSmall)
                                .foregroundColor(.textTertiary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.titleSmall)
                        .foregroundColor(.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textPrimary)
                            .font(.system(size: 16))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Sign Out?", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Continue", role: .destructive) {
                    showDeleteFinalConfirmation = true
                }
            } message: {
                Text("This will permanently delete:\n\n• All your data\n• Your subscription access\n• Your account progress\n• All community posts\n\nThis cannot be recovered.")
            }
            .alert("Final Confirmation", isPresented: $showDeleteFinalConfirmation) {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Delete Forever", role: .destructive) {
                    if deleteConfirmationText == "DELETE" {
                        Task {
                            await performAccountDeletion()
                        }
                    }
                }
                .disabled(deleteConfirmationText != "DELETE")
            } message: {
                Text("Type DELETE (in all caps) to permanently delete your account.")
            }
            .overlay {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.8)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            
                            Text("Deleting account...")
                                .foregroundColor(.textPrimary)
                                .font(.body)
                        }
                    }
                }
            }
        }
    }
    
    private func performAccountDeletion() async {
        isDeletingAccount = true
        deleteError = nil
        
        do {
            try await authManager.deleteAccount()
            dismiss()
        } catch {
            deleteError = "Failed to delete account: \(error.localizedDescription)"
            isDeletingAccount = false
        }
        
        deleteConfirmationText = ""
    }
}

// MARK: - Supporting Components

struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.titleSmall)
            .foregroundColor(.textPrimary)
    }
}

struct SettingsTextField: View {
    let label: String
    @Binding var value: String
    var prefix: String? = nil
    var keyboardType: UIKeyboardType = .default
    var disableAutocorrection: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 8) {
                if let prefix = prefix {
                    Text(prefix)
                        .foregroundColor(.textTertiary)
                }
                
                TextField("", text: $value)
                    .foregroundColor(.textPrimary)
                    .keyboardType(keyboardType)
                    .autocapitalization(disableAutocorrection ? .none : .sentences)
                    .autocorrectionDisabled(disableAutocorrection)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surfaceBackground)
            .cornerRadius(12)
        }
    }
}

struct SettingsTextEditor: View {
    let label: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            ZStack(alignment: .topLeading) {
                if value.isEmpty {
                    Text("Enter \(label.lowercased())...")
                        .foregroundColor(.textTertiary)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $value)
                    .foregroundColor(.textPrimary)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(height: 100)
            .background(Color.surfaceBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
