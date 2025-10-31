//
//  MusicStoryCompanionApp.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 07/08/25.
//

import SwiftUI
import Firebase

@main
struct MusicStoryCompanionApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .onOpenURL { url in
                    handleSpotifyCallback(url: url)
                }
        }
    }
    
    private func handleSpotifyCallback(url: URL) {
        print("🎵 Received URL callback: \(url)")
        // Handle Spotify callback URL
        if url.scheme == "spotify-dashboard" && url.host == "callback" {
            print("🎵 Valid Spotify callback URL detected")
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let queryItems = components.queryItems,
               let code = queryItems.first(where: { $0.name == "code" })?.value {
                print("🎵 Authorization code found: \(code)")
                // Notify SpotifyManager about the callback
                NotificationCenter.default.post(
                    name: NSNotification.Name("SpotifyAuthCallback"),
                    object: nil,
                    userInfo: ["code": code]
                )
                print("🎵 Posted notification to SpotifyManager")
            } else {
                print("❌ No authorization code found in URL")
            }
        } else {
            print("❌ Invalid callback URL scheme or host")
        }
    }
}
