//
//  DailyCheckInView.swift
//  NoMas
//
//  Created by Claude on 1/7/26.
//

import SwiftUI

// MARK: - Feeling Type

enum CheckInFeeling: String, CaseIterable {
    case happy
    case neutral
    case down
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .neutral: return "😐"
        case .down: return "😔"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .happy:
            return LinearGradient(
                colors: [Color(hex: "34C759"), Color(hex: "30B350")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .neutral:
            return LinearGradient(
                colors: [Color(hex: "FFD60A"), Color(hex: "F5A623")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .down:
            return LinearGradient(
                colors: [Color(hex: "FF6B6B"), Color(hex: "EE5A5A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Daily Check In View

struct DailyCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    
    @State private var step: Int = 1
    @State private var selectedFeeling: CheckInFeeling? = nil
    @State private var isLoading: Bool = true
    
    // Stats from Supabase
    @State private var stillStrongCount: Int = 720
    @State private var happyCount: Int = 347
    @State private var neutralCount: Int = 233
    @State private var downCount: Int = 140
    
    // Callback to open reset timer flow
    var onOpenResetTimer: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)
            
            // Content with transition
            Group {
                switch step {
                case 1:
                    step1View
                case 2:
                    step2View
                case 3:
                    step3View
                default:
                    EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: step)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            GeometryReader { geometry in
                Image("bg1")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.4))
            }
            .ignoresSafeArea()
        }
        .task {
            await fetchStats()
        }
    }
    
    // MARK: - Step 1: Did You Relapse?
    
    private var step1View: some View {
        VStack(spacing: 24) {
            // Header
            Text("Did you relapse? 👀")
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            Text("Let the community know by checking in.")
                .font(.body)
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            // Big center number with purple glow
            VStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else {
                    Text("\(stillStrongCount)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .shadow(color: Color.accentGradientStart.opacity(0.6), radius: 30)
                        .shadow(color: Color.accentGradientStart.opacity(0.4), radius: 50)
                }
                
                Text("are still going strong")
                    .font(.body)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                // No, still going strong
                Button {
                    Task {
                        await incrementStillStrong()
                    }
                    withAnimation {
                        step = 2
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("No, still going strong")
                            .font(.titleSmall)
                            .fontWeight(.semibold)
                        Text("💪")
                            .font(.system(size: 20))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.accent)
                    .cornerRadius(12)
                }
                
                // Yes, I relapsed
                Button {
                    dismiss()
                    onOpenResetTimer()
                } label: {
                    HStack(spacing: 8) {
                        Text("Yes, I relapsed")
                            .font(.titleSmall)
                            .fontWeight(.semibold)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Step 2: How Are You Feeling?
    
    private var step2View: some View {
        VStack(spacing: 32) {
            // Header
            Text("And how are you feeling?")
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            // 3 Feeling buttons
            VStack(spacing: 16) {
                ForEach(CheckInFeeling.allCases, id: \.self) { feeling in
                    Button {
                        selectedFeeling = feeling
                        withAnimation {
                            step = 3
                        }
                    } label: {
                        Text(feeling.emoji)
                            .font(.system(size: 48))
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(feeling.gradient)
                            .cornerRadius(20)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Step 3: Summary
    
    private var step3View: some View {
        VStack(spacing: 16) {
            // Header - reduced top spacing
            Text("NOMÁS believes in you...")
                .font(.titleMedium)
                .foregroundColor(.textPrimary)
                .padding(.top, 8)
            
            // Feeling tallies - centered
            VStack(spacing: 20) {
                feelingTallyRow(feeling: .happy, count: happyCount + (selectedFeeling == .happy ? 1 : 0))
                feelingTallyRow(feeling: .neutral, count: neutralCount + (selectedFeeling == .neutral ? 1 : 0))
                feelingTallyRow(feeling: .down, count: downCount + (selectedFeeling == .down ? 1 : 0))
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            
            // Caption
            Text("This journey is hard but you are not alone...")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                // Reflect
                Button {
                    Task {
                        await saveCheckInAndClose(openJournal: true)
                    }
                } label: {
                    Text("Reflect")
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.accent)
                        .cornerRadius(12)
                }
                
                // Finish - white gradient background with purple text
                Button {
                    Task {
                        await saveCheckInAndClose(openJournal: false)
                    }
                } label: {
                    Text("Finish")
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(LinearGradient.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Feeling Tally Row (Centered)
    
    private func feelingTallyRow(feeling: CheckInFeeling, count: Int) -> some View {
        HStack(spacing: 12) {
            Text(feeling.emoji)
                .font(.system(size: 36))
            
            Text("\(count) others")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Supabase Operations
    
    private func fetchStats() async {
        isLoading = true
        
        do {
            let stats = try await DatabaseService.shared.fetchDailyCheckInStats()
            stillStrongCount = stats.stillStrongCount
            happyCount = stats.happyCount
            neutralCount = stats.neutralCount
            downCount = stats.downCount
        } catch {
            print("❌ Failed to fetch check-in stats: \(error)")
            // Keep defaults on error
        }
        
        isLoading = false
    }
    
    private func incrementStillStrong() async {
        do {
            try await DatabaseService.shared.incrementStillStrongCount()
        } catch {
            print("❌ Failed to increment still strong count: \(error)")
        }
    }
    
    private func saveCheckInAndClose(openJournal: Bool) async {
        // Increment the feeling count
        if let feeling = selectedFeeling {
            do {
                try await DatabaseService.shared.incrementFeelingCount(feeling: feeling)
            } catch {
                print("❌ Failed to increment feeling count: \(error)")
            }
        }
        
        // Mark check-in as complete
        await MainActor.run {
            UserData.shared.lastCheckInDate = Date()
            
            if openJournal {
                UserData.shared.shouldOpenReflectionJournal = true
                selectedTab = 2 // Switch to Library tab
            }
            
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Step 1") {
    DailyCheckInView(selectedTab: .constant(0), onOpenResetTimer: {})
}
