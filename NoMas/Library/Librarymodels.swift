//
//  LibraryModels.swift
//  NoMas
//
//  Models for Library categories and articles from Supabase
//

import Foundation

// MARK: - Category

struct Category: Codable, Identifiable {
    let id: String
    let title: String
    let sort: Int
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case sort
        case createdAt = "created_at"
    }
}

// MARK: - Article

struct Article: Codable, Identifiable {
    let id: String
    let categoryId: String
    let title: String
    let heroImageUrl: String
    let bodyMd: String  // URL to markdown file in Supabase Storage
    let sort: Int
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case categoryId = "category_id"
        case title
        case heroImageUrl = "hero_image_url"
        case bodyMd = "body_md"
        case sort
        case createdAt = "created_at"
    }
}
