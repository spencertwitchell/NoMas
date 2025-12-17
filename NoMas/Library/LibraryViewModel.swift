//
//  LibraryViewModel.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/16/25.
//


//
//  LibraryViewModel.swift
//  NoMas
//
//  ViewModel for fetching and managing library content from Supabase
//

import Foundation
import Supabase
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    @Published var articlesByCategory: [String: [Article]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var hasLoadedData = false
    
    func fetchData() async {
        // Only fetch if we haven't loaded data yet
        guard !hasLoadedData else { return }
        
        isLoading = true
        errorMessage = nil
        
        print("📚 Starting to fetch library data from Supabase...")
        
        do {
            // Fetch categories
            print("📂 Fetching categories...")
            let categoriesData: [Category] = try await supabase
                .from("categories")
                .select()
                .order("sort")
                .execute()
                .value
            
            print("✅ Categories fetched: \(categoriesData.count)")
            
            // Fetch articles
            print("📄 Fetching articles...")
            let articlesData: [Article] = try await supabase
                .from("articles")
                .select()
                .order("sort")
                .execute()
                .value
            
            print("✅ Articles fetched: \(articlesData.count)")
            
            // Group articles by category
            var grouped: [String: [Article]] = [:]
            for article in articlesData {
                if grouped[article.categoryId] == nil {
                    grouped[article.categoryId] = []
                }
                grouped[article.categoryId]?.append(article)
            }
            
            self.categories = categoriesData
            self.articlesByCategory = grouped
            self.hasLoadedData = true
            
            print("✅ Library data loading complete!")
            
            // Preload images in background
            Task {
                await ImageCacheManager.shared.preloadArticleImages(articles: articlesData)
            }
            
        } catch {
            print("❌ Error fetching library data: \(error)")
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Force refresh data
    func refreshData() async {
        hasLoadedData = false
        await fetchData()
    }
}