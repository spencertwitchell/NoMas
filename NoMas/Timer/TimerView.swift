//
//  TimerView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/8/25.
//

import SwiftUI
import Lottie
import Combine
import UserNotifications

// MARK: - Timer View

struct TimerView: View {
    @Binding var selectedTab: Int
    @StateObject private var userData = UserData.shared
    @StateObject private var remindersManager = RemindersManager.shared
    @StateObject private var pledgeManager = PledgeManager.shared
    @StateObject private var quoteManager = MotivationalQuoteManager.shared
    
    @State private var showingMightBreak = false
    @State private var showingResetTimer = false
    @State private var showingPanicButton = false
    @State private var showingReminders = false
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Motivational Quote Box
                    MotivationalQuoteBox(quote: quoteManager.currentQuote)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // Animated Flame
                    AnimatedFlameView()
                        .frame(height: 180)
                    
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
                    
                    // Remind Yourself Why Section (NEW)
                    RemindYourselfWhySection(
                        remindersManager: remindersManager,
                        showingReminders: $showingReminders
                    )
                    .padding(.horizontal, 20)
                    
                    // To-Do Section (NEW)
                    ToDoSection(
                        userData: userData,
                        selectedTab: $selectedTab,
                        pledgeManager: pledgeManager
                    )
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
        .task {
            // Fetch reminders on appear
            await remindersManager.fetchReminders()
            // Refresh quote if needed (checks 6-hour cache automatically)
            await quoteManager.refreshQuoteIfNeeded(for: userData.currentMilestone)
        }
        .onChange(of: userData.currentMilestone) { oldValue, newValue in
            // When milestone changes, fetch a new quote for the new milestone
            if oldValue != newValue {
                Task {
                    await quoteManager.forceRefresh(for: newValue)
                }
            }
        }
        .fullScreenCover(isPresented: $showingMightBreak) {
            MightBreakFlowView(selectedTab: $selectedTab)
        }
        .fullScreenCover(isPresented: $showingResetTimer) {
            ResetTimerFlowView(selectedTab: $selectedTab)
        }
        .fullScreenCover(isPresented: $showingPanicButton) {
            PanicButtonFlowView(selectedTab: $selectedTab)
        }
        .sheet(isPresented: $showingReminders) {
            RemindersManagementView(remindersManager: remindersManager)
        }
    }
}

// MARK: - Animated Flame View

struct AnimatedFlameView: View {
    @StateObject private var userData = UserData.shared
    
    var body: some View {
        LottieView(animation: .named(userData.currentMilestone.animationName))
            .playing(loopMode: .loop)
            .animationSpeed(0.67)
            .frame(height: 180)
            .scaleEffect(1.4)
            .shadow(color: Color.accentGradientStart.opacity(0.5), radius: 20)
    }
}

// MARK: - Motivational Quote Box

struct MotivationalQuoteBox: View {
    let quote: String
    
    var body: some View {
        Text(quote)
            .font(.bodySmall)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient.accent
                    .opacity(0.3)
            )
            .cornerRadius(12)
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
            
            Text("\(timeComponents.days) \(timeComponents.days == 1 ? "day" : "days")")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.textPrimary)
                .padding(.bottom, 8)
            
            HStack(spacing: 8) {
                Text("+")
                Text("\(timeComponents.hours) \(timeComponents.hours == 1 ? "hour" : "hours")")
                Text("|")
                Text("\(timeComponents.minutes) \(timeComponents.minutes == 1 ? "minute" : "minutes")")
                Text("|")
                Text("\(timeComponents.seconds) \(timeComponents.seconds == 1 ? "second" : "seconds")")
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
    
    private var iconColor: Color {
        userData.currentMilestone.gradientColors.first ?? .accentGradientEnd
    }
    
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
                    label: "Relapsed",
                    iconColor: iconColor
                )
                AnalyticCard(
                    icon: "flame.fill",
                    value: "\(userData.daysSinceRelapse)",
                    unit: userData.daysSinceRelapse == 1 ? "day" : "days",
                    label: "Current Streak",
                    iconColor: iconColor
                )
                AnalyticCard(
                    icon: "trophy.fill",
                    value: "\(userData.effectiveBestStreak)",
                    unit: userData.effectiveBestStreak == 1 ? "day" : "days",
                    label: "Best Streak",
                    iconColor: iconColor
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
    var iconColor: Color = .accentGradientEnd
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
            
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
                    
                    Text("\(daysRemaining) \(daysRemaining == 1 ? "day" : "days") left")
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
                        let daysUntil = next.daysRequired - userData.daysSinceRelapse
                        Text("\(daysUntil) \(daysUntil == 1 ? "day" : "days") until \(next.displayName)")
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

// MARK: - Remind Yourself Why Section

struct RemindYourselfWhySection: View {
    @ObservedObject var remindersManager: RemindersManager
    @Binding var showingReminders: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Remind Yourself Why")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
            
            Text("You chose to quit for a reason. When urges hit hard, remind yourself why you started:")
                .font(.captionSmall)
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
            
            if remindersManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.accentGradientStart)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(remindersManager.reminders.prefix(3)) { reminder in
                        Text(reminder.text)
                            .font(.bodySmall)
                            .foregroundColor(.textPrimary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(LinearGradient.accent.opacity(0.5))
                            .cornerRadius(8)
                    }
                }
            }
            
            Button(action: {
                showingReminders = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add / Edit")
                }
                .font(.captionSmall)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            }
        }
        .padding(16)
        .background(
            LinearGradient.accent
                .opacity(0.3)
        )
        .cornerRadius(12)
    }
}

// MARK: - To-Do Section

struct ToDoSection: View {
    let userData: UserData
    @Binding var selectedTab: Int
    @ObservedObject var pledgeManager: PledgeManager
    
    // State for checked items (persisted in UserDefaults)
    @AppStorage("todoNotificationsChecked") private var notificationsChecked = false
    @AppStorage("todoWebsiteBlockerChecked") private var websiteBlockerChecked = false
    @AppStorage("todoChatAIChecked") private var chatAIChecked = false
    @AppStorage("todoProfileChecked") private var profileChecked = false
    @AppStorage("todoCreatePostChecked") private var createPostChecked = false
    
    // Sheet states
    @State private var showingWebsiteBlocker = false
    @State private var showingProfile = false
    @State private var showingPledge = false
    @State private var showingCreatePost = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("To Do")
                .font(.titleSmall)
                .foregroundColor(.textPrimary)
            
            // Enable Notifications (checkbox NOT manually tappable - controlled by system)
            ToDoCard(
                title: "Enable Notifications",
                description: "Get timely check-ins, motivation, and quick interventions to catch urges before they spiral.",
                isChecked: $notificationsChecked,
                allowManualCheckbox: false,
                action: {
                    requestNotificationPermission()
                }
            )
            
            // Website Blocker (checkbox manually tappable)
            ToDoCard(
                title: "Website Blocker",
                description: "Block adult content across all browsers and apps to remove temptation and protect your recovery.",
                isChecked: $websiteBlockerChecked,
                allowManualCheckbox: true,
                action: {
                    showingWebsiteBlocker = true
                }
            )
            
            // Chat with AI (checkbox manually tappable)
            ToDoCard(
                title: "Chat with AI",
                description: "Talk to Nomi, your AI companion who understands your journey and can help when urges hit.",
                isChecked: $chatAIChecked,
                allowManualCheckbox: true,
                action: {
                    selectedTab = 1 // Navigate to Chat tab
                }
            )
            
            // Update Your Profile (checkbox manually tappable)
            ToDoCard(
                title: "Update Your Profile",
                description: "Make your space feel like yours — add a photo, write a bio, or stay anonymous if you prefer.",
                isChecked: $profileChecked,
                allowManualCheckbox: true,
                action: {
                    showingProfile = true
                }
            )
            
            // Pledge for Today (checkbox NOT manually tappable - controlled by PledgeManager)
            ToDoCard(
                title: "Pledge for Today",
                description: "Make a daily commitment to stay strong. Small, achievable goals build lasting change.",
                isChecked: .constant(pledgeManager.isPledgedToday),
                allowManualCheckbox: false,
                action: {
                    showingPledge = true
                }
            )
            
            // Create A Post (checkbox manually tappable)
            ToDoCard(
                title: "Create A Post",
                description: "Share your story, struggles, or victories with the community. Your experience might help someone else.",
                isChecked: $createPostChecked,
                allowManualCheckbox: true,
                action: {
                    showingCreatePost = true
                }
            )
        }
        .padding(16)
        .background(
            LinearGradient.accent
                .opacity(0.3)
        )
        .cornerRadius(12)
        .sheet(isPresented: $showingWebsiteBlocker) {
            WebsiteBlockerView()
        }
        .sheet(isPresented: $showingProfile) {
            SettingsView()
        }
        .sheet(isPresented: $showingPledge) {
            PledgeView()
        }
        .sheet(isPresented: $showingCreatePost) {
            CreatePostView(onPostCreated: {
                createPostChecked = true
            })
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationsChecked = true
                }
            }
        }
    }
}

// MARK: - To Do Card

struct ToDoCard: View {
    let title: String
    let description: String
    @Binding var isChecked: Bool
    var allowManualCheckbox: Bool = true
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Main tappable area (title, description, arrow)
            Button(action: {
                action?()
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    // Title and checkbox row
                    HStack(alignment: .top, spacing: 12) {
                        Text(title)
                            .font(.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(.textPrimary)
                            .strikethrough(isChecked, color: .textPrimary)
                        
                        Spacer()
                        
                        // Checkbox (separate tap target for manual, display only for auto)
                        if allowManualCheckbox {
                            Button(action: {
                                isChecked.toggle()
                            }) {
                                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(isChecked ? .accentGradientStart : .textTertiary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
                                .foregroundColor(isChecked ? .accentGradientStart : .textTertiary)
                        }
                    }
                    
                    // Description and arrow row
                    HStack(alignment: .bottom, spacing: 12) {
                        Text(description)
                            .font(.captionSmall)
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                            .strikethrough(isChecked, color: .textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(LinearGradient.accent.opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Reminders Management View

struct RemindersManagementView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var remindersManager: RemindersManager
    @State private var newReminder = ""
    @State private var editingReminder: RecoveryReminder?
    @State private var editText = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                VStack(spacing: 20) {
                    // Existing reminders
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(remindersManager.reminders) { reminder in
                                HStack {
                                    if editingReminder?.id == reminder.id {
                                        // Edit mode
                                        TextField("", text: $editText)
                                            .foregroundColor(.textPrimary)
                                            .onSubmit {
                                                Task {
                                                    await remindersManager.updateReminder(reminder, newText: editText)
                                                    editingReminder = nil
                                                }
                                            }
                                    } else {
                                        Text(reminder.text)
                                            .foregroundColor(.textPrimary)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        // Edit button
                                        Button(action: {
                                            editingReminder = reminder
                                            editText = reminder.text
                                        }) {
                                            Image(systemName: "pencil")
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        // Delete button
                                        Button(action: {
                                            Task {
                                                await remindersManager.deleteReminder(reminder)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(LinearGradient.accent.opacity(0.5))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                    
                    // Add new reminder
                    VStack(spacing: 12) {
                        TextField("", text: $newReminder, prompt: Text("Add new reminder...").foregroundColor(.textTertiary))
                            .textFieldStyle(.plain)
                            .foregroundColor(.textPrimary)
                            .padding()
                            .background(Color.surfaceBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                        
                        Button(action: {
                            if !newReminder.isEmpty {
                                Task {
                                    await remindersManager.createReminder(text: newReminder)
                                    newReminder = ""
                                }
                            }
                        }) {
                            Text("Add Reminder")
                                .font(.button)
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(LinearGradient.accent)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Manage Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.textPrimary)
                }
            }
            .toolbarBackground(Color.backgroundGradientStart, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
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
