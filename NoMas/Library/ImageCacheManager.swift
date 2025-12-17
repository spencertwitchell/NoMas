//
//  ImageCacheManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/16/25.
//


//
//  ImageCacheManager.swift
//  NoMas
//
//  Image caching and preloading manager for hero images
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    private let cache: URLCache
    private let fileManager = FileManager.default
    
    @Published var preloadProgress: Double = 0.0
    @Published var isPreloading = false
    
    private init() {
        // Configure a larger persistent cache (50MB memory, 200MB disk)
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        cache = URLCache(
            memoryCapacity: 50 * 1024 * 1024,  // 50 MB memory
            diskCapacity: 200 * 1024 * 1024,   // 200 MB disk
            directory: cacheDirectory
        )
        
        URLCache.shared = cache
    }
    
    /// Preload all article hero images in the background
    func preloadArticleImages(articles: [Article]) async {
        guard !articles.isEmpty else { return }
        
        isPreloading = true
        preloadProgress = 0.0
        
        let imageUrls = articles.map { $0.heroImageUrl }
        let totalImages = Double(imageUrls.count)
        var loadedCount = 0.0
        
        // Download images concurrently with a limit
        await withTaskGroup(of: Void.self) { group in
            for (index, imageUrl) in imageUrls.enumerated() {
                group.addTask {
                    await self.downloadAndCacheImage(urlString: imageUrl)
                    
                    await MainActor.run {
                        loadedCount += 1
                        self.preloadProgress = loadedCount / totalImages
                    }
                }
                
                // Limit concurrent downloads to avoid overwhelming the network
                if index % 5 == 0 && index > 0 {
                    await group.next()
                }
            }
        }
        
        isPreloading = false
        print("✅ Preloaded \(Int(loadedCount)) article images")
    }
    
    /// Download and cache a single image
    private func downloadAndCacheImage(urlString: String) async {
        guard let url = URL(string: urlString) else { return }
        
        // Check if already cached
        let request = URLRequest(url: url)
        if cache.cachedResponse(for: request) != nil {
            return // Already cached
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Store in cache
            let cachedResponse = CachedURLResponse(response: response, data: data)
            cache.storeCachedResponse(cachedResponse, for: request)
            
        } catch {
            print("⚠️ Failed to cache image: \(url.lastPathComponent)")
        }
    }
    
    /// Check if an image is already cached
    func isImageCached(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let request = URLRequest(url: url)
        return cache.cachedResponse(for: request) != nil
    }
    
    /// Clear all cached images
    func clearCache() {
        cache.removeAllCachedResponses()
        print("🗑️ Image cache cleared")
    }
    
    /// Get cache statistics
    func getCacheStats() -> (memoryUsage: Int, diskUsage: Int) {
        return (cache.currentMemoryUsage, cache.currentDiskUsage)
    }
}