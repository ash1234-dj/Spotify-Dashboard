//
//  OnboardingView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var spotifyManager: SpotifyManager
    
    @State private var currentPage = 0
    @State private var selectedGenres: Set<String> = []
    @State private var moodSensitivity: Double = 0.5
    @State private var isConnectingSpotify = false
    @State private var spotifyConnected = false
    
    private let availableGenres = [
        "Classical", "Ambient", "Jazz", "Instrumental",
        "Nature Sounds", "Piano", "Soundtrack", "Acoustic"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if currentPage == 0 {
                welcomePage
            } else if currentPage == 1 {
                genreSelectionPage
            } else if currentPage == 2 {
                moodSensitivityPage
            } else if currentPage == 3 {
                spotifyConnectionPage
            }
        }
        .onAppear {
            // Load saved preferences
            if let savedGenres = UserDefaults.standard.array(forKey: "selectedGenres") as? [String] {
                selectedGenres = Set(savedGenres)
            }
            moodSensitivity = UserDefaults.standard.double(forKey: "moodSensitivity")
            if moodSensitivity == 0 {
                moodSensitivity = 0.5
            }
            
            // Listen for Spotify authentication changes
            spotifyConnected = spotifyManager.isAuthenticated
        }
        .onChange(of: spotifyManager.isAuthenticated) { isAuthenticated in
            spotifyConnected = isAuthenticated
            isConnectingSpotify = false
        }
    }
    
    // MARK: - Welcome Page
    
    var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "book.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple)
                .symbolEffect(.bounce, value: currentPage)
            
            // Title
            Text("Music Story Companion")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Description
            VStack(spacing: 12) {
                Text("Immerse yourself in stories")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("with AI-driven adaptive music")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("• Read classics from Gutenberg Project")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                Text("• Enjoy dynamic music that matches the story")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("• Track your mood and reactions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Continue button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage = 1
                }
            }) {
                HStack {
                    Text("Get Started")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Genre Selection Page
    
    var genreSelectionPage: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Text("Choose Your Music Preferences")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Select genres you enjoy for your reading soundtrack")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.horizontal, 40)
            
            // Genre grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(availableGenres, id: \.self) { genre in
                        GenreButton(
                            genre: genre,
                            isSelected: selectedGenres.contains(genre)
                        ) {
                            if selectedGenres.contains(genre) {
                                selectedGenres.remove(genre)
                            } else {
                                selectedGenres.insert(genre)
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            // Navigation buttons
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage = 0
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(15)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage = 2
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Mood Sensitivity Page
    
    var moodSensitivityPage: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Text("Mood Sensitivity")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("How much should the music adapt to story changes?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Slider
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(Int(moodSensitivity * 100))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.purple)
                    
                    Text(moodSensitivityText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $moodSensitivity, in: 0...1)
                    .tint(Color.purple)
                    .padding(.horizontal, 40)
                
                HStack {
                    Text("Subtle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Very Responsive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Navigation buttons
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage = 1
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(15)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage = 3
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Spotify Connection Page
    
    var spotifyConnectionPage: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Connect Spotify")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Connect your Spotify account to enable dynamic music playback")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 80)
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Connection status
            if spotifyConnected {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Spotify Connected!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            } else {
                VStack(spacing: 20) {
                    // Spotify icon/logo
                    Image(systemName: "music.note.list")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    if isConnectingSpotify {
                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
            
            Spacer()
            
            // Connect button
            Button(action: {
                Task {
                    await connectSpotify()
                }
            }) {
                HStack {
                    Image(systemName: spotifyConnected ? "checkmark.circle.fill" : "music.note")
                    Text(spotifyConnected ? "Connected" : "Connect Spotify")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: spotifyConnected ? [Color.green, Color.green.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(15)
            }
            .disabled(isConnectingSpotify || spotifyConnected)
            .padding(.horizontal, 40)
            
            // Continue button
            if spotifyConnected {
                Button(action: {
                    savePreferences()
                    hasCompletedOnboarding = true
                }) {
                    HStack {
                        Text("Start Reading")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
                .padding(.horizontal, 40)
            }
            
            // Skip button
            if !spotifyConnected {
                Button(action: {
                    savePreferences()
                    hasCompletedOnboarding = true
                }) {
                    Text("Skip for now")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Properties
    
    var moodSensitivityText: String {
        if moodSensitivity < 0.3 {
            return "Music stays consistent throughout"
        } else if moodSensitivity < 0.7 {
            return "Music adapts to major story changes"
        } else {
            return "Music dynamically responds to every moment"
        }
    }
    
    // MARK: - Helper Functions
    
    func connectSpotify() async {
        print("🎵 Starting Spotify connection...")
        isConnectingSpotify = true
        
        do {
            print("🎵 Calling spotifyManager.startAuthentication()...")
            try await spotifyManager.startAuthentication()
            print("🎵 Authentication call completed successfully")
            // The authentication will be handled by the notification system
            // We'll update the UI when the authentication completes
        } catch {
            print("❌ Spotify authentication failed: \(error)")
            await MainActor.run {
                isConnectingSpotify = false
            }
        }
    }
    
    func savePreferences() {
        // Save selected genres
        UserDefaults.standard.set(Array(selectedGenres), forKey: "selectedGenres")
        
        // Save mood sensitivity
        UserDefaults.standard.set(moodSensitivity, forKey: "moodSensitivity")
        
        // Save Spotify connection status
        UserDefaults.standard.set(spotifyConnected, forKey: "spotifyConnected")
    }
}

// MARK: - Genre Button Component

struct GenreButton: View {
    let genre: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(genre)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color.gray.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
}

