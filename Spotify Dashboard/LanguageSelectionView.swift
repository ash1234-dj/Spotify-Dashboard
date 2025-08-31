//
//  LanguageSelectionView.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 07/08/25.
//

import SwiftUI

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: Language
    @ObservedObject var spotifyManager: SpotifyManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Language Header
            HStack {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Trending Tracks")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Selected language display
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(selectedLanguage.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                            .background(
                                Capsule()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Refresh button
                Button(action: {
                    spotifyManager.manualRefresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal)
            
            // Language dropdown
            if isExpanded {
                VStack(spacing: 8) {
                            ForEach(Language.allCases, id: \.rawValue) { language in
                        LanguageOptionRow(
                            language: language,
                            isSelected: language == selectedLanguage
                        ) {
                            // Update language without causing navigation issues
                            DispatchQueue.main.async {
                                self.selectedLanguage = language
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    self.isExpanded = false
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.4))
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Last updated info
            if let lastUpdated = spotifyManager.lastUpdated {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("Updated \(timeAgoString(from: lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
}

struct LanguageOptionRow: View {
    let language: Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(language.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.green.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color.black.opacity(0.9),
                Color.purple.opacity(0.1),
                Color.black.opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        LanguageSelectionView(
            selectedLanguage: .constant(.english),
            spotifyManager: SpotifyManager()
        )
    }
}
