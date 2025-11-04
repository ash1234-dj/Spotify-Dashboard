//
//  JamendoManager.swift
//  Music Story Companion
//
//  Lightweight Jamendo API client used for safe, license-friendly playback
//

import Foundation

struct JamendoTrack: Codable, Identifiable {
    let id: String
    let name: String
    let artist_name: String
    let audio: String // MP3 stream URL
}

struct JamendoTracksResponse: Codable {
    let results: [JamendoTrack]
}

class JamendoManager: ObservableObject {
    @Published var isLoading = false
    @Published var tracks: [JamendoTrack] = []
    @Published var errorMessage: String?
    
    private let clientId = "77de42c5"
    
    // Optimized URLSession with fast configuration
    private lazy var fastSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0 // Fast timeout
        config.timeoutIntervalForResource = 8.0
        config.waitsForConnectivity = false // Don't wait for connectivity
        config.requestCachePolicy = .useProtocolCachePolicy
        config.urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
        return URLSession(configuration: config)
    }()
    
    func fetchTracks(tag: String, limit: Int = 10) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        let encodedTag = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tag
        let urlString = "https://api.jamendo.com/v3.0/tracks/?client_id=\(clientId)&format=json&limit=\(limit)&tags=\(encodedTag)&audioformat=mp31&order=popularity_total"
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.errorMessage = "Invalid Jamendo URL"
                self.isLoading = false
            }
            return
        }
        
        // Use optimized session with timeout
        do {
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 5.0)
            let (data, response) = try await fastSession.data(for: request)
            guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
                throw URLError(.badServerResponse)
            }
            // Jamendo nests data under "results"
            let decoded = try JSONDecoder().decode(JamendoTracksResponse.self, from: data)
            await MainActor.run {
                self.tracks = decoded.results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.tracks = []
                self.isLoading = false
            }
        }
    }
}


