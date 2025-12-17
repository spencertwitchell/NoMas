//
//  RelaxationSound.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/16/25.
//


//
//  RelaxationSound.swift
//  NoMas
//
//  Model for relaxation/meditation sounds
//

import Foundation

struct RelaxationSound: Identifiable, Codable {
    let id: String
    let name: String
    let coverImageUrl: String
    let audioUrl: String
    let sort: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coverImageUrl = "cover_image_url"
        case audioUrl = "audio_url"
        case sort
    }
    
    // MARK: - Hardcoded fallback (optional - remove once DB is set up)
    
    static let supabaseURL = "https://YOUR_PROJECT_ID.supabase.co/storage/v1/object/public/relaxation-sounds"
    
    static let fallbackSounds: [RelaxationSound] = [
        RelaxationSound(
            id: "1",
            name: "777hz Euphoria",
            coverImageUrl: "\(supabaseURL)/covers/777hz%20Euphoria.jpg",
            audioUrl: "\(supabaseURL)/777hz%20Euphoria.mp3",
            sort: 1
        ),
        RelaxationSound(
            id: "2",
            name: "Calming Campfire",
            coverImageUrl: "\(supabaseURL)/covers/Calming%20Campfire.jpg",
            audioUrl: "\(supabaseURL)/Calming%20Campfire.mp3",
            sort: 2
        ),
        RelaxationSound(
            id: "3",
            name: "Enchanted Forest",
            coverImageUrl: "\(supabaseURL)/covers/Enchanted%20Forest.jpg",
            audioUrl: "\(supabaseURL)/Enchanted%20Forest.mp3",
            sort: 3
        ),
        RelaxationSound(
            id: "4",
            name: "Flowing River",
            coverImageUrl: "\(supabaseURL)/covers/Flowing%20River.jpg",
            audioUrl: "\(supabaseURL)/Flowing%20River.mp3",
            sort: 4
        ),
        RelaxationSound(
            id: "5",
            name: "Peaceful Night",
            coverImageUrl: "\(supabaseURL)/covers/Peaceful%20Night.jpg",
            audioUrl: "\(supabaseURL)/Peaceful%20Night.mp3",
            sort: 5
        ),
        RelaxationSound(
            id: "6",
            name: "Relaxing Rainfall",
            coverImageUrl: "\(supabaseURL)/covers/Relaxing%20Rainfall.jpg",
            audioUrl: "\(supabaseURL)/Relaxing%20Rainfall.mp3",
            sort: 6
        ),
        RelaxationSound(
            id: "7",
            name: "Tropical Waves",
            coverImageUrl: "\(supabaseURL)/covers/Tropical%20Waves.jpg",
            audioUrl: "\(supabaseURL)/Tropical%20Waves.mp3",
            sort: 7
        )
    ]
}