//
//  MightBreakFlowView.swift
//  NoMas
//
//  Created by Spencer Twitchell on 12/17/25.
//


//
//  MightBreakFlowView.swift
//  NoMas
//
//  Orchestrates the "I Might Break" flow - animation sequence then main page
//

import SwiftUI

struct MightBreakFlowView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTab: Int
    @State private var showingMainPage = false
    
    var body: some View {
        ZStack {
            if !showingMainPage {
                MightBreakAnimationView(onComplete: {
                    showingMainPage = true
                })
                .transition(.opacity)
            } else {
                MightBreakView(selectedTab: $selectedTab)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showingMainPage)
    }
}

#Preview {
    MightBreakFlowView(selectedTab: .constant(0))
}
