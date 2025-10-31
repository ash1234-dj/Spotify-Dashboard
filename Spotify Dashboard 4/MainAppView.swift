//
//  MainAppView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

struct MainAppView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @StateObject private var gutendexManager = GutendexManager()
    @StateObject private var openLibraryManager = OpenLibraryManager()
    @StateObject private var firebaseSync = FirebaseSyncManager()
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var moodTracker = MoodTracker()
    
    init() {
        // Reset onboarding for testing - always show welcome page during development
        #if DEBUG
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        #endif
    }
    
    var body: some View {
        if hasCompletedOnboarding {
            // Main app content
            TabView {
                ReadingSessionView()
                    .tabItem {
                        Label("Read", systemImage: "text.book.closed.fill")
                    }
                    .tag(0)

                AuthorDiscoveryView()
                    .tabItem {
                        Label("Authors", systemImage: "person.2.fill")
                    }
                    .tag(1)

                PodcastView()
                    .tabItem {
                        Label("Podcasts", systemImage: "waveform.circle.fill")
                    }
                    .tag(2)

                MoodDiaryView()
                    .tabItem {
                        Label("Diary", systemImage: "bookmark.fill")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(4)
            }
            .environmentObject(gutendexManager)
            .environmentObject(openLibraryManager)
            .environmentObject(firebaseSync)
            .environmentObject(authManager)
            .environmentObject(moodTracker)
            .onAppear {
                // Sync data when app appears
                Task {
                    await firebaseSync.syncAllData()
                }
            }
        } else {
            // Onboarding flow
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(gutendexManager)
                .environmentObject(authManager)
        }
    }
}

// MARK: - StorySelectionView is now in separate file

// MARK: - ReadingSessionView is now in separate file

// MARK: - MoodDiaryView is now in separate file

// MARK: - SettingsView is now in separate file

