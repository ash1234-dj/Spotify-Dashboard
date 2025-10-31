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
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
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


