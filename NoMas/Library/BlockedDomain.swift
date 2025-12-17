//
//  BlockedDomain.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  BlockedDomain.swift
//  NoMas
//
//  Model for blocked domains from Supabase
//

import Foundation

struct BlockedDomain: Codable, Identifiable {
    let id: String
    let domain: String
    let category: String?
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case domain
        case category
        case isActive = "is_active"
    }
}