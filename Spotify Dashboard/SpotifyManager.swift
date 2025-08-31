//
//  SpotifyManager.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import Combine

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct Followers: Codable {
    let total: Int
}

struct Artist: Codable {
    let id: String
    let name: String
    let popularity: Int?
    let images: [SpotifyImage]?
    let followers: Followers?
}

struct Album: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
    let release_date: String
}

struct ExternalUrls: Codable {
    let spotify: String
}

struct Track: Codable {
    let id: String
    let name: String
    let popularity: Int?
    let artists: [Artist]
    let album: Album
    let preview_url: String?
    let external_urls: ExternalUrls
}

struct ArtistsSearchResponse: Codable {
    let artists: ArtistsResult
}

struct ArtistsResult: Codable {
    let items: [Artist]
}

struct TracksSearchResponse: Codable {
    let tracks: TracksResult
}

struct TracksResult: Codable {
    let items: [Track]
}

// MARK: - Search Results Structure
struct SearchResults {
    let artists: [Artist]
    let tracks: [Track]
}

// MARK: - Combined Search Response
struct SpotifySearchResponse: Codable {
    let artists: ArtistsResult
    let tracks: TracksResult
}

// MARK: - API Error Enum
enum APIError: Error {
    case invalidURL
    case httpError
    case noData
    case authenticationFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .httpError:
            return "Network request failed"
        case .noData:
            return "No data received"
        case .authenticationFailed:
            return "Authentication failed - check your credentials"
        }
    }
}

// MARK: - Language Support with Indian Languages
enum Language: String, CaseIterable, Codable {
    case english = "en"
    case hindi = "hi"
    case tamil = "ta"
    case telugu = "te"
    case kannada = "kn"
    case malayalam = "ml"
    case bengali = "bn"
    case marathi = "mr"
    case gujarati = "gu"
    case punjabi = "pa"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case korean = "ko"
    case japanese = "ja"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hindi: return "हिन्दी"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .kannada: return "ಕನ್ನಡ"
        case .malayalam: return "മലയാളം"
        case .bengali: return "বাংলা"
        case .marathi: return "मराठी"
        case .gujarati: return "ગુજરાતી"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
    
    var trendingQueries: [String] {
        switch self {
        case .english:
            return ["trending", "viral", "top hits", "popular", "billboard hot 100", "charts"]
        case .hindi:
            return ["bollywood", "hindi hits", "trending indian", "desi pop", "indian music", "new hindi songs"]
        case .tamil:
            return ["tamil songs", "kollywood", "tamil hits", "tamil music", "new tamil songs", "rajinikanth songs"]
        case .telugu:
            return ["telugu songs", "tollywood", "telugu hits", "telugu music", "new telugu songs", "vijay devarakonda"]
        case .kannada:
            return ["kannada songs", "sandalwood", "kannada hits", "kannada music", "new kannada songs", "punith raj"]
        case .malayalam:
            return ["malayalam songs", "mollywood", "malayalam hits", "malayalam music", "new malayalam songs", "mammootty"]
        case .bengali:
            return ["bengali songs", "bollywood bengali", "bengali hits", "bengali music", "new bengali songs", "tollygunge"]
        case .marathi:
            return ["marathi songs", "marathi hits", "marathi music", "new marathi songs", "marathi bhavgeet"]
        case .gujarati:
            return ["gujarati songs", "gujarati hits", "gujarati music", "new gujarati songs", "gujarati folk"]
        case .punjabi:
            return ["punjabi songs", "bhangra", "punjabi hits", "punjabi pop", "sidhu moosewala", "punjabi music"]
        case .spanish:
            return ["música latina", "regueton", "flamenco", "spanish hits", "latino", "latinoamericano"]
        case .french:
            return ["chanson française", "french pop", "rap français", "french hits", "francophone"]
        case .german:
            return ["deutschrap", "german rock", "schlager", "german hits", "austrian pop"]
        case .italian:
            return ["italiano", "canta italiano", "opera", "trap italiano", "italian pop"]
        case .portuguese:
            return ["funk brasileiro", "sertanejo", "mpb", "bossa nova", "brazilian hits"]
        case .korean:
            return ["k-pop", "k-pop hits", "bts", "blackpink", "twice", "korean pop"]
        case .japanese:
            return ["j-pop", "anime music", "japanese pop", "city pop", "japanese indie"]
        case .chinese:
            return ["c-pop", "mandarin pop", "cantonese pop", "taiwan pop", "hong kong music"]
        }
    }
}

// MARK: - SpotifyManager Class
class SpotifyManager: ObservableObject {
    @Published var popularArtists: [Artist] = []
    @Published var trendingTracks: [Track] = []
    @Published var searchResults: SearchResults?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedLanguage: Language = .english
    @Published var lastUpdated: Date?
    
    private let clientId = "8daa6921d510480196865c592e3af024"
    private let clientSecret = "2b8a713e39aa448096ee2beeb95d609e"
    private var accessToken: String = ""
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await getAccessToken()
        }
        
        // Start automatic updates timer (every 5 minutes)
        startAutoUpdates()
        
        // Watch for language changes with debouncing to prevent rapid updates
        $selectedLanguage
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] newLanguage in
                Task {
                    await self?.updateTrendingTracksForLanguage(newLanguage)
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - Auto Update Methods
    private func startAutoUpdates() {
        updateTimer?.invalidate() // Stop any existing timer
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.updateTrendingTracksForLanguage(self?.selectedLanguage ?? .english)
            }
        }
    }
    
    func manualRefresh() {
        Task {
            await updateTrendingTracksForLanguage(selectedLanguage)
        }
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.updateTrendingTracksForLanguage(self?.selectedLanguage ?? .english)
            }
        }
    }
    
    // MARK: - Get Access Token
    private func getAccessToken() async {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsBase64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(credentialsBase64)", forHTTPHeaderField: "Authorization")
        
        let body = "grant_type=client_credentials"
        request.httpBody = body.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                await MainActor.run {
                    self.accessToken = token
                    print("✅ Successfully obtained Spotify access token")
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to get access token: \(error.localizedDescription)"
                print("❌ Failed to get access token: \(error)")
            }
        }
    }
    
    // MARK: - Get Popular Artists
    func getPopularArtists() async {
        guard !accessToken.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Access token not available"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🎵 Fetching popular artists from Spotify API...")
        
        // Search for popular artists
        let popularArtistNames = ["Taylor Swift", "Drake", "Ed Sheeran", "Ariana Grande", "The Weeknd", "Billie Eilish", "Post Malone", "Dua Lipa"]
        var artists: [Artist] = []
        
        for artistName in popularArtistNames {
            if let artist = await searchArtist(artistName: artistName) {
                artists.append(artist)
            }
        }
        
        await MainActor.run {
            self.popularArtists = artists
            self.isLoading = false
            print("✅ Loaded \(artists.count) popular artists")
        }
    }
    
    // MARK: - Get Trending Tracks
    func getTrendingTracks() async {
        await updateTrendingTracksForLanguage(selectedLanguage)
    }
    
    // MARK: - Update Trending Tracks for Specific Language
    func updateTrendingTracksForLanguage(_ language: Language) async {
        guard !accessToken.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Access token not available"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🎵 Fetching \(language.displayName) trending tracks from Spotify API...")
        
        // Get trending tracks from language-specific queries
        let trendingQueries = language.trendingQueries
        var tracks: [Track] = []
        
        for query in trendingQueries {
            if let searchedTracks = await searchTracks(query: query) {
                tracks.append(contentsOf: searchedTracks.prefix(5)) // Add 5 tracks from each search
            }
        }
        
        await MainActor.run {
            self.trendingTracks = Array(tracks.prefix(20)) // Limit to 20 tracks
            self.isLoading = false
            self.lastUpdated = Date()
            print("✅ Loaded \(tracks.count) \(language.displayName) trending tracks")
        }
    }
    
    // MARK: - NEW: Spotify Search API Integration
    func searchSpotify(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = nil
            }
            return
        }
        
        guard !accessToken.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Access token not available for search"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🔍 Searching Spotify API for: '\(query)'")
        
        do {
            let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let urlString = "https://api.spotify.com/v1/search?q=\(searchQuery)&type=artist,track&limit=20"
            
            guard let url = URL(string: urlString) else {
                throw APIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.httpError
            }
            
            if httpResponse.statusCode == 401 {
                // Token expired, get new one
                await getAccessToken()
                throw APIError.authenticationFailed
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.httpError
            }
            
            let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
            
            await MainActor.run {
                self.searchResults = SearchResults(
                    artists: searchResponse.artists.items,
                    tracks: searchResponse.tracks.items
                )
                self.isLoading = false
                print("✅ Search completed: \(searchResponse.artists.items.count) artists, \(searchResponse.tracks.items.count) tracks")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.searchResults = nil
                self.isLoading = false
                print("❌ Search failed: \(error)")
            }
        }
    }
    
    private func searchArtist(artistName: String) async -> Artist? {
        let searchURL = "https://api.spotify.com/v1/search?q=\(artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=artist&limit=1"
        
        guard let url = URL(string: searchURL) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for 401 (token expired)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                await getAccessToken() // Refresh token
                return nil
            }
            
            let searchResponse = try JSONDecoder().decode(ArtistsSearchResponse.self, from: data)
            return searchResponse.artists.items.first
        } catch {
            print("Error searching for artist \(artistName): \(error)")
            return nil
        }
    }
    
    private func searchTracks(query: String) async -> [Track]? {
        let searchURL = "https://api.spotify.com/v1/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=track&limit=10"
        
        guard let url = URL(string: searchURL) else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for 401 (token expired)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                await getAccessToken() // Refresh token
                return nil
            }
            
            let searchResponse = try JSONDecoder().decode(TracksSearchResponse.self, from: data)
            return searchResponse.tracks.items
        } catch {
            print("Error searching for tracks with query \(query): \(error)")
            return nil
        }
    }
}