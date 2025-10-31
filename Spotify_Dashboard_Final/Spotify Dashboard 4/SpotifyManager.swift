//
//  SpotifyManager.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import Combine
import SafariServices

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct Followers: Codable {
    let total: Int
}

struct Artist: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let popularity: Int?
    let images: [SpotifyImage]?
    let followers: Followers?
    
    static func == (lhs: Artist, rhs: Artist) -> Bool {
        return lhs.id == rhs.id
    }
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
            return ["english hits", "top hits usa", "billboard hot 100", "today's top hits", "new music friday", "viral usa"]
        case .hindi:
            return ["हिंदी गाने", "बॉलीवुड", "नए हिंदी गाने", "ट्रेंडिंग हिंदी", "देसी पॉप"]
        case .tamil:
            return ["தமிழ் பாடல்கள்", "கோலிவுட்", "புதிய தமிழ் பாடல்கள்", "டிரென்டிங் தமிழ்", "தமிழ் ஹிட்ஸ்"]
        case .telugu:
            return ["తెలుగు పాటలు", "టాలీవుడ్", "కొత్త తెలుగు పాటలు", "ట్రెండింగ్ తెలుగు", "తెలుగు హిట్స్"]
        case .kannada:
            return ["ಕನ್ನಡ ಹಾಡುಗಳು", "ಸ್ಯಾಂಡಲ್ವುಡ್", "ಹೊಸ ಕನ್ನಡ ಹಾಡುಗಳು", "ಟ್ರೆಂಡಿಂಗ್ ಕನ್ನಡ", "ಕನ್ನಡ ಹಿಟ್ಸ್"]
        case .malayalam:
            return ["മലയാളം പാട്ടുകൾ", "മോളിവുഡ്", "പുതിയ മലയാളം പാട്ടുകൾ", "ട്രെൻഡിംഗ് മലയാളം", "മലയാളം ഹിറ്റ്സ്"]
        case .bengali:
            return ["বাংলা গান", "ট্রেন্ডিং বাংলা", "নতুন বাংলা গান", "বাংলা হিটস"]
        case .marathi:
            return ["मराठी गाणी", "ट्रेंडिंग मराठी", "नवीन मराठी गाणी", "मराठी हिट्स"]
        case .gujarati:
            return ["ગુજરાતી ગીત", "ટ્રેન્ડિંગ ગુજરાતી", "નવા ગુજરાતી ગીત", "ગુજરાતી હિટ્સ"]
        case .punjabi:
            return ["ਪੰਜਾਬੀ ਗਾਣੇ", "ਭਾਂਗੜਾ", "ਨਵੇਂ ਪੰਜਾਬੀ ਗਾਣੇ", "ਟ੍ਰੈਂਡਿੰਗ ਪੰਜਾਬੀ", "ਪੰਜਾਬੀ ਹਿੱਟਸ"]
        case .spanish:
            return ["éxitos españa", "música latina", "reggaetón", "top españa", "novedades viernes"]
        case .french:
            return ["chanson française", "rap français", "hits france", "nouveautés", "top france"]
        case .german:
            return ["deutschrap", "german hits", "schlager", "top deutschland", "neuheiten"]
        case .italian:
            return ["hit italiani", "trap italiano", "nuove uscite", "top italia", "italian pop"]
        case .portuguese:
            return ["hits brasil", "funk brasileiro", "sertanejo", "mpb", "bossa nova"]
        case .korean:
            return ["케이팝", "K-pop", "인기 한국 노래", "한국 가요", "최신 한국 노래"]
        case .japanese:
            return ["J-POP", "邦楽", "アニメソング", "日本のポップ", "最新 日本の歌"]
        case .chinese:
            return ["华语 流行", "国语 歌曲", "粤语 歌曲", "华语 热门", "华语 新歌"]
        }
    }
    
    var seedArtists: [String] {
        switch self {
        case .english:
            return ["Taylor Swift", "Drake", "The Weeknd", "Ed Sheeran", "Billie Eilish"]
        case .hindi:
            return ["Arijit Singh", "Badshah", "Shreya Ghoshal", "Neha Kakkar", "Jubin Nautiyal"]
        case .tamil:
            return ["Anirudh Ravichander", "A. R. Rahman", "Sid Sriram", "Yuvan Shankar Raja", "Dhanush"]
        case .telugu:
            return ["Devi Sri Prasad", "Thaman S", "Sid Sriram", "Anirudh Ravichander", "Armaan Malik"]
        case .kannada:
            return ["Arjun Janya", "Vijay Prakash", "Charan Raj", "Anirudh Shastry", "Vasuki Vaibhav"]
        case .malayalam:
            return ["Vineeth Sreenivasan", "Sushin Shyam", "Sithara Krishnakumar", "KS Harisankar", "Shreya Ghoshal"]
        case .bengali:
            return ["Arijit Singh", "Shreya Ghoshal", "Anupam Roy", "Ishan Mitra", "Lagnajita Chakraborty"]
        case .marathi:
            return ["Ajay-Atul", "Shankar Mahadevan", "Avadhoot Gupte", "Sonu Nigam", "Shreya Ghoshal"]
        case .gujarati:
            return ["Sachin-Jigar", "Aishwarya Majmudar", "Kinjal Dave", "Jigardan Gadhavi", "Kirtidan Gadhvi"]
        case .punjabi:
            return ["Sidhu Moose Wala", "AP Dhillon", "Diljit Dosanjh", "Karan Aujla", "Shubh"]
        case .spanish:
            return ["Bad Bunny", "Rosalía", "Quevedo", "Karol G", "J Balvin"]
        case .french:
            return ["Aya Nakamura", "PNL", "Stromae", "GIMS", "Ninho"]
        case .german:
            return ["Apache 207", "RAF Camora", "Capital Bra", "Bonez MC", "Loredana"]
        case .italian:
            return ["Sfera Ebbasta", "Måneskin", "Ultimo", "Lazza", "Mahmood"]
        case .portuguese:
            return ["Anitta", "Pedro Sampaio", "Gusttavo Lima", "Luan Santana", "Jão"]
        case .korean:
            return ["BTS", "BLACKPINK", "SEVENTEEN", "NewJeans", "IVE"]
        case .japanese:
            return ["YOASOBI", "Official HIGE DANDism", "Ado", "King Gnu", "LiSA"]
        case .chinese:
            return ["Jay Chou", "JJ Lin", "Eason Chan", "G.E.M.", "Mayday"]
        }
    }
}

// MARK: - SpotifyManager Class
class SpotifyManager: NSObject, ObservableObject {
    @Published var popularArtists: [Artist] = []
    @Published var trendingTracks: [Track] = []
    @Published var searchResults: SearchResults?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedLanguage: Language = .english
    @Published var lastUpdated: Date?
    
    // Authentication properties
    @Published var isAuthenticated = false
    @Published var userAccessToken: String?
    @Published var refreshToken: String?
    @Published var user: SpotifyUser?
    
    private let clientId = SpotifyConfig.clientId
    private let clientSecret = SpotifyConfig.clientSecret
    private let redirectURI = SpotifyConfig.redirectURI
    private var accessToken: String = ""
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var safariViewController: SFSafariViewController?
    
    // Performance optimizations
    private var artistCache: [String: [Artist]] = [:]
    private var trackCache: [String: [Track]] = [:]
    private var cacheExpiry: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    override init() {
        super.init()
        Task {
            await getAccessToken()
        }
        
        // Start automatic updates timer (every 5 minutes)
        startAutoUpdates()
        
        // Listen for Spotify authentication callbacks
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SpotifyAuthCallback"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let code = userInfo["code"] as? String else {
                print("❌ No authorization code in callback")
                return
            }
            
            Task {
                await self?.handleAuthCallback(code: code)
            }
        }
        
        // Load saved authentication state
        if let savedToken = UserDefaults.standard.string(forKey: "spotify_access_token") {
            userAccessToken = savedToken
            isAuthenticated = true
        }
        
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
    
    // MARK: - Authentication Methods
    
    func startAuthentication() async throws {
        print("🎵 SpotifyManager: Starting authentication...")
        
        // URL encode the redirect URI
        let encodedRedirectURI = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
        
        let authURL = "https://accounts.spotify.com/authorize?client_id=\(clientId)&response_type=code&redirect_uri=\(encodedRedirectURI)&scope=user-read-private%20user-read-email%20playlist-read-private%20playlist-read-collaborative%20user-library-read"
        
        print("🎵 Auth URL: \(authURL)")
        
        guard let url = URL(string: authURL) else {
            print("❌ Invalid auth URL")
            throw NSError(domain: "SpotifyAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid auth URL"])
        }
        
        print("🎵 Presenting Safari view controller...")
        await MainActor.run {
            self.safariViewController = SFSafariViewController(url: url)
            self.safariViewController?.delegate = self
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                print("🎵 Found window, presenting Safari...")
                rootViewController.present(self.safariViewController!, animated: true)
            } else {
                print("❌ Could not find window to present Safari")
                // Try alternative approach
                if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                   let rootVC = keyWindow.rootViewController {
                    rootVC.present(self.safariViewController!, animated: true)
                }
            }
        }
    }
    
    func handleAuthCallback(code: String) async {
        do {
            let tokenResponse = try await exchangeCodeForToken(code: code)
            
            await MainActor.run {
                self.userAccessToken = tokenResponse.accessToken
                self.refreshToken = tokenResponse.refreshToken
                self.isAuthenticated = true
                
                // Save tokens to UserDefaults
                UserDefaults.standard.set(tokenResponse.accessToken, forKey: "spotify_access_token")
                UserDefaults.standard.set(tokenResponse.refreshToken, forKey: "spotify_refresh_token")
                
                // Dismiss Safari view controller
                self.safariViewController?.dismiss(animated: true)
                self.safariViewController = nil
            }
            
            // Fetch user profile
            try await fetchUserProfile()
            
        } catch {
            print("❌ Auth callback error: \(error)")
        }
    }
    
    private func exchangeCodeForToken(code: String) async throws -> TokenResponse {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsBase64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(credentialsBase64)", forHTTPHeaderField: "Authorization")
        
        // URL encode the redirect URI for the body
        let encodedRedirectURI = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectURI
        let body = "grant_type=authorization_code&code=\(code)&redirect_uri=\(encodedRedirectURI)"
        request.httpBody = body.data(using: .utf8)
        
        print("🎵 Token exchange request body: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("🎵 Token exchange response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 400 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Token exchange error: \(errorString)")
            throw NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Bad request: \(errorString)"])
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Token exchange failed: \(errorString)")
            throw NSError(domain: "SpotifyAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Token exchange failed: \(errorString)"])
        }
        
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
    
    private func fetchUserProfile() async throws {
        guard let accessToken = userAccessToken else { return }
        
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw NSError(domain: "SpotifyAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user profile"])
        }
        
        let user = try JSONDecoder().decode(SpotifyUser.self, from: data)
        
        await MainActor.run {
            self.user = user
        }
    }
    
    // Map UI language selection to a Spotify market code to bias results
    private func marketForLanguage(_ language: Language) -> String {
        switch language {
        case .english:
            return "US"
        case .hindi, .tamil, .telugu, .kannada, .malayalam, .bengali, .marathi, .gujarati, .punjabi:
            return "IN"
        case .spanish:
            return "ES"
        case .french:
            return "FR"
        case .german:
            return "DE"
        case .italian:
            return "IT"
        case .portuguese:
            return "BR"
        case .korean:
            return "KR"
        case .japanese:
            return "JP"
        case .chinese:
            return "TW" // Spotify not available in mainland China; TW/HK are common
        }
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
        // Check cache first
        let cacheKey = "popular_artists"
        if let cachedArtists = artistCache[cacheKey],
           let expiryDate = cacheExpiry[cacheKey],
           Date() < expiryDate {
            await MainActor.run {
                self.popularArtists = cachedArtists
            }
            print("✅ Using cached popular artists (\(cachedArtists.count) artists)")
            return
        }
        
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
        
        // Reduced list of popular artists for faster loading
        let popularArtistNames = ["Taylor Swift", "Drake", "Ed Sheeran", "Ariana Grande", "The Weeknd", "Billie Eilish"]
        var artists: [Artist] = []
        
        // Fetch artists concurrently for better performance
        await withTaskGroup(of: Artist?.self) { group in
            for artistName in popularArtistNames {
                group.addTask {
                    await self.searchArtist(artistName: artistName)
                }
            }
            
            for await artist in group {
                if let artist = artist {
                    artists.append(artist)
                }
            }
        }
        
        // Cache the results
        artistCache[cacheKey] = artists
        cacheExpiry[cacheKey] = Date().addingTimeInterval(cacheValidityDuration)
        
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
    
    // MARK: - Get Regional Trending Tracks
    func getTrendingTracks(for countryCode: String) async {
        // For now, use the existing trending tracks method
        // In a real implementation, you would modify the API call to include country parameter
        await updateTrendingTracksForLanguage(selectedLanguage)
    }
    
    // MARK: - Update Trending Tracks for Specific Language
    func updateTrendingTracksForLanguage(_ language: Language) async {
        // Check cache first
        let cacheKey = "trending_tracks_\(language.rawValue)"
        if let cachedTracks = trackCache[cacheKey],
           let expiryDate = cacheExpiry[cacheKey],
           Date() < expiryDate {
            await MainActor.run {
                self.trendingTracks = cachedTracks
                self.lastUpdated = Date()
            }
            print("✅ Using cached trending tracks (\(cachedTracks.count) tracks)")
            return
        }
        
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
        
        let market = marketForLanguage(language)
        // Reduced queries for faster loading - only use top 3 queries
        let trendingQueries = Array(language.trendingQueries.prefix(3))
        var tracks: [Track] = []
        var seen = Set<String>()

        // Fetch tracks concurrently for better performance
        await withTaskGroup(of: [Track]?.self) { group in
            for query in trendingQueries {
                group.addTask {
                    await self.searchTracks(query: query, market: market, recentYears: true)
                }
            }
            
            for await searchedTracks in group {
                if let searchedTracks = searchedTracks {
                    for t in searchedTracks {
                        if !seen.contains(t.id) {
                            seen.insert(t.id)
                            tracks.append(t)
                        }
                    }
                }
            }
        }

        // Strict match for non-Latin languages, with top-up from seed artists; never fall back to unfiltered
        func matchesLanguage(_ t: Track, for lang: Language) -> Bool {
            func matchPattern(_ text: String, _ pattern: String) -> Bool {
                return text.range(of: pattern, options: .regularExpression) != nil
            }
            switch lang {
            case .english, .spanish, .french, .german, .italian, .portuguese:
                return true // rely on market for these
            case .hindi, .marathi:
                let p = "[\\u{0900}-\\u{097F}]" // Devanagari
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .bengali:
                let p = "[\\u{0980}-\\u{09FF}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .tamil:
                let p = "[\\u{0B80}-\\u{0BFF}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .telugu:
                let p = "[\\u{0C00}-\\u{0C7F}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .kannada:
                let p = "[\\u{0C80}-\\u{0CFF}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .malayalam:
                let p = "[\\u{0D00}-\\u{0D7F}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .gujarati:
                let p = "[\\u{0A80}-\\u{0AFF}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .punjabi:
                let p = "[\\u{0A00}-\\u{0A7F}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .korean:
                let p = "[\\u{1100}-\\u{11FF}\\u{3130}-\\u{318F}\\u{AC00}-\\u{D7AF}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .japanese:
                let p = "[\\u{3040}-\\u{309F}\\u{30A0}-\\u{30FF}\\u{4E00}-\\u{9FFF}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            case .chinese:
                let p = "[\\u{4E00}-\\u{9FFF}]"
                return matchPattern(t.name, p) || matchPattern(t.album.name, p) || t.artists.contains { matchPattern($0.name, p) }
            }
        }

        let deduped = tracks

        // Start with strictly matching items or tracks by seed artists for the language
        let seedSet = Set(language.seedArtists.map { $0.lowercased() })
        func hasSeedArtist(_ t: Track) -> Bool { t.artists.contains { seedSet.contains($0.name.lowercased()) } }

        var strict: [Track] = deduped.filter { matchesLanguage($0, for: language) || hasSeedArtist($0) }

        // Top-up from seed artists until we reach up to 20 items (still constrained by language/seed)
        if strict.count < 20 {
            for name in language.seedArtists {
                if let more = await searchTracks(query: "artist:\(name)", market: market, recentYears: true) {
                    for t in more {
                        if !seen.contains(t.id) {
                            seen.insert(t.id)
                            if matchesLanguage(t, for: language) || hasSeedArtist(t) {
                                strict.append(t)
                                if strict.count >= 20 { break }
                            }
                        }
                    }
                }
                if strict.count >= 20 { break }
            }
        }

        // Use the strict list only (no fallback to unfiltered results)
        tracks = strict

        // Sort by popularity (desc) and cap to 15 for faster loading
        tracks.sort { ( ($0.popularity ?? 0) > ($1.popularity ?? 0) ) }
        let finalTracks = Array(tracks.prefix(15)) // Reduced from 20 to 15
        
        // Cache the results
        trackCache[cacheKey] = finalTracks
        cacheExpiry[cacheKey] = Date().addingTimeInterval(cacheValidityDuration)
        
        await MainActor.run {
            self.trendingTracks = finalTracks
            self.isLoading = false
            self.lastUpdated = Date()
            print("✅ Loaded \(finalTracks.count) \(language.displayName) trending tracks")
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
            let market = marketForLanguage(self.selectedLanguage)
            let urlString = "https://api.spotify.com/v1/search?q=\(searchQuery)&type=artist,track&limit=20&market=\(market)"
            
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
    
    // MARK: - Internal Search Method (for RedditManager integration)
    func searchSpotifyInternal(query: String) async -> SearchResults? {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        guard !accessToken.isEmpty else {
            print("⚠️ Access token not available for internal search")
            return nil
        }
        
        do {
            let searchQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let market = marketForLanguage(self.selectedLanguage)
            let urlString = "https://api.spotify.com/v1/search?q=\(searchQuery)&type=track&limit=10&market=\(market)"
            
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
            
            let searchResponse = try JSONDecoder().decode(TracksSearchResponse.self, from: data)
            
            return SearchResults(
                artists: [],
                tracks: searchResponse.tracks.items
            )
            
        } catch {
            print("❌ Internal search failed for '\(query)': \(error)")
            return nil
        }
    }
    
    private func searchArtist(artistName: String) async -> Artist? {
        let market = marketForLanguage(self.selectedLanguage)
        let searchURL = "https://api.spotify.com/v1/search?q=\(artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=artist&limit=1&market=\(market)"
        
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
    
    private func searchTracks(query: String, market: String, recentYears: Bool = false) async -> [Track]? {
        let marketParam = market.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? market
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearFilter = recentYears ? " year:\(currentYear-2)-\(currentYear)" : ""
        let rawQuery = query + yearFilter
        let encodedQuery = rawQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let searchURL = "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track&limit=10&market=\(marketParam)"
        
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

// MARK: - SFSafariViewControllerDelegate
extension SpotifyManager: SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        // Handle initial load completion if needed
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // Handle when user cancels or finishes authentication
        controller.dismiss(animated: true)
    }
}

// MARK: - Authentication Data Models
struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

struct SpotifyUser: Codable {
    let id: String
    let displayName: String?
    let email: String?
    let images: [SpotifyImage]?
    let followers: Followers?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case images
        case followers
    }
}

// MARK: - URL Extension
extension URL {
    var queryParameters: [String: String] {
        var params: [String: String] = [:]
        if let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                params[item.name] = item.value
            }
        }
        return params
    }
}

