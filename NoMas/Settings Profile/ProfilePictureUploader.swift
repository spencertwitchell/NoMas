//
//  ProfilePictureUploader.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/11/25.
//


//
//  ProfilePictureUploader.swift
//  NoMas
//
//  Handles profile picture upload and database sync
//

import SwiftUI
import PhotosUI
import Supabase
import Combine

@MainActor
class ProfilePictureUploader: ObservableObject {
    @Published var isUploading = false
    @Published var uploadError: String?
    
    private let database = DatabaseService.shared
    
    /// Upload a profile picture for the current user
    func uploadProfilePicture(from item: PhotosPickerItem) async -> Bool {
        guard let userId = UserData.shared.supabaseUserId else {
            print("❌ No user ID found")
            uploadError = "User not authenticated"
            return false
        }
        
        print("🔵 === STARTING PROFILE PICTURE UPLOAD ===")
        print("🔵 User ID: \(userId.uuidString)")
        print("🔵 Current profile URL: \(UserData.shared.profilePictureURL ?? "nil")")
        
        isUploading = true
        uploadError = nil
        
        do {
            // 1. Load the image data from PhotosPicker
            print("🔵 Step 1: Loading image data...")
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                print("❌ Failed to load image data")
                uploadError = "Failed to load image"
                isUploading = false
                return false
            }
            print("✅ Step 1: Image data loaded (\(imageData.count / 1024) KB)")
            
            // 2. Convert to UIImage and resize
            print("🔵 Step 2: Converting to UIImage...")
            guard let uiImage = UIImage(data: imageData) else {
                print("❌ Failed to create UIImage")
                uploadError = "Invalid image format"
                isUploading = false
                return false
            }
            print("✅ Step 2: UIImage created (size: \(uiImage.size))")
            
            // 3. Resize to 500x500 max
            print("🔵 Step 3: Resizing image...")
            let resizedImage = resizeImage(uiImage, maxSize: 500)
            print("✅ Step 3: Image resized (new size: \(resizedImage.size))")
            
            // 4. Convert to JPEG with compression
            print("🔵 Step 4: Converting to JPEG...")
            guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to convert to JPEG")
                uploadError = "Failed to process image"
                isUploading = false
                return false
            }
            print("✅ Step 4: JPEG created (\(jpegData.count / 1024) KB)")
            
            // 5. Delete old profile picture if it exists
            if let oldURL = UserData.shared.profilePictureURL, !oldURL.isEmpty {
                print("🔵 Step 5: Deleting old profile picture...")
                await deleteOldProfilePicture(url: oldURL, userId: userId)
            } else {
                print("🔵 Step 5: No old picture to delete")
            }
            
            // 6. Upload to Supabase Storage
            print("🔵 Step 6: Uploading to Supabase Storage...")
            let fileName = "\(userId.uuidString)/profile.jpg"
            print("🔵 File path: \(fileName)")
            
            let uploadResponse = try await supabase.storage
                .from("profile-pictures")
                .upload(
                    fileName,
                    data: jpegData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )
            
            print("✅ Step 6: Uploaded to storage")
            print("✅ Upload response: \(uploadResponse)")
            
            // 7. Get the public URL
            print("🔵 Step 7: Getting public URL...")
            let publicURL = try supabase.storage
                .from("profile-pictures")
                .getPublicURL(path: fileName)
            
            // 8. ADD CACHE-BUSTING TIMESTAMP
            let timestamp = Int(Date().timeIntervalSince1970)
            let cacheBustedURL = "\(publicURL.absoluteString)?v=\(timestamp)"
            
            print("✅ Step 7: Public URL obtained")
            print("✅ Base URL: \(publicURL.absoluteString)")
            print("✅ Cache-busted URL: \(cacheBustedURL)")
            
            // 9. Update the database
            print("🔵 Step 8: Updating database...")
            try await database.updateProfilePicture(userId: userId, url: cacheBustedURL)
            print("✅ Step 8: Database updated successfully")
            
            // 10. Update local UserData so UI updates immediately
            print("🔵 Step 9: Updating local UserData...")
            print("🔵 Old local URL: \(UserData.shared.profilePictureURL ?? "nil")")
            UserData.shared.profilePictureURL = cacheBustedURL
            print("✅ New local URL: \(UserData.shared.profilePictureURL ?? "nil")")
            
            print("✅ === PROFILE PICTURE UPLOAD COMPLETE ===")
            isUploading = false
            return true
            
        } catch {
            print("❌ === UPLOAD FAILED ===")
            print("❌ Error: \(error)")
            print("❌ Error description: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error details: \(decodingError)")
            }
            uploadError = "Upload failed: \(error.localizedDescription)"
            isUploading = false
            return false
        }
    }
    
    /// Delete old profile picture from storage
    private func deleteOldProfilePicture(url: String, userId: UUID) async {
        do {
            let fileName = "\(userId.uuidString)/profile.jpg"
            try await supabase.storage
                .from("profile-pictures")
                .remove(paths: [fileName])
            print("✅ Deleted old profile picture")
        } catch {
            print("⚠️ Failed to delete old picture (may not exist): \(error)")
        }
    }
    
    /// Resize image to fit within maxSize while maintaining aspect ratio
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        // If image is already smaller, return as-is
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let ratio = size.width / size.height
        let newSize: CGSize
        
        if ratio > 1 {
            // Landscape
            newSize = CGSize(width: maxSize, height: maxSize / ratio)
        } else {
            // Portrait or square
            newSize = CGSize(width: maxSize * ratio, height: maxSize)
        }
        
        // Resize
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
}
