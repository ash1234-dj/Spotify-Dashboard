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
    @Published var currentTitle: String?
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
        currentTitle = track.name
        
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

    // Play arbitrary audio URL (e.g., Jamendo stream) - Optimized with caching
    private var audioCache: [String: Data] = [:]
    
    // Optimized URLSession for fast audio loading
    private lazy var audioSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8.0 // Faster timeout for audio
        config.timeoutIntervalForResource = 12.0
        config.waitsForConnectivity = false
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024, diskPath: nil) // 50MB memory, 200MB disk
        return URLSession(configuration: config)
    }()
    
    // Preload audio data to cache (called from background)
    func preloadAudioToCache(urlString: String, data: Data) {
        audioCache[urlString] = data
        // Keep last 5 tracks cached (increased from 3)
        if audioCache.count > 5 {
            let firstKey = audioCache.keys.first!
            audioCache.removeValue(forKey: firstKey)
        }
        print("📦 Preloaded to cache: \(urlString.components(separatedBy: "/").last ?? "")")
    }
    
    func playAudioURL(title: String, artist: String, urlString: String) {
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid audio URL"
            return
        }
        
        // Stop previous playback immediately for responsive UI
        audioPlayer?.stop()
        isPlaying = false
        
        // Update title immediately for instant UI feedback
        currentTitle = "\(title) — \(artist)"
        currentTrack = nil
        errorMessage = nil // Clear previous errors
        
        // Check cache first - if cached, play instantly without loading state
        if let cached = audioCache[urlString] {
            // Instant playback from cache
            do {
                self.audioPlayer = try AVAudioPlayer(data: cached)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.volume = self.volume
                self.audioPlayer?.prepareToPlay()
                if self.audioPlayer?.play() == true {
                    self.isPlaying = true
                    self.duration = self.audioPlayer?.duration ?? 0
                    self.startPlaybackTimer()
                    self.isLoading = false
                    print("✅ Instant playback from cache: \(title)")
                } else {
                    self.errorMessage = "Failed to start playback"
                    self.isPlaying = false
                    self.isLoading = false
                }
            } catch {
                // Cache corrupted, fall through to loading
                audioCache.removeValue(forKey: urlString)
                isLoading = true
            }
        } else {
            // Need to load - show loading state briefly
            isLoading = true
        }
        
        // Load in background if not cached - Optimized for speed
        if isLoading {
            Task.detached(priority: .userInitiated) {
                do {
                    // Use optimized session with fast timeout
                    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8.0)
                    let (loadedData, _) = try await self.audioSession.data(for: request)
                    
                    // Cache immediately
                    await MainActor.run {
                        self.audioCache[urlString] = loadedData
                        // Keep last 5 tracks cached (increased for better performance)
                        if self.audioCache.count > 5 {
                            let firstKey = self.audioCache.keys.first!
                            self.audioCache.removeValue(forKey: firstKey)
                        }
                        print("📦 Cached audio for: \(title)")
                    }
                    
                    // Start playing as soon as data is loaded
                    await MainActor.run {
                        do {
                            self.audioPlayer = try AVAudioPlayer(data: loadedData)
                            self.audioPlayer?.delegate = self
                            self.audioPlayer?.volume = self.volume
                            self.audioPlayer?.prepareToPlay()
                            if self.audioPlayer?.play() == true {
                                self.isPlaying = true
                                self.duration = self.audioPlayer?.duration ?? 0
                                self.startPlaybackTimer()
                                print("🎵 Playing: \(self.currentTitle ?? title)")
                            } else {
                                self.errorMessage = "Failed to start playback"
                                self.isPlaying = false
                            }
                            self.isLoading = false
                        } catch {
                            self.errorMessage = "Failed to create audio player: \(error.localizedDescription)"
                            self.isLoading = false
                            self.isPlaying = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to load audio: \(error.localizedDescription)"
                        self.isLoading = false
                        self.isPlaying = false
                    }
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
