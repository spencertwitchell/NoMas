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
    
    // Dark overlay opacity - uniform dark overlay with varying opacity
    private var overlayOpacity: Double {
        if isCurrent { return 0.35 }
        if isUnlocked { return 0.55 }
        return 0.75 // locked - darkest overlay
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Icon placeholder (will be Lottie)
                ZStack {
                    Circle()
                        .fill(milestone.gradient.opacity(isUnlocked ? 0.8 : 0.3))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: milestone.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(isUnlocked ? 1.0 : 0.5))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(milestone.displayName)
                            .font(.titleSmall)
                            .foregroundColor(.white)
                        
                        if isCurrent {
                            Text("Current")
                                .font(.captionSmall)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.25))
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(milestone.title)
                        .font(.bodySmall)
                        .foregroundColor(.white.opacity(isUnlocked ? 0.9 : 0.6))
                    
                    Text("Day \(milestone.daysRequired)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Status
                if isUnlocked && !isCurrent {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 16))
                }
            }
            
            // Description
            Text(milestone.description)
                .font(.caption)
                .foregroundColor(.white.opacity(isUnlocked ? 0.85 : 0.5))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            MilestoneCardBackground(
                milestone: milestone,
                overlayOpacity: overlayOpacity,
                isCurrent: isCurrent
            )
        )
        .overlay(
            // 3pt gradient border for current milestone only
            RoundedRectangle(cornerRadius: 16)
                .stroke(milestone.gradient, lineWidth: isCurrent ? 3 : 0)
        )
        // Glow effect for current milestone
        .shadow(
            color: isCurrent ? milestone.gradientColors.first?.opacity(0.5) ?? .clear : .clear,
            radius: isCurrent ? 12 : 0,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Milestone Card Background

struct MilestoneCardBackground: View {
    let milestone: Milestone
    let overlayOpacity: Double
    let isCurrent: Bool
    
    var body: some View {
        ZStack {
            // Gradient layer (full opacity)
            RoundedRectangle(cornerRadius: 16)
                .fill(milestone.gradient)
            
            // Dark overlay for readability (varying opacity based on state)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(overlayOpacity))
        }
    }
}

// MARK: - Preview

#Preview("Milestones Sheet") {
    MilestonesSheetView()
}

#Preview("Milestone Row - Current") {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            MilestoneRow(milestone: .bronze, isUnlocked: true, isCurrent: true)
            MilestoneRow(milestone: .gold, isUnlocked: true, isCurrent: true)
            MilestoneRow(milestone: .grandmaster, isUnlocked: true, isCurrent: true)
        }
        .padding()
    }
}

#Preview("Milestone Row - States") {
    ZStack {
        AppBackground()
        VStack(spacing: 16) {
            MilestoneRow(milestone: .silver, isUnlocked: true, isCurrent: false) // passed
            MilestoneRow(milestone: .gold, isUnlocked: true, isCurrent: true) // current
            MilestoneRow(milestone: .platinum, isUnlocked: false, isCurrent: false) // locked
        }
        .padding()
    }
}
