//
//  MilestonesSheetView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/12/25.
//


//
//  MilestonesSheetView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI

// MARK: - Milestones Sheet View

struct MilestonesSheetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userData = UserData.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header info
                        VStack(spacing: 8) {
                            Text("Your Progress")
                                .font(.titleMedium)
                                .foregroundColor(.textPrimary)
                            
                            Text("\(userData.daysSinceRelapse) days clean")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                            
                            if let projectedDate = userData.projectedRecoveryDate {
                                Text("Projected recovery: \(projectedDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Milestone list
                        ForEach(Milestone.allCases, id: \.self) { milestone in
                            MilestoneRow(
                                milestone: milestone,
                                isUnlocked: userData.daysSinceRelapse >= milestone.daysRequired,
                                isCurrent: userData.currentMilestone == milestone
                            )
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Milestones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentGradientStart)
                }
            }
        }
    }
}

// MARK: - Milestone Row

struct MilestoneRow: View {
    let milestone: Milestone
    let isUnlocked: Bool
    let isCurrent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isUnlocked ? milestone.color : Color.surfaceBackground)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: milestone.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(isUnlocked ? .white : .textTertiary)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(milestone.displayName)
                            .font(.titleSmall)
                            .foregroundColor(isUnlocked ? .textPrimary : .textTertiary)
                        
                        if isCurrent {
                            Text("Current")
                                .font(.captionSmall)
                                .foregroundColor(.accentGradientStart)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentGradientStart.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(milestone.title)
                        .font(.bodySmall)
                        .foregroundColor(isUnlocked ? .textSecondary : .textTertiary)
                    
                    Text("Day \(milestone.daysRequired)")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
                
                Spacer()
                
                // Status
                if isUnlocked && !isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.textTertiary)
                        .font(.system(size: 16))
                }
            }
            
            // Description
            Text(milestone.description)
                .font(.caption)
                .foregroundColor(isUnlocked ? .textSecondary : .textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(isCurrent ? Color.accentGradientStart.opacity(0.1) : Color.surfaceBackground)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview {
    MilestonesSheetView()
}
