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
    
    // In-memory UIImage cache for faster display (avoids re-decoding from data)
    private var imageCache = NSCache<NSString, UIImage>()
    
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
        
        // Configure in-memory image cache
        imageCache.countLimit = 100 // Max 100 images in memory
        imageCache.totalCostLimit = 50 * 1024 * 1024 // ~50MB
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
        
        let cacheKey = urlString as NSString
        
        // Check if already in memory cache
        if imageCache.object(forKey: cacheKey) != nil {
            return
        }
        
        // Check if already in URL cache
        let request = URLRequest(url: url)
        if let cachedResponse = cache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            // Add to memory cache for faster access
            imageCache.setObject(image, forKey: cacheKey)
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Store in URL cache (disk)
            let cachedResponse = CachedURLResponse(response: response, data: data)
            cache.storeCachedResponse(cachedResponse, for: request)
            
            // Store in memory cache
            if let image = UIImage(data: data) {
                imageCache.setObject(image, forKey: cacheKey)
            }
            
        } catch {
            print("⚠️ Failed to cache image: \(url.lastPathComponent)")
        }
    }
    
    /// Get cached image if available (checks memory first, then disk)
    func getCachedImage(urlString: String) -> UIImage? {
        let cacheKey = urlString as NSString
        
        // Check memory cache first (fastest)
        if let image = imageCache.object(forKey: cacheKey) {
            return image
        }
        
        // Check URL cache (disk)
        guard let url = URL(string: urlString) else { return nil }
        let request = URLRequest(url: url)
        
        if let cachedResponse = cache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            // Promote to memory cache for next time
            imageCache.setObject(image, forKey: cacheKey)
            return image
        }
        
        return nil
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
        imageCache.removeAllObjects()
        print("🗑️ Image cache cleared")
    }
    
    /// Get cache statistics
    func getCacheStats() -> (memoryUsage: Int, diskUsage: Int) {
        return (cache.currentMemoryUsage, cache.currentDiskUsage)
    }
}

// MARK: - CachedAsyncImage View

/// A replacement for AsyncImage that uses ImageCacheManager's cache
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var loadedImage: UIImage?
    @State private var isLoading = false
    
    init(
        urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        // Check cache first (synchronous, fast)
        if let cached = ImageCacheManager.shared.getCachedImage(urlString: urlString) {
            loadedImage = cached
            return
        }
        
        // Not cached, need to download
        guard !isLoading else { return }
        isLoading = true
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Cache the response
                let request = URLRequest(url: url)
                let cachedResponse = CachedURLResponse(response: response, data: data)
                URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        loadedImage = image
                    }
                }
            } catch {
                print("⚠️ Failed to load image: \(url.lastPathComponent)")
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Convenience initializer matching AsyncImage API

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    init(urlString: String) {
        self.urlString = urlString
        self.content = { $0 }
        self.placeholder = { ProgressView() }
    }
}
