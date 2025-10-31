//
//  Config.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation

// MARK: - Spotify Configuration
struct SpotifyConfig {
    static let clientId = "8daa6921d510480196865c592e3af024"
    static let clientSecret = "2b8a713e39aa448096ee2beeb95d609e"
    static let redirectURI = "spotify-dashboard://callback"
}

// MARK: - Gutendex Configuration
struct GutendexConfig {
    static let baseURL = "https://gutendex.com"
    static let booksEndpoint = "/books"
    static let searchEndpoint = "/books?search="
}


