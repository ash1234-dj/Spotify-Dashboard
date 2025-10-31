//
//  SpotifyPlaybackManager.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import Combine
import AVFoundation

// MARK: - Spotify Playback Manager
class SpotifyPlaybackManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTrack: Track?
    @Published var volume: Float = 0.5
    @Published var playbackPosition: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopPlayback()
        playbackTimer?.invalidate()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
            errorMessage = "Failed to setup audio session"
        }
    }
    
    // MARK: - Playback Control
    
    func playTrack(_ track: Track) {
        guard let previewURL = track.preview_url, !previewURL.isEmpty else {
            errorMessage = "No preview available for this track"
            return
        }
        
        isLoading = true
        currentTrack = track
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: URL(string: previewURL)!)
                
                await MainActor.run {
                    do {
                        self.audioPlayer = try AVAudioPlayer(data: data)
                        self.audioPlayer?.delegate = self
                        self.audioPlayer?.volume = self.volume
                        self.audioPlayer?.prepareToPlay()
                        
                        if self.audioPlayer?.play() == true {
                            self.isPlaying = true
                            self.duration = self.audioPlayer?.duration ?? 0
                            self.startPlaybackTimer()
                            print("🎵 Playing: \(track.name) by \(track.artists.first?.name ?? "Unknown")")
                        } else {
                            self.errorMessage = "Failed to start playback"
                        }
                        
                        self.isLoading = false
                    } catch {
                        self.errorMessage = "Failed to create audio player: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load track: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackTimer()
        print("⏸️ Playback paused")
    }
    
    func resumePlayback() {
        if audioPlayer?.play() == true {
            isPlaying = true
            startPlaybackTimer()
            print("▶️ Playback resumed")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        playbackPosition = 0
        stopPlaybackTimer()
        print("⏹️ Playback stopped")
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        audioPlayer?.volume = volume
        print("🔊 Volume set to: \(Int(volume * 100))%")
    }
    
    func seekTo(_ position: TimeInterval) {
        audioPlayer?.currentTime = position
        playbackPosition = position
    }
    
    // MARK: - Playback Timer
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.playbackPosition = player.currentTime
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    // MARK: - Track Management
    
    func playNextTrack(from tracks: [Track]) {
        guard let currentTrack = currentTrack,
              let currentIndex = tracks.firstIndex(where: { $0.id == currentTrack.id }),
              currentIndex + 1 < tracks.count else {
            return
        }
        
        let nextTrack = tracks[currentIndex + 1]
        playTrack(nextTrack)
    }
    
    func playPreviousTrack(from tracks: [Track]) {
        guard let currentTrack = currentTrack,
              let currentIndex = tracks.firstIndex(where: { $0.id == currentTrack.id }),
              currentIndex > 0 else {
            return
        }
        
        let previousTrack = tracks[currentIndex - 1]
        playTrack(previousTrack)
    }
    
    // MARK: - Playlist Management
    
    func createReadingPlaylist(from tracks: [Track], name: String = "Reading Playlist") -> [Track] {
        // Filter tracks that are suitable for reading (instrumental, ambient, etc.)
        let readingTracks = tracks.filter { track in
            let trackName = track.name.lowercased()
            let artistName = track.artists.first?.name.lowercased() ?? ""
            
            // Keywords that indicate good reading music
            let readingKeywords = [
                "instrumental", "ambient", "classical", "piano", "violin",
                "orchestra", "chill", "relaxing", "peaceful", "calm",
                "reading", "study", "focus", "meditation", "zen"
            ]
            
            return readingKeywords.contains { keyword in
                trackName.contains(keyword) || artistName.contains(keyword)
            }
        }
        
        print("📚 Created reading playlist with \(readingTracks.count) tracks")
        return readingTracks
    }
}

// MARK: - AVAudioPlayerDelegate

extension SpotifyPlaybackManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        playbackPosition = 0
        stopPlaybackTimer()
        print("🎵 Track finished playing")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        errorMessage = "Audio decode error: \(error?.localizedDescription ?? "Unknown error")"
        isPlaying = false
        stopPlaybackTimer()
        print("❌ Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
    }
}

// MARK: - Reading Music Helper

extension SpotifyPlaybackManager {
    
    func startAdaptiveReadingMusic(spotifyManager: SpotifyManager, genre: String) async {
        isLoading = true
        
        // Search for instrumental reading music
        let searchQuery = "\(genre) instrumental reading ambient"
        await spotifyManager.searchSpotify(query: searchQuery)
        
        // Wait for search results
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        if let searchResults = spotifyManager.searchResults,
           !searchResults.tracks.isEmpty {
            
            // Create a reading playlist
            let readingTracks = createReadingPlaylist(from: searchResults.tracks)
            
            if let firstTrack = readingTracks.first {
                await MainActor.run {
                    self.playTrack(firstTrack)
                }
            } else {
                await MainActor.run {
                    self.errorMessage = "No suitable reading tracks found"
                    self.isLoading = false
                }
            }
        } else {
            await MainActor.run {
                self.errorMessage = "No music found for reading"
                self.isLoading = false
            }
        }
    }
    
    func stopAdaptiveReadingMusic() {
        stopPlayback()
        currentTrack = nil
        print("🛑 Stopped adaptive reading music")
    }
}
