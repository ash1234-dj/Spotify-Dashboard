//
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
    
    private var player: AVPlayer?
    
    func playEpisode(_ episode: PodcastEpisode) {
        guard let audioURL = episode.audioURL else { return }
        
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
            
            // Create new player
            let asset = AVPlayerItem(url: audioURL)
            player = AVPlayer(playerItem: asset)
            
            // Add time observer
            let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                self?.currentTime = time.seconds
            }
            
            // Observe duration
            Task {
                await observeDuration()
            }
            
            player?.play()
            isPlaying = true
        }
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player = nil
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
