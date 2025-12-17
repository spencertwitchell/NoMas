//
//  PledgeManager.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  PledgeManager.swift
//  NoMas
//
//  Manages daily pledge state
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PledgeManager: ObservableObject {
    static let shared = PledgeManager()
    
    private let lastPledgeDateKey = "lastPledgeDate"
    
    @Published var isPledgedToday: Bool = false
    @Published var lastPledgeDate: Date?
    
    private init() {
        loadPledgeState()
    }
    
    // MARK: - Load State
    
    private func loadPledgeState() {
        if let savedDate = UserDefaults.standard.object(forKey: lastPledgeDateKey) as? Date {
            lastPledgeDate = savedDate
            isPledgedToday = !hasExpired(savedDate)
        } else {
            isPledgedToday = false
            lastPledgeDate = nil
        }
    }
    
    // MARK: - Check Expiration
    
    private func hasExpired(_ date: Date) -> Bool {
        let hoursSincePledge = Date().timeIntervalSince(date) / 3600
        return hoursSincePledge >= 24
    }
    
    // MARK: - Time Remaining
    
    var timeRemainingString: String? {
        guard let pledgeDate = lastPledgeDate, isPledgedToday else { return nil }
        
        let expirationDate = pledgeDate.addingTimeInterval(24 * 3600)
        let remaining = expirationDate.timeIntervalSince(Date())
        
        if remaining <= 0 {
            return nil
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    // MARK: - Make Pledge
    
    func makePledge() {
        let now = Date()
        lastPledgeDate = now
        isPledgedToday = true
        UserDefaults.standard.set(now, forKey: lastPledgeDateKey)
        
        print("✅ Pledge made at \(now)")
    }
    
    // MARK: - Refresh State
    
    func refreshState() {
        loadPledgeState()
    }
}
