import Foundation
import UIKit
import Supabase

final class PhotoStorageService {
    static let shared = PhotoStorageService()
    
    private let supabase = SupabaseManager.shared.client
    private let bucketName = "user-photos"
    
    private init() {}
    
    
    func uploadUserPhoto(_ image: UIImage, userId: String) async throws -> String {
        print("Starting photo upload for user: \(userId)")
        
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data")
            throw PhotoError.imageConversionFailed
        }
        
        print("Image converted to data, size: \(imageData.count) bytes")
        
        // Create filename
        let filename = "\(userId)/profile.jpg"
        print("Uploading to filename: \(filename)")
        
        do {
            // Upload to Supabase Storage
            print("Uploading to Supabase Storage...")
            try await supabase.storage
                .from(bucketName)
                .upload(filename, data: imageData)
            
            print("Upload successful, getting public URL...")
            
            // Return the public URL
            let publicURL = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: filename)
            
            print("Successfully uploaded photo for user \(userId), URL: \(publicURL.absoluteString)")
            
            // Update user profile with image URL
            try await updateUserProfileImageUrl(userId: userId, imageUrl: publicURL.absoluteString)
            
            return publicURL.absoluteString
        } catch {
            print("Failed to upload photo for user \(userId): \(error)")
            print("Error details: \(error.localizedDescription)")
            throw PhotoError.uploadFailed
        }
    }
    
    func downloadUserPhoto(userId: String) async throws -> UIImage? {
        let filename = "\(userId)/profile.jpg"
        
        do {
            let data = try await supabase.storage
                .from(bucketName)
                .download(path: filename)
            
            return UIImage(data: data)
        } catch {
            // Photo doesn't exist or failed to download
            print("Failed to download photo for user \(userId): \(error)")
            return nil
        }
    }
    
    func deleteUserPhoto(userId: String) async throws {
        let filename = "\(userId)/profile.jpg"
        
        try await supabase.storage
            .from(bucketName)
            .remove(paths: [filename])
    }
    
    private func updateUserProfileImageUrl(userId: String, imageUrl: String) async throws {
        try await supabase
            .from("user_profiles")
            .update(["profile_image_url": imageUrl, "updated_at": "now()"])
            .eq("id", value: userId)
            .execute()
    }
}

enum PhotoError: LocalizedError {
    case imageConversionFailed
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image"
        case .uploadFailed:
            return "Failed to upload photo"
        case .downloadFailed:
            return "Failed to download photo"
        }
    }
}
