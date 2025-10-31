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
        }
    }
    
    
}
