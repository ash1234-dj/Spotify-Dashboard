
//  AudioPlayer.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Audio Player Manager

@MainActor
class AudioPlayerManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentEpisode: PodcastEpisode?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var episodeProgress: [String: Double] = [:] // episodeId -> 0.0...1.0
    @Published private(set) var resumeByPodcast: [String: [String: String]] = [:] // podcastId -> ["episodeId","episodeTitle","podcastTitle","currentTime","duration"]
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var currentPodcastId: String?
    private var currentPodcastTitle: String?
    
    init() {
        loadProgressFromStorage()
        loadResumeMap()
    }
    
    func playEpisode(_ episode: PodcastEpisode, inPodcast podcast: Podcast? = nil) {
        guard let audioURL = episode.audioURL else { return }
        
        // Track podcast context if provided
        if let podcast = podcast {
            currentPodcastId = podcast.id
            currentPodcastTitle = podcast.title
        }
        
        if currentEpisode?.id == episode.id {
            // Same episode - toggle play/pause
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                player?.play()
                isPlaying = true
            }
        } else {
            // New episode - load and play
            currentEpisode = episode
            
            // Stop current player
            player?.pause()
            if let token = timeObserverToken {
                player?.removeTimeObserver(token)
                timeObserverToken = nil
            }
            
            // Create new player
            let asset = AVPlayerItem(url: audioURL)
            player = AVPlayer(playerItem: asset)
            
            // Add time observer
            let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time.seconds
                self.persistProgressTick()
            }
            
            // Observe duration
            Task {
                await observeDuration()
                
                // Restore previous position if available
                if let saved = getSavedTime(for: episode.id), saved > 0, saved < self.duration {
                    self.seek(to: saved)
                }
            }
            
            player?.play()
            isPlaying = true
            
            // Persist initial resume info
            updateResumeInfoIfNeeded()
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        persistProgressTick()
    }
    
    func stop() {
        player?.pause()
        player = nil
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        currentEpisode = nil
        isPlaying = false
        currentTime = 0
        duration = 0
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    private func observeDuration() async {
        while let player = player {
            if let duration = try? await player.currentItem?.asset.load(.duration) {
                self.duration = duration.seconds
                break
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    // MARK: - Progress Persistence (Local)
    
    private func persistProgressTick() {
        guard let episode = currentEpisode, duration > 0, currentTime >= 0 else { return }
        let progress = max(0.0, min(currentTime / duration, 1.0))
        episodeProgress[episode.id] = progress
        
        // Save compactly as [String:String] to UserDefaults
        let dict = Dictionary(uniqueKeysWithValues: episodeProgress.map { ($0.key, String($0.value)) })
        UserDefaults.standard.set(dict, forKey: "podcastEpisodeProgress")
        
        // Save current episode state for quick resume
        let state: [String: String] = [
            "episodeId": episode.id,
            "episodeTitle": episode.title,
            "podcastId": currentPodcastId ?? "",
            "podcastTitle": currentPodcastTitle ?? "",
            "currentTime": String(currentTime),
            "duration": String(duration)
        ]
        UserDefaults.standard.set(state, forKey: "currentEpisodeState")
        
        // Update per-podcast resume map
        updateResumeInfoIfNeeded()
    }
    
    private func loadProgressFromStorage() {
        if let stored = UserDefaults.standard.dictionary(forKey: "podcastEpisodeProgress") as? [String: String] {
            var loaded: [String: Double] = [:]
            for (k, v) in stored {
                if let d = Double(v) {
                    loaded[k] = d
                }
            }
            self.episodeProgress = loaded
        }
    }
    
    private func loadResumeMap() {
        if let map = UserDefaults.standard.dictionary(forKey: "podcastResumeMap") as? [String: [String: String]] {
            self.resumeByPodcast = map
        }
    }
    
    private func saveResumeMap() {
        UserDefaults.standard.set(resumeByPodcast, forKey: "podcastResumeMap")
    }
    
    private func updateResumeInfoIfNeeded() {
        guard let episode = currentEpisode,
              let podcastId = currentPodcastId,
              let podcastTitle = currentPodcastTitle else { return }
        let info: [String: String] = [
            "episodeId": episode.id,
            "episodeTitle": episode.title,
            "podcastId": podcastId,
            "podcastTitle": podcastTitle,
            "currentTime": String(currentTime),
            "duration": String(max(duration, 0))
        ]
        resumeByPodcast[podcastId] = info
        saveResumeMap()
    }
    
    func getProgress(for episodeId: String) -> Double {
        episodeProgress[episodeId] ?? 0.0
    }
    
    private func getSavedTime(for episodeId: String) -> TimeInterval? {
        let progress = getProgress(for: episodeId)
        guard progress > 0, duration > 0 else { return nil }
        return progress * duration
    }
    
    // Public helper for UI
    func getResumeInfo(for podcastId: String) -> (episodeId: String, episodeTitle: String, time: TimeInterval, duration: TimeInterval)? {
        guard let info = resumeByPodcast[podcastId],
              let eid = info["episodeId"],
              let title = info["episodeTitle"],
              let timeStr = info["currentTime"],
              let time = TimeInterval(timeStr) else { return nil }
        let dur: TimeInterval = TimeInterval(info["duration"] ?? "") ?? 0
        return (eid, title, time, dur)
    }
}

// MARK: - Mini Player View

struct MiniPlayerView: View {
    @ObservedObject var player: AudioPlayerManager
    
    var body: some View {
        if let episode = player.currentEpisode {
            VStack(spacing: 0) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)
                        
                        if player.duration > 0 {
                            Rectangle()
                                .fill(Color.purple)
                                .frame(width: geometry.size.width * (player.currentTime / player.duration))
                                .frame(height: 2)
                        }
                    }
                }
                .frame(height: 2)
                
                HStack(spacing: 12) {
                    // Play/Pause button
                    Button(action: {
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.playEpisode(episode)
                        }
                    }) {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                    }
                    
                    // Episode info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(episode.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Text(formatTime(player.currentTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        player.stop()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
