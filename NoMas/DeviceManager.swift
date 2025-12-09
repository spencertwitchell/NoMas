//
//  DeviceManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//


import Foundation
import UIKit
import Combine

// MARK: - Device Manager

/// Manages a unique device identifier for anonymous user tracking.
/// This ID persists across app launches but NOT across app reinstalls.
/// For more persistence, we also store in Keychain as backup.
@MainActor
class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    
    private let userDefaultsKey = "device_uuid"
    private let keychainService = "com.twitchapps.NoMas.device"
    private let keychainAccount = "device_uuid"
    
    @Published private(set) var deviceId: String
    
    private init() {
        // Try to load existing device ID, or create new one
        self.deviceId = Self.loadOrCreateDeviceId(
            userDefaultsKey: userDefaultsKey,
            keychainService: keychainService,
            keychainAccount: keychainAccount
        )
    }
    
    // MARK: - Load or Create Device ID
    
    private static func loadOrCreateDeviceId(
        userDefaultsKey: String,
        keychainService: String,
        keychainAccount: String
    ) -> String {
        // 1. Try UserDefaults first (fastest)
        if let storedId = UserDefaults.standard.string(forKey: userDefaultsKey), !storedId.isEmpty {
            print("📱 Device ID loaded from UserDefaults: \(storedId.prefix(8))...")
            return storedId
        }
        
        // 2. Try Keychain (survives app deletion on some iOS versions)
        if let keychainId = loadFromKeychain(service: keychainService, account: keychainAccount) {
            print("📱 Device ID restored from Keychain: \(keychainId.prefix(8))...")
            // Re-save to UserDefaults
            UserDefaults.standard.set(keychainId, forKey: userDefaultsKey)
            return keychainId
        }
        
        // 3. Generate new ID
        let newId = UUID().uuidString
        print("📱 Generated new Device ID: \(newId.prefix(8))...")
        
        // Save to both locations
        UserDefaults.standard.set(newId, forKey: userDefaultsKey)
        saveToKeychain(service: keychainService, account: keychainAccount, value: newId)
        
        return newId
    }
    
    // MARK: - Keychain Operations
    
    private static func saveToKeychain(service: String, account: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status == errSecSuccess {
            print("📱 Device ID saved to Keychain")
        } else {
            print("⚠️ Failed to save to Keychain: \(status)")
        }
    }
    
    private static func loadFromKeychain(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // MARK: - Reset (for testing/debugging)
    
    #if DEBUG
    func resetDeviceId() {
        let newId = UUID().uuidString
        
        // Update UserDefaults
        UserDefaults.standard.set(newId, forKey: userDefaultsKey)
        
        // Update Keychain
        Self.saveToKeychain(service: keychainService, account: keychainAccount, value: newId)
        
        // Update published property
        self.deviceId = newId
        
        print("📱 Device ID reset to: \(newId.prefix(8))...")
    }
    #endif
}
