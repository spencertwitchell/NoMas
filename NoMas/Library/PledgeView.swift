//
//  PledgeView.swift
//  NoMas
//
//  Daily sobriety pledge view
//

import SwiftUI

struct PledgeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var pledgeManager = PledgeManager.shared
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Video Background
                LoopingVideoBackground(videoName: "bg flow")
                
                // Dark overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                if pledgeManager.isPledgedToday {
                    alreadyPledgedView
                } else {
                    pledgeContentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Pledge")
                        .font(.titleSmall)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .alert("Pledge for Today?", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Pledge") {
                pledgeManager.makePledge()
                // Brief delay then dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        } message: {
            Text("You're committing to stay strong for the next 24 hours. You've got this!")
        }
    }
    
    // MARK: - Pledge Content View
    
    private var pledgeContentView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Hand icon
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.8))
            
            // Title
            Text("Pledge Sobriety Today")
                .font(.titleLarge)
                .foregroundColor(.white)
            
            // Description
            Text("Make a commitment to yourself to stay strong for today. You'll check in tomorrow to see how you did.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
                .frame(height: 20)
            
            // Benefits card
            benefitsCard
            
            Spacer()
            
            // Pledge button
            Button(action: {
                showingConfirmation = true
            }) {
                Text("Pledge Now")
                    .font(.button)
                    .foregroundColor(.backgroundGradientEnd)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Benefits Card
    
    private var benefitsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            benefitRow(
                icon: "checkmark.circle",
                title: "Achievable Goal",
                description: "When pledging, you agree to stay strong for the day only."
            )
            
            benefitRow(
                icon: "sparkles",
                title: "Take it Easy",
                description: "Just live the day as normal and after pledging, don't change your mind."
            )
            
            benefitRow(
                icon: "crown",
                title: "Success is Inevitable",
                description: "Stay strong, the first few days/weeks will be tough but after that it'll get easier."
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 24)
    }
    
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.buttonSmall)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // MARK: - Already Pledged View
    
    private var alreadyPledgedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Checkmark icon
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("You've Pledged!")
                .font(.titleLarge)
                .foregroundColor(.white)
            
            Text("You made a commitment to stay strong today. Keep going, you've got this!")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let timeRemaining = pledgeManager.timeRemainingString {
                Text(timeRemaining)
                    .font(.caption)
                    .foregroundColor(.accentGradientStart)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            // Close button
            Button(action: { dismiss() }) {
                Text("Close")
                    .font(.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(LinearGradient.accent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview

#Preview {
    PledgeView()
}
