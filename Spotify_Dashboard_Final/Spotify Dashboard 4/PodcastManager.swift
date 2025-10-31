//
//  PodcastManager.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import SwiftUI
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - ListenNotes API Configuration
struct ListenNotesConfig {
    static let apiKey = "01a373623ec64904aa5a3fe2297722fc"
    static let baseURL = "https://listen-api.listennotes.com/api/v2"
}

// MARK: - Podcast Models

struct Podcast: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let publisher: String
    let image: String?
    let thumbnail: String?
    let totalEpisodes: Int
    let explicitContent: Bool
    let language: String
    let country: String
    let website: String?
    let isClaimed: Bool
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case publisher
        case image
        case thumbnail
        case totalEpisodes
        case explicitContent
        case language
        case country
        case website
        case isClaimed
        case email
    }
}

struct PodcastEpisode: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let audio: String
    let audioLengthSec: Int
    let image: String?
    let thumbnail: String?
    let pubDateMs: Int64
    let explicitContent: Bool
    
    var audioURL: URL? {
        URL(string: audio)
    }
    
    var duration: String {
        let minutes = audioLengthSec / 60
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}

struct PodcastEpisodesResponse: Codable {
    let episodes: [PodcastEpisode]
}

struct PodcastSearchResponse: Codable {
    let total: Int
    let count: Int
    let nextOffset: Int?
    let took: Double
    let results: [PodcastResult]
    
    enum CodingKeys: String, CodingKey {
        case total
        case count
        case nextOffset = "next_offset"
        case took
        case results
    }
}

struct PodcastResult: Identifiable, Codable {
    let id: String
    let titleOriginal: String
    let descriptionOriginal: String
    let publisherOriginal: String
    let image: String
    let thumbnail: String
    let totalEpisodes: Int
    let explicitContent: Bool
    let website: String?
}

// MARK: - Podcast Manager

@MainActor
class PodcastManager: ObservableObject {
    @Published var podcasts: [Podcast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSearching = false
    @Published var searchQuery = ""
    @Published var selectedMood: String = "Calm"
    @Published var aiRecommendationReason: String = ""
    
    private let availableMoods = [
        "Calm", "Inspired", "Sad", "Curious", "Anxious", 
        "Happy", "Reflective", "Excited", "Nostalgic", "Focused"
    ]
    
    // Mood to keyword mapping - Using simple, proven keywords
    private let moodToKeyword: [String: String] = [
        "calm": "relaxation",
        "inspired": "motivation",
        "sad": "self improvement",
        "curious": "storytelling",
        "anxious": "mindfulness",
        "happy": "comedy",
        "reflective": "philosophy",
        "excited": "adventure",
        "nostalgic": "history",
        "focused": "productivity"
    ]
    
    // MARK: - Detect Mood from Text using Foundation Models
    
    func detectMood(from diaryText: String) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return await detectMoodWithFoundationModels(from: diaryText)
        } else {
            return detectMoodWithBasicLogic(from: diaryText)
        }
        #else
        return detectMoodWithBasicLogic(from: diaryText)
        #endif
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func detectMoodWithFoundationModels(from diaryText: String) async -> String {
        do {
            let session = LanguageModelSession()
            
            let prompt = """
            Analyze this diary entry and determine the mood/emotional state. Respond with just ONE word from this list: Calm, Inspired, Sad, Curious, Anxious, Happy, Reflective, Excited, Nostalgic, Focused
            
            Diary Entry:
            \(diaryText)
            
            Analyze the emotional tone and respond with only the mood word:
            """
            
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 0.7,
                    maximumResponseTokens: nil
                )
            )
            
            let detectedMood = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return availableMoods.contains(detectedMood) ? detectedMood : "Calm"
            
        } catch {
            print("❌ Foundation Models error: \(error)")
            return detectMoodWithBasicLogic(from: diaryText)
        }
    }
    #endif
    
    private func detectMoodWithBasicLogic(from diaryText: String) -> String {
        let lowerText = diaryText.lowercased()
        
        if lowerText.contains("miss") || lowerText.contains("old days") || lowerText.contains("remember") {
            return "Nostalgic"
        }
        if lowerText.contains("excited") || lowerText.contains("can't wait") {
            return "Excited"
        }
        if lowerText.contains("why") || lowerText.contains("how") || lowerText.contains("wonder") {
            return "Curious"
        }
        if lowerText.contains("stress") || lowerText.contains("worried") || lowerText.contains("anxious") {
            return "Anxious"
        }
        if lowerText.contains("happy") || lowerText.contains("joy") || lowerText.contains("smile") {
            return "Happy"
        }
        if lowerText.contains("inspired") || lowerText.contains("motivated") || lowerText.contains("encouraged") {
            return "Inspired"
        }
        if lowerText.contains("calm") || lowerText.contains("peaceful") || lowerText.contains("relaxed") {
            return "Calm"
        }
        if lowerText.contains("sad") || lowerText.contains("upset") || lowerText.contains("disappointed") {
            return "Sad"
        }
        if lowerText.contains("reflect") || lowerText.contains("think") || lowerText.contains("contemplate") {
            return "Reflective"
        }
        
        return "Calm"
    }
    
    // MARK: - Get Podcast Keyword
    
    func getKeyword(for mood: String) -> String {
        let lowerMood = mood.lowercased()
        return moodToKeyword[lowerMood] ?? "motivation"
    }
    
    // MARK: - Search Podcasts by Mood
    
    func searchPodcastsByMood(_ mood: String) async {
        print("🔍 Searching podcasts for mood: \(mood)")
        let lowerMood = mood.lowercased()
        print("🔍 Lowercase mood: \(lowerMood)")
        
        guard let keyword = moodToKeyword[lowerMood] ?? moodToKeyword["calm"] else {
            print("❌ No keyword found for mood: \(mood)")
            errorMessage = "Unable to find podcasts for this mood"
            return
        }
        
        print("✅ Using keyword: \(keyword)")
        await searchPodcasts(query: keyword, searchType: "podcast", sortByDate: 0)
    }
    
    // MARK: - Search Podcasts
    
    func searchPodcasts(query: String, searchType: String = "podcast", sortByDate: Int = 0, pageNumber: Int = 0) async {
        guard !query.isEmpty else {
            errorMessage = "Please enter a search term"
            return
        }
        
        // Clear previous results
        podcasts = []
        isLoading = true
        errorMessage = nil
        isSearching = true
        
        // Build URL
        var urlComponents = URLComponents(string: "\(ListenNotesConfig.baseURL)/search")!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: searchType),
            URLQueryItem(name: "sort_by_date", value: String(sortByDate)),
            URLQueryItem(name: "page", value: String(pageNumber))
        ]
        
        guard let url = urlComponents.url else {
            errorMessage = "Invalid URL"
            isLoading = false
            isSearching = false
            return
        }
        
            print("🌐 Calling URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(ListenNotesConfig.apiKey, forHTTPHeaderField: "X-ListenAPI-Key")
        
        print("🔑 API Key: \(ListenNotesConfig.apiKey.prefix(10))...")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("📡 Received \(data.count) bytes of data")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("📊 HTTP Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 {
                    errorMessage = "Rate limit exceeded. Please try again later."
                } else if httpResponse.statusCode == 401 {
                    errorMessage = "Authentication failed. Check API key."
                } else {
                    errorMessage = "Search failed: HTTP \(httpResponse.statusCode)"
                }
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorData)")
                }
                isLoading = false
                isSearching = false
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            print("📦 Parsing JSON response...")
            let searchResponse = try decoder.decode(PodcastSearchResponse.self, from: data)
            
            print("✅ Decoded response: total=\(searchResponse.total), count=\(searchResponse.count), results=\(searchResponse.results.count)")
            
            // Convert PodcastResult to Podcast
            self.podcasts = searchResponse.results.map { result in
                Podcast(
                    id: result.id,
                    title: cleanUpgradeText(result.titleOriginal),
                    description: cleanUpgradeText(result.descriptionOriginal),
                    publisher: cleanUpgradeText(result.publisherOriginal),
                    image: result.image,
                    thumbnail: result.thumbnail,
                    totalEpisodes: result.totalEpisodes,
                    explicitContent: result.explicitContent,
                    language: "en",
                    country: "US",
                    website: result.website.map(cleanUpgradeText),
                    isClaimed: false,
                    email: nil
                )
            }
            
            isLoading = false
            isSearching = false
            
            print("✅ Found \(self.podcasts.count) podcasts")
            if self.podcasts.isEmpty {
                print("⚠️ No podcasts found! Response data: \(String(data: data.prefix(200), encoding: .utf8) ?? "nil")")
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Missing key '\(key)' in \(context)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type \(type) in \(context)")
            case .valueNotFound(let type, let context):
                print("Value not found for type \(type) in \(context)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context)")
            @unknown default:
                print("Unknown decoding error")
            }
            errorMessage = "Failed to parse podcast results: \(decodingError.localizedDescription)"
            isLoading = false
            isSearching = false
        } catch {
            print("❌ Error searching podcasts: \(error)")
            errorMessage = "Failed to search podcasts: \(error.localizedDescription)"
            isLoading = false
            isSearching = false
        }
    }
    
    // MARK: - Fetch Episodes for a Podcast
    
    @Published var episodes: [PodcastEpisode] = []
    @Published var isLoadingEpisodes = false
    
    func fetchEpisodes(for podcastId: String) async {
        isLoadingEpisodes = true
        errorMessage = nil
        
        let urlString = "\(ListenNotesConfig.baseURL)/podcasts/\(podcastId)"
        
        print("📡 Fetching episodes for podcast: \(podcastId)")
        print("🌐 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoadingEpisodes = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(ListenNotesConfig.apiKey, forHTTPHeaderField: "X-ListenAPI-Key")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("📦 Received \(data.count) bytes of episode data")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("📊 HTTP Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 429 {
                    errorMessage = "Rate limit exceeded. Please try again later."
                } else if httpResponse.statusCode == 401 {
                    errorMessage = "Authentication failed. Check API key."
                } else {
                    errorMessage = "Failed to fetch episodes: HTTP \(httpResponse.statusCode)"
                }
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorData.prefix(500))")
                }
                isLoadingEpisodes = false
                return
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            struct PodcastDetailResponse: Codable {
                let id: String
                let title: String
                let episodes: [PodcastEpisode]
            }
            
            let detailResponse = try decoder.decode(PodcastDetailResponse.self, from: data)
            self.episodes = detailResponse.episodes
            isLoadingEpisodes = false
            
            print("✅ Fetched \(self.episodes.count) episodes for podcast: \(detailResponse.title)")
            
        } catch let decodingError as DecodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Missing key '\(key)' in \(context)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for type \(type) in \(context)")
            case .valueNotFound(let type, let context):
                print("Value not found for type \(type) in \(context)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context)")
            @unknown default:
                print("Unknown decoding error")
            }
            errorMessage = "Failed to parse episodes: \(decodingError.localizedDescription)"
            isLoadingEpisodes = false
        } catch {
            print("❌ Error fetching episodes: \(error)")
            errorMessage = "Failed to fetch episodes: \(error.localizedDescription)"
            isLoadingEpisodes = false
        }
    }
    
    // MARK: - Get AI Recommendation Reason
    
    func getAIRecommendationReason(podcast: Podcast, for mood: String, diaryText: String?) async {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), let diaryText = diaryText {
            await getAIReasonWithFoundationModels(podcast: podcast, mood: mood, diaryText: diaryText)
        } else {
            aiRecommendationReason = generateBasicReason(podcast: podcast, mood: mood)
        }
        #else
        aiRecommendationReason = generateBasicReason(podcast: podcast, mood: mood)
        #endif
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func getAIReasonWithFoundationModels(podcast: Podcast, mood: String, diaryText: String) async {
        do {
            let session = LanguageModelSession()
            
            let prompt = """
            Explain why this podcast is perfect for someone feeling \(mood) right now.
            
            Podcast: \(podcast.title)
            Description: \(podcast.description)
            Publisher: \(podcast.publisher)
            
            User's Diary: \(diaryText)
            
            Write a brief, encouraging explanation (2-3 sentences) connecting the podcast to their current mood and emotional state.
            """
            
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 0.8,
                    maximumResponseTokens: 150
                )
            )
            
            aiRecommendationReason = response.content
            
        } catch {
            print("❌ AI reason generation error: \(error)")
            aiRecommendationReason = generateBasicReason(podcast: podcast, mood: mood)
        }
    }
    #endif
    
    private func generateBasicReason(podcast: Podcast, mood: String) -> String {
        let publisherName = podcast.publisher
        let episodes = podcast.totalEpisodes
        
        if mood.lowercased() == "calm" {
            return "Perfect for finding peace and relaxation. \(podcast.title) by \(publisherName) offers \(episodes) episodes to help you unwind and destress."
        } else if mood.lowercased() == "inspired" || mood.lowercased() == "excited" {
            return "Great for sparking creativity and motivation. \(podcast.title) will energize you and help you reach your goals."
        } else if mood.lowercased() == "curious" {
            return "Ideal for curious minds. \(podcast.title) explores fascinating topics that will satisfy your thirst for knowledge."
        } else if mood.lowercased() == "reflective" || mood.lowercased() == "nostalgic" {
            return "Perfect for thoughtful moments. \(podcast.title) by \(publisherName) offers deep insights and meaningful stories."
        } else {
            return "This podcast matches your current mood perfectly. \(podcast.title) has \(episodes) episodes ready to listen to."
        }
    }
    
    // MARK: - Clear Results
    
    func clearResults() {
        podcasts = []
        errorMessage = nil
        searchQuery = ""
        aiRecommendationReason = ""
    }
    
    // Helper function to clean "Please upgrade" text
    private func cleanUpgradeText(_ text: String) -> String {
        // If the text contains the upgrade message, return a default value
        if text.contains("Please upgrade") {
            return "Podcast Info"
        }
        return text
    }
}

// MARK: - Podcast Manager Extension for Mood-Adaptive Search

extension PodcastManager {
    
    /// Search podcasts based on latest mood diary entry
    func searchBasedOnLatestMood(from entries: [MoodEntry]) async {
        guard let latestEntry = entries.first else {
            await searchPodcastsByMood(selectedMood)
            return
        }
        
        // Detect mood from diary entry
        let detectedMood = await detectMood(from: latestEntry.notes)
        selectedMood = detectedMood
        
        await searchPodcastsByMood(detectedMood)
    }
}

