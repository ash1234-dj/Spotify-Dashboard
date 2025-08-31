//
//  SpotifyDashboardApp.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 07/08/25.
//

import SwiftUI
import Firebase

@main
struct SpotifyDashboardApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            SpotifyDashboardView()
        }
    }
}
