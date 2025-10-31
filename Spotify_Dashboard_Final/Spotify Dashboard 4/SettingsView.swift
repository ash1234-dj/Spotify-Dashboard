//
//  SettingsView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager
    @EnvironmentObject var gutendexManager: GutendexManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedGenres") private var selectedGenresData: Data = Data()
    @AppStorage("moodSensitivity") private var moodSensitivity = 0.5
    @AppStorage("spotifyConnected") private var spotifyConnected = false
    
    @State private var showingResetAlert = false
    @State private var showingSpotifyConnect = false
    @State private var showingSignIn = false
    @State private var showingSignOutAlert = false
    
    var selectedGenres: [String] {
        if let genres = try? JSONDecoder().decode([String].self, from: selectedGenresData) {
            return genres
        }
        return []
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Account Section
                Section("Account") {
                    if authManager.isAuthenticated, let user = authManager.user {
                        // Signed In User
                        HStack {
                            AsyncImage(url: URL(string: user.photoURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: user.provider.icon)
                                    .foregroundColor(.purple)
                            }
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Signed in with \(user.provider.displayName)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Sign Out") {
                                showingSignOutAlert = true
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    } else {
                        // Guest User
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Guest User")
                                    .font(.headline)
                                Text("Sign in to sync your data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Sign In") {
                                showingSignIn = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    Button(action: {
                        showingSpotifyConnect = true
                    }) {
                        HStack {
                            Image(systemName: spotifyConnected ? "checkmark.circle.fill" : "music.note")
                                .foregroundColor(spotifyConnected ? .green : .primary)
                            
                            Text(spotifyConnected ? "Spotify Connected" : "Connect Spotify")
                            
                            Spacer()
                            
                            if spotifyConnected {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Reading Preferences
                Section("Reading Preferences") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Genres")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if selectedGenres.isEmpty {
                            Text("No genres selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            FlowLayout(items: selectedGenres) { genre in
                                Text(genre)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mood Sensitivity: \(Int(moodSensitivity * 100))%")
                            .font(.subheadline)
                        
                        Slider(value: $moodSensitivity, in: 0...1)
                            .tint(.purple)
                        
                        Text(moodSensitivityText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Accessibility
                Section("Accessibility") {
                    Toggle("Dyslexia-Friendly Font", isOn: .constant(false))
                    Toggle("Reduce Motion", isOn: .constant(false))
                    Toggle("Increase Contrast", isOn: .constant(false))
                    Toggle("VoiceOver Support", isOn: .constant(true))
                    
                    Picker("Text Size", selection: .constant("Default")) {
                        Text("Small").tag("Small")
                        Text("Default").tag("Default")
                        Text("Large").tag("Large")
                        Text("Extra Large").tag("Extra Large")
                    }
                }
                
                // Privacy & Data
                Section("Privacy & Data") {
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {
                        // Clear cache
                        gutendexManager.clearCache()
                    }) {
                        HStack {
                            Text("Clear Cache")
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // App Info
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Danger Zone
                Section {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset App")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset App", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetApp()
                }
            } message: {
                Text("This will delete all your data and reset the app to initial state.")
            }
            .sheet(isPresented: $showingSpotifyConnect) {
                SpotifyAuthView()
            }
            .sheet(isPresented: $showingSignIn) {
                SignInView()
                    .environmentObject(authManager)
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? Your local data will remain, but sync will be disabled.")
            }
        }
    }
    
    var moodSensitivityText: String {
        if moodSensitivity < 0.3 {
            return "Music stays consistent throughout"
        } else if moodSensitivity < 0.7 {
            return "Music adapts to major story changes"
        } else {
            return "Music dynamically responds to every moment"
        }
    }
    
    func resetApp() {
        // Reset onboarding
        hasCompletedOnboarding = false
        
        // Clear preferences
        selectedGenresData = Data()
        moodSensitivity = 0.5
        spotifyConnected = false
        
        // Clear caches
        gutendexManager.clearCache()
    }
}

// MARK: - Flow Layout

struct FlowLayout: View {
    let items: [String]
    let content: (String) -> AnyView
    
    init(items: [String], @ViewBuilder content: @escaping (String) -> some View) {
        self.items = items
        self.content = { item in
            AnyView(content(item))
        }
    }
    
    var body: some View {
        WrappingHStack(items: items) { item in
            content(item)
        }
    }
}

struct WrappingHStack: View {
    let items: [String]
    let content: (String) -> AnyView
    
    init(items: [String], @ViewBuilder content: @escaping (String) -> some View) {
        self.items = items
        self.content = { item in
            AnyView(content(item))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        content(item)
                    }
                }
            }
        }
    }
    
    private var rows: [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        
        for item in items {
            currentRow.append(item)
            if currentRow.count >= 3 {
                result.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            result.append(currentRow)
        }
        
        return result
    }
}

