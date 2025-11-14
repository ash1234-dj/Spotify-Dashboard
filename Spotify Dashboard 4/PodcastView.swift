//
//  PodcastView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

// MARK: - HTML Utilities

private func cleanedHTMLText(from text: String) -> String {
    guard !text.isEmpty else { return "" }
    
    if let data = text.data(using: .utf8),
       let attributedString = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
       ) {
        let plain = attributedString.string
        return plain.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    return text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#39;", with: "'")
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

struct PodcastView: View {
    @StateObject private var podcastManager = PodcastManager()
    @StateObject private var audioPlayer = AudioPlayerManager()
    @EnvironmentObject var moodTracker: MoodTracker
    
    @State private var showingMoodPicker = false
    @State private var selectedPodcast: Podcast?
    @State private var showingPodcastDetail = false
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    if podcastManager.podcasts.isEmpty && !podcastManager.isLoading {
                        emptyStateView
                    } else {
                        podcastsList
                    }
                }
                .navigationTitle("Podcasts")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingMoodPicker = true
                        }) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                        }
                    }
                }
                .environmentObject(audioPlayer)
                .sheet(isPresented: $showingMoodPicker) {
                    MoodSelectionView(
                        selectedMood: $podcastManager.selectedMood,
                        onSearch: {
                            await podcastManager.searchPodcastsByMood(podcastManager.selectedMood)
                        }
                    )
                }
        .sheet(item: $selectedPodcast) { podcast in
            PodcastDetailView(
                podcast: podcast,
                mood: podcastManager.selectedMood,
                diaryText: getLatestDiaryText(),
                audioPlayer: audioPlayer
            )
        }
            }
            
            // Mini player overlay
            if audioPlayer.currentEpisode != nil {
                VStack {
                    Spacer()
                    MiniPlayerView(player: audioPlayer)
                        .frame(height: 60)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }
    
    // MARK: - Empty State
    
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("Discover AI-Adaptive Podcasts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Select your mood to discover podcasts that match how you're feeling right now")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // AI Mood Detection Button
            Button(action: {
                Task {
                    await podcastManager.searchBasedOnLatestMood(from: moodTracker.entries)
                }
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Detect Mood from Diary")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(moodTracker.entries.isEmpty)
            
            // Or manually select mood
            Button(action: {
                showingMoodPicker = true
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("Choose My Mood")
                }
                .foregroundColor(.purple)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Podcasts List
    
    var podcastsList: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search podcasts...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        if !searchText.isEmpty {
                            Task {
                                await podcastManager.searchPodcasts(query: searchText)
                            }
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        podcastManager.clearResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Current Search Info
            if podcastManager.selectedMood != "Calm" || !podcastManager.podcasts.isEmpty {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundColor(.purple)
                    
                    Text("Mood: \(podcastManager.selectedMood)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Error Message
            if let error = podcastManager.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Error")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Podcasts
            ScrollView {
                LazyVStack(spacing: 16) {
                    if podcastManager.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    ForEach(podcastManager.podcasts) { podcast in
                        PodcastCard(
                            podcast: podcast,
                            onTap: {
                                selectedPodcast = podcast
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getLatestDiaryText() -> String {
        guard let latestEntry = moodTracker.entries.first else {
            return ""
        }
        return latestEntry.notes
    }
}

// MARK: - Podcast Card

struct PodcastCard: View {
    let podcast: Podcast
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Thumbnail
                AsyncImage(url: URL(string: podcast.thumbnail ?? podcast.image ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "waveform.circle.fill")
                                .foregroundColor(.gray)
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "waveform.circle.fill")
                                .foregroundColor(.gray)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(podcast.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(podcast.publisher)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Label("\(podcast.totalEpisodes)", systemImage: "play.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if podcast.explicitContent {
                            Text("E")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mood Selection View

struct MoodSelectionView: View {
    @Binding var selectedMood: String
    let onSearch: () async -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let moods = [
        ("Calm", "😌", "relaxation meditation"),
        ("Inspired", "✨", "motivation success"),
        ("Sad", "😢", "empathy support"),
        ("Curious", "🤔", "storytelling narrative"),
        ("Anxious", "😰", "mindfulness wellness"),
        ("Happy", "😊", "entertainment comedy"),
        ("Reflective", "💭", "contemplation philosophy"),
        ("Excited", "🎉", "adventure discovery"),
        ("Nostalgic", "📸", "memory history"),
        ("Focused", "🎯", "productivity learning")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Text("How are you feeling?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Text("Select your current mood to discover matching podcasts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(moods, id: \.0) { mood in
                            MoodButton(
                                mood: mood.0,
                                emoji: mood.1,
                                isSelected: selectedMood == mood.0
                            ) {
                                selectedMood = mood.0
                            }
                        }
                    }
                    .padding()
                    
                    Button(action: {
                        Task {
                            await onSearch()
                            await MainActor.run {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Search Podcasts")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .fontWeight(.semibold)
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
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Select Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Mood Button

struct MoodButton: View {
    let mood: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 40))
                
                Text(mood)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 140, height: 100)
            .background(
                isSelected ?
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color(.systemGray6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Podcast Detail View

struct PodcastDetailView: View {
    let podcast: Podcast
    let mood: String
    let diaryText: String?
    @ObservedObject var audioPlayer: AudioPlayerManager
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var podcastManager = PodcastManager()
    @State private var showingAIRec = false
    @State private var isLoadingReason = false
    @State private var showEpisodesSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with image
                AsyncImage(url: URL(string: podcast.image ?? podcast.thumbnail ?? "")) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                        .frame(height: 250)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.3)
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                        .frame(height: 250)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .cornerRadius(20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(podcast.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("by \(podcast.publisher)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Label("\(podcast.totalEpisodes) Episodes", systemImage: "play.circle.fill")
                            .font(.caption)
                        
                        if podcast.explicitContent {
                            Text("EXPLICIT")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                    }
                    
                    // AI Recommendation Button
                    Button(action: {
                        showingAIRec = true
                        loadAIReason()
                    }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                            Text("Why This Podcast For My Mood?")
                            Spacer()
                            if isLoadingReason {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.semibold)
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
                .padding(.horizontal)
                
                // AI Recommendation
                if showingAIRec && !podcastManager.aiRecommendationReason.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                            Text("AI Recommendation")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        Text(podcastManager.aiRecommendationReason)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("About")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                        Text(cleanedHTMLText(from: podcast.description))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Episodes info
                VStack(alignment: .leading, spacing: 8) {
                    Label("Total Episodes: \(podcast.totalEpisodes)", systemImage: "play.circle")
                    Label("Language: \(podcast.language)", systemImage: "globe")
                    Label("Country: \(podcast.country)", systemImage: "mappin.circle")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Episodes access
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Episodes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if podcastManager.isLoadingEpisodes {
                            ProgressView()
                        } else if !podcastManager.episodes.isEmpty {
                            Text("\(podcastManager.episodes.count) loaded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Tap below to browse the complete list of episodes for this podcast.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        if podcastManager.episodes.isEmpty {
                            loadEpisodes(forceRefresh: false)
                        }
                        showEpisodesSheet = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet.rectangle.portrait")
                            Text("View All Episodes")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .fontWeight(.semibold)
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
                    .padding(.horizontal)
                    
                    if !podcastManager.episodes.isEmpty {
                        Divider()
                            .padding(.horizontal)
                        
                        Text("Latest Episodes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal)
                        
                        ForEach(podcastManager.episodes.prefix(3)) { episode in
                            EpisodeCard(episode: episode, audioPlayer: audioPlayer)
                        }
                    }
                }
                .padding(.bottom)
            }
        }
        .navigationTitle("Podcast Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showEpisodesSheet) {
            EpisodesSheetView(
                podcast: podcast,
                podcastManager: podcastManager,
                audioPlayer: audioPlayer
            )
        }
    }
    
    private func loadAIReason() {
        isLoadingReason = true
        Task {
            await podcastManager.getAIRecommendationReason(
                podcast: podcast,
                for: mood,
                diaryText: diaryText
            )
            isLoadingReason = false
        }
    }
    
    private func loadEpisodes(forceRefresh: Bool) {
        if podcastManager.isLoadingEpisodes {
            return
        }
        
        if !forceRefresh && !podcastManager.episodes.isEmpty {
            return
        }
        
        Task {
            await podcastManager.fetchEpisodes(for: podcast.id)
        }
    }
}

// MARK: - Episode Card

struct EpisodeCard: View {
    let episode: PodcastEpisode
    @ObservedObject var audioPlayer: AudioPlayerManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Play button
            Button(action: {
                audioPlayer.playEpisode(episode)
            }) {
                Image(systemName: audioPlayer.currentEpisode?.id == episode.id && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.purple)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Episode info
            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(cleanedHTMLText(from: episode.description))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(episode.duration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if episode.explicitContent {
                        Text("E")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
}

// MARK: - Episodes Sheet

struct EpisodesSheetView: View {
    let podcast: Podcast
    @ObservedObject var podcastManager: PodcastManager
    @ObservedObject var audioPlayer: AudioPlayerManager
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Group {
                if podcastManager.isLoadingEpisodes && podcastManager.episodes.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading episodes…")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if podcastManager.episodes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                        Text("No episodes available right now.")
                            .font(.headline)
                        Text("Try refreshing to fetch the latest episodes from ListenNotes.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            Task {
                                await podcastManager.fetchEpisodes(for: podcast.id)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Reload")
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(podcastManager.episodes) { episode in
                                EpisodeCard(episode: episode, audioPlayer: audioPlayer)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await podcastManager.fetchEpisodes(for: podcast.id)
                    }
                }
            }
            .navigationTitle("All Episodes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if podcastManager.isLoadingEpisodes {
                        ProgressView()
                    } else {
                        Button {
                            Task {
                                await podcastManager.fetchEpisodes(for: podcast.id)
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task {
            if podcastManager.episodes.isEmpty && !podcastManager.isLoadingEpisodes {
                await podcastManager.fetchEpisodes(for: podcast.id)
            }
        }
    }
}


