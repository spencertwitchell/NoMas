//
//  TimerView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie
import Combine

// MARK: - Timer View

struct TimerView: View {
    @Binding var selectedTab: Int
    @StateObject private var userData = UserData.shared
    
    @State private var showingMightBreak = false
    @State private var showingResetTimer = false
    @State private var showingPanicButton = false
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Animated Flame
                    AnimatedFlameView()
                        .frame(height: 180)
                        .padding(.top, 12)
                    
                    // Timer Display
                    TimerDisplayView(userData: userData, currentTime: currentTime)
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(
                            icon: "exclamationmark.triangle.fill",
                            title: "I Might Break",
                            action: { showingMightBreak = true }
                        )
                        
                        ActionButton(
                            icon: "arrow.counterclockwise",
                            title: "Reset Timer",
                            action: { showingResetTimer = true }
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Analytics Section
                    AnalyticsSection(userData: userData)
                        .padding(.horizontal, 20)
                    
                    // Recovery Progress Section
                    RecoveryProgressSection(userData: userData)
                        .padding(.horizontal, 20)
                    
                    // Current Milestone Card
                    CurrentMilestoneCard(userData: userData)
                        .padding(.horizontal, 20)
                    
                    // Extra space for floating button
                    Spacer()
                        .frame(height: 100)
                }
            }
            
            // Floating PANIC BUTTON
            VStack {
                Spacer()
                PanicButtonView(action: {
                    showingPanicButton = true
                })
                .padding(.bottom, 12)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            // Update best streak in real-time if current exceeds it
            userData.updateBestStreakIfNeeded()
        }
        .fullScreenCover(isPresented: $showingMightBreak) {
            MightBreakFlowView()
        }
        .fullScreenCover(isPresented: $showingResetTimer) {
            ResetTimerFlowView(selectedTab: $selectedTab)
        }
        .fullScreenCover(isPresented: $showingPanicButton) {
            PanicButtonFlowView()
        }
    }
}

// MARK: - Animated Flame View

struct AnimatedFlameView: View {
    @StateObject private var userData = UserData.shared
    
    var body: some View {
        LottieView(animation: .named(animationName))
            .playing(loopMode: .loop)
            .animationSpeed(0.67)
            .frame(height: 180)
            .scaleEffect(2.0)
            .shadow(color: Color.accentGradientStart.opacity(0.5), radius: 20)
    }
    
    var animationName: String {
        switch userData.currentMilestone {
        case .bronze: return "Heart_Blue"      // Placeholder - update with actual animation
        case .silver: return "Heart_Blue"      // Placeholder
        case .gold: return "Heart_Blue"        // Placeholder
        case .platinum: return "Heart_Blue"    // Placeholder
        case .diamond: return "Heart_Blue"     // Placeholder
        case .ruby: return "Heart_Blue"        // Placeholder
        case .elite: return "Heart_Blue"       // Placeholder
        case .master: return "Heart_Blue"      // Placeholder
        case .grandmaster: return "Heart_Blue" // Placeholder
        }
    }
}

// MARK: - Timer Display View

struct TimerDisplayView: View {
    @ObservedObject var userData: UserData
    let currentTime: Date
    
    private var displayName: String {
        userData.displayName.isEmpty ? "Hey there" : userData.displayName
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(displayName), you've been clean for:")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            Text("\(timeComponents.days) days")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.textPrimary)
                .padding(.bottom, 8)
            
            HStack(spacing: 8) {
                Text("+")
                Text("\(timeComponents.hours) hours")
                Text("|")
                Text("\(timeComponents.minutes) minutes")
                Text("|")
                Text("\(timeComponents.seconds) seconds")
            }
            .font(.bodySmall)
            .foregroundColor(.textPrimary)
            .opacity(0.8)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                LinearGradient.accent
                    .opacity(0.3)
            )
            .cornerRadius(20)
        }
    }
    
    var timeComponents: (days: Int, hours: Int, minutes: Int, seconds: Int) {
        let interval = currentTime.timeIntervalSince(userData.streakStartDate)
        let totalSeconds = max(Int(interval), 0)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        return (days, hours, minutes, seconds)
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.button)
            }
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(LinearGradient.accent)
            .cornerRadius(12)
        }
    }
}

// MARK: - Analytics Section

struct AnalyticsSection: View {
    @ObservedObject var userData: UserData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analytics")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                AnalyticCard(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(userData.timesRelapsed)",
                    unit: userData.timesRelapsed == 1 ? "time" : "times",
                    label: "Relapsed"
                )
                AnalyticCard(
                    icon: "flame.fill",
                    value: "\(userData.daysSinceRelapse)",
                    unit: userData.daysSinceRelapse == 1 ? "day" : "days",
                    label: "Current Streak"
                )
                AnalyticCard(
                    icon: "trophy.fill",
                    value: "\(userData.effectiveBestStreak)",
                    unit: userData.effectiveBestStreak == 1 ? "day" : "days",
                    label: "Best Streak"
                )
            }
        }
    }
}

struct AnalyticCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentGradientEnd)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.titleMedium)
                    .foregroundColor(.textPrimary)
                
                Text(unit)
                    .font(.bodySmall)
                    .foregroundColor(.textPrimary)
            }
            
            Text(label)
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient.accent
                .opacity(0.3)
        )
        .cornerRadius(12)
    }
}

// MARK: - Recovery Progress Section

struct RecoveryProgressSection: View {
    @ObservedObject var userData: UserData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You'll be fully recovered by:")
                .font(.bodySmall)
                .foregroundColor(.textSecondary)
            
            Text(formattedRecoveryDate)
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progressFormatted)
                        .font(.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(daysRemaining) days left")
                        .font(.captionSmall)
                        .foregroundColor(.textTertiary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.textPrimary.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(LinearGradient.accent)
                            .frame(width: geometry.size.width * CGFloat(progressPercentage), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            LinearGradient.accent
                .opacity(0.3)
        )
        .cornerRadius(12)
    }
    
    var formattedRecoveryDate: String {
        guard let date = userData.projectedRecoveryDate else {
            return "Calculating..."
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    var daysRemaining: Int {
        guard let date = userData.projectedRecoveryDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return max(days, 0)
    }
    
    var progressPercentage: Double {
        guard userData.totalRecoveryDays > 0 else { return 0 }
        let progress = Double(userData.daysSinceRelapse) / Double(userData.totalRecoveryDays)
        return min(max(progress, 0), 1)
    }
    
    var progressFormatted: String {
        let percentage = Int(progressPercentage * 100)
        return "\(percentage)% Complete"
    }
}

// MARK: - Current Milestone Card

struct CurrentMilestoneCard: View {
    @ObservedObject var userData: UserData
    
    private var milestone: Milestone {
        userData.currentMilestone
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Milestone")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("Day \(milestone.daysRequired)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 16) {
                // Milestone Icon (placeholder for Lottie)
                ZStack {
                    Circle()
                        .fill(milestone.gradient.opacity(0.8))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: milestone.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                
                // Milestone Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.displayName)
                        .font(.titleSmall)
                        .foregroundColor(.white)
                    
                    Text(milestone.title)
                        .font(.bodySmall)
                        .foregroundColor(.white.opacity(0.9))
                    
                    if let next = milestone.next {
                        Text("\(next.daysRequired - userData.daysSinceRelapse) days until \(next.displayName)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("You've reached the final milestone!")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
            }
            
            // Milestone Description
            Text(milestone.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            ZStack {
                // Gradient layer
                RoundedRectangle(cornerRadius: 16)
                    .fill(milestone.gradient)
                
                // Dark overlay for readability (same as "current" state in MilestoneRow)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.35))
            }
        )
        .overlay(
            // 3pt gradient border
            RoundedRectangle(cornerRadius: 16)
                .stroke(milestone.gradient, lineWidth: 3)
        )
        .cornerRadius(16)
        // Glow effect
        .shadow(
            color: milestone.gradientColors.first?.opacity(0.5) ?? .clear,
            radius: 12,
            x: 0,
            y: 0
        )
    }
}

// MARK: - Panic Button View

struct PanicButtonView: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("PANIC BUTTON")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(30)
            .shadow(color: Color.red.opacity(0.5), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppBackground()
        TimerView(selectedTab: .constant(0))
    }
}
