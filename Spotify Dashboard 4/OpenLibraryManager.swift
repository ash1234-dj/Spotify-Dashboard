//
//  OpenLibraryManager.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import Combine

// MARK: - Open Library Data Models

struct AuthorSearchResponse: Codable {
    let numFound: Int
    let start: Int
    let docs: [AuthorSearchResult]
}

struct AuthorSearchResult: Codable, Identifiable {
    let id: String
    let key: String
    let name: String
    let birthDate: String?
    let deathDate: String?
    let topWork: String?
    let workCount: Int?
    let topSubjects: [String]?
    let alternateNames: [String]?
    
    enum CodingKeys: String, CodingKey {
        case key, name
        case birthDate = "birth_date"
        case deathDate = "death_date"
        case topWork = "top_work"
        case workCount = "work_count"
        case topSubjects = "top_subjects"
        case alternateNames = "alternate_names"
    }
    
    // Custom initializer for fallback data
    init(id: String, key: String, name: String, birthDate: String?, deathDate: String?, topWork: String?, workCount: Int?, topSubjects: [String]?, alternateNames: [String]?) {
        self.id = id
        self.key = key
        self.name = name
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.topWork = topWork
        self.workCount = workCount
        self.topSubjects = topSubjects
        self.alternateNames = alternateNames
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.key = try container.decode(String.self, forKey: .key)
        self.id = key.replacingOccurrences(of: "/authors/", with: "")
        self.name = try container.decode(String.self, forKey: .name)
        self.birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate)
        self.deathDate = try container.decodeIfPresent(String.self, forKey: .deathDate)
        self.topWork = try container.decodeIfPresent(String.self, forKey: .topWork)
        self.workCount = try container.decodeIfPresent(Int.self, forKey: .workCount)
        self.topSubjects = try container.decodeIfPresent([String].self, forKey: .topSubjects)
        self.alternateNames = try container.decodeIfPresent([String].self, forKey: .alternateNames)
    }
}

struct AuthorDetail: Codable, Identifiable {
    let id: String
    let name: String
    let personalName: String?
    let birthDate: String?
    let deathDate: String?
    let bio: String?
    let photos: [Int]?
    let authorWorks: [AuthorWork]?
    
    enum CodingKeys: String, CodingKey {
        case name, bio, photos
        case personalName = "personal_name"
        case birthDate = "birth_date"
        case deathDate = "death_date"
        case authorWorks = "works"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Extract ID from the key field
        let keyContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        if let keyString = try? keyContainer.decode(String.self, forKey: DynamicCodingKey(stringValue: "key")!) {
            self.id = keyString.replacingOccurrences(of: "/authors/", with: "")
        } else {
            self.id = UUID().uuidString
        }
        
        self.name = try container.decode(String.self, forKey: .name)
        self.personalName = try container.decodeIfPresent(String.self, forKey: .personalName)
        self.birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate)
        self.deathDate = try container.decodeIfPresent(String.self, forKey: .deathDate)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.photos = try container.decodeIfPresent([Int].self, forKey: .photos)
        self.authorWorks = try container.decodeIfPresent([AuthorWork].self, forKey: .authorWorks)
    }
}

struct AuthorWork: Codable, Identifiable {
    let id: String
    let title: String
    let key: String
    
    enum CodingKeys: String, CodingKey {
        case title, key
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.key = try container.decode(String.self, forKey: .key)
        self.id = key.replacingOccurrences(of: "/works/", with: "")
        self.title = try container.decode(String.self, forKey: .title)
    }
}

struct WorksResponse: Codable {
    let entries: [AuthorWork]
}

// MARK: - Dynamic Coding Key for flexible JSON parsing

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
}

// MARK: - Open Library Manager

class OpenLibraryManager: ObservableObject {
    @Published var searchResults: [AuthorSearchResult] = []
    @Published var famousAuthorResults: [AuthorSearchResult] = []
    @Published var authorDetails: [String: AuthorDetail] = [:]
    @Published var authorWorks: [String: [AuthorWork]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://openlibrary.org"
    
    // MARK: - Famous Authors by Default
    
    let famousAuthors = [
        "Jane Austen",
        "Charles Dickens", 
        "Mark Twain",
        "Ernest Hemingway",
        "Virginia Woolf",
        "F. Scott Fitzgerald",
        "George Orwell",
        "Agatha Christie",
        "J.R.R. Tolkien",
        "Harper Lee",
        "Oscar Wilde",
        "Edgar Allan Poe",
        "William Shakespeare",
        "Emily Dickinson",
        "Maya Angelou",
        "Toni Morrison",
        "Gabriel García Márquez",
        "Leo Tolstoy",
        "Anton Chekhov",
        "Charlotte Brontë",
        "Emily Brontë",
        "Mary Shelley",
        "Herman Melville",
        "Kurt Vonnegut",
        "C.S. Lewis",
        "Fyodor Dostoevsky",
        "Franz Kafka",
        "James Joyce",
        "Marcel Proust",
        "Albert Camus",
        "Jean-Paul Sartre",
        "Simone de Beauvoir",
        "Chinua Achebe",
        "Salman Rushdie",
        "Margaret Atwood",
        "Ursula K. Le Guin",
        "Isaac Asimov",
        "Ray Bradbury",
        "Arthur C. Clarke",
        "Philip K. Dick",
        "H.G. Wells",
        "Jules Verne",
        "Robert Louis Stevenson",
        "Rudyard Kipling",
        "Lewis Carroll",
        "Beatrix Potter",
        "Roald Dahl",
        "Dr. Seuss",
        "Maurice Sendak"
    ]
    
    // MARK: - Search Authors
    
    func searchAuthors(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🔍 Searching Open Library for author: '\(query)'")
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(baseURL)/search/authors.json?q=\(encodedQuery)&limit=15" // Reduced for faster loading
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.errorMessage = "Invalid search URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenLibraryError.networkError
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw OpenLibraryError.httpError(httpResponse.statusCode)
            }
            
            let searchResponse = try JSONDecoder().decode(AuthorSearchResponse.self, from: data)
            
            // Show all authors with works, but we'll check data completeness in the UI
            let authorsWithWorks = searchResponse.docs.filter { $0.workCount ?? 0 > 0 }
            
            await MainActor.run {
                self.searchResults = authorsWithWorks
                self.isLoading = false
                print("✅ Search completed: \(authorsWithWorks.count) authors found (all authors with works)")
            }
            
        } catch {
            print("❌ Author search error: \(error)")
            await MainActor.run {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Get Author Details
    
    func getAuthorDetails(authorId: String) async -> AuthorDetail? {
        // Check if we already have the details
        if let existingDetails = authorDetails[authorId] {
            return existingDetails
        }
        
        print("📚 Fetching author details for ID: \(authorId)")
        
        let urlString = "\(baseURL)/authors/\(authorId).json"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid author details URL")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenLibraryError.networkError
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw OpenLibraryError.httpError(httpResponse.statusCode)
            }
            
            let authorDetail = try JSONDecoder().decode(AuthorDetail.self, from: data)
            
            await MainActor.run {
                self.authorDetails[authorId] = authorDetail
            }
            
            print("✅ Loaded author details for: \(authorDetail.name)")
            return authorDetail
            
        } catch {
            print("❌ Failed to fetch author details: \(error)")
            return nil
        }
    }
    
    // MARK: - Get Author Works
    
    func getAuthorWorks(authorId: String) async -> [AuthorWork] {
        // Check if we already have the works
        if let existingWorks = authorWorks[authorId] {
            return existingWorks
        }
        
        print("📖 Fetching works for author ID: \(authorId)")
        
        let urlString = "\(baseURL)/authors/\(authorId)/works.json?limit=100"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid author works URL")
            return []
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenLibraryError.networkError
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw OpenLibraryError.httpError(httpResponse.statusCode)
            }
            
            let worksResponse = try JSONDecoder().decode(WorksResponse.self, from: data)
            
            await MainActor.run {
                self.authorWorks[authorId] = worksResponse.entries
            }
            
            print("✅ Loaded \(worksResponse.entries.count) works for author")
            return worksResponse.entries
            
        } catch {
            print("❌ Failed to fetch author works: \(error)")
            return []
        }
    }
    
    // MARK: - Load Famous Authors
    
    func loadFamousAuthors() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🌟 Loading famous authors (simplified approach)...")
        print("🌟 Base URL: \(baseURL)")
        print("🌟 Famous authors count: \(famousAuthors.count)")
        
        var famousAuthorResults: [AuthorSearchResult] = []
        
        // Process first 20 authors sequentially for reliable loading
        let authorsToProcess = Array(famousAuthors.prefix(20))
        print("🚀 Processing first \(authorsToProcess.count) authors sequentially")
        
        for (index, authorName) in authorsToProcess.enumerated() {
            print("📝 Processing author \(index + 1)/\(authorsToProcess.count): \(authorName)")
            
            do {
                let encodedQuery = authorName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? authorName
                let urlString = "\(baseURL)/search/authors.json?q=\(encodedQuery)&limit=1"
                
                guard let url = URL(string: urlString) else { 
                    print("❌ Invalid URL for \(authorName)")
                    continue
                }
                
                print("🌐 Making request to: \(urlString)")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response for \(authorName)")
                    continue
                }
                
                print("📡 Response status: \(httpResponse.statusCode)")
                
                guard 200...299 ~= httpResponse.statusCode else { 
                    print("❌ HTTP error for \(authorName): \(httpResponse.statusCode)")
                    continue
                }
                
                let searchResponse = try JSONDecoder().decode(AuthorSearchResponse.self, from: data)
                print("📊 Found \(searchResponse.docs.count) docs for \(authorName)")
                
                if let author = searchResponse.docs.first {
                    if (author.workCount ?? 0) > 0 {
                        // Include all authors with works - validate biographies when user taps
                        famousAuthorResults.append(author)
                        print("✅ Added author: \(author.name) (\(author.workCount ?? 0) works) - Total: \(famousAuthorResults.count)")
                        
                        // Update UI progressively for faster loading
                        await MainActor.run {
                            self.famousAuthorResults = famousAuthorResults
                            if famousAuthorResults.count >= 3 && self.isLoading {
                                print("🎯 Showing first 3 authors, continuing to load...")
                                self.isLoading = false
                            }
                        }
                    } else {
                        print("⚠️ Skipped \(authorName) - no works found (workCount: \(author.workCount ?? 0))")
                    }
                } else {
                    print("⚠️ No author found in response for \(authorName)")
                }
                
            } catch {
                print("❌ Failed to load \(authorName): \(error)")
            }
        }
        
        await MainActor.run {
            self.famousAuthorResults = famousAuthorResults
            self.isLoading = false
            print("✅ Loaded \(famousAuthorResults.count) famous authors")
            print("📊 Final results: \(famousAuthorResults.map { $0.name })")
            
            if famousAuthorResults.isEmpty {
                print("❌ No authors found - using fallback data")
                // Use fallback data when API is not available
                self.loadFallbackAuthors()
            } else {
                print("🎉 Successfully loaded \(famousAuthorResults.count) authors!")
            }
        }
    }
    
    // MARK: - Fallback Authors (when API is not available)
    
    private func loadFallbackAuthors() {
        print("🔄 Loading fallback authors...")
        
        let fallbackAuthors: [AuthorSearchResult] = [
            AuthorSearchResult(
                id: "OL21594A",
                key: "/authors/OL21594A",
                name: "Jane Austen",
                birthDate: "December 16, 1775",
                deathDate: "July 18, 1817",
                topWork: "Pride and Prejudice",
                workCount: 2211,
                topSubjects: ["Fiction", "English literature", "England, fiction"],
                alternateNames: ["Austen Jane", "Austen", "J. Austen"]
            ),
            AuthorSearchResult(
                id: "OL18319A",
                key: "/authors/OL18319A",
                name: "Charles Dickens",
                birthDate: "February 7, 1812",
                deathDate: "June 9, 1870",
                topWork: "A Christmas Carol",
                workCount: 5428,
                topSubjects: ["Fiction", "19th century", "England"],
                alternateNames: ["Dickens Charles", "Dickens", "C. Dickens"]
            ),
            AuthorSearchResult(
                id: "OL18320A",
                key: "/authors/OL18320A",
                name: "Mark Twain",
                birthDate: "November 30, 1835",
                deathDate: "April 21, 1910",
                topWork: "The Adventures of Tom Sawyer",
                workCount: 47,
                topSubjects: ["Fiction", "American literature", "Humor"],
                alternateNames: ["Twain Mark", "Clemens Samuel", "S. Clemens"]
            ),
            AuthorSearchResult(
                id: "OL18321A",
                key: "/authors/OL18321A",
                name: "Ernest Hemingway",
                birthDate: "July 21, 1899",
                deathDate: "July 2, 1961",
                topWork: "The Old Man and the Sea",
                workCount: 1126,
                topSubjects: ["Fiction", "American literature", "War"],
                alternateNames: ["Hemingway Ernest", "Hemingway", "E. Hemingway"]
            ),
            AuthorSearchResult(
                id: "OL18322A",
                key: "/authors/OL18322A",
                name: "F. Scott Fitzgerald",
                birthDate: "September 24, 1896",
                deathDate: "December 21, 1940",
                topWork: "The Great Gatsby",
                workCount: 1273,
                topSubjects: ["Fiction", "American literature", "Jazz Age"],
                alternateNames: ["Fitzgerald F. Scott", "Fitzgerald", "F. S. Fitzgerald"]
            ),
            AuthorSearchResult(
                id: "OL18323A",
                key: "/authors/OL18323A",
                name: "Virginia Woolf",
                birthDate: "January 25, 1882",
                deathDate: "March 28, 1941",
                topWork: "Mrs. Dalloway",
                workCount: 892,
                topSubjects: ["Fiction", "English literature", "Modernism"],
                alternateNames: ["Woolf Virginia", "Woolf", "V. Woolf"]
            ),
            AuthorSearchResult(
                id: "OL18324A",
                key: "/authors/OL18324A",
                name: "George Orwell",
                birthDate: "June 25, 1903",
                deathDate: "January 21, 1950",
                topWork: "1984",
                workCount: 1567,
                topSubjects: ["Fiction", "English literature", "Dystopian"],
                alternateNames: ["Orwell George", "Blair Eric", "E. Blair"]
            ),
            AuthorSearchResult(
                id: "OL18325A",
                key: "/authors/OL18325A",
                name: "Agatha Christie",
                birthDate: "September 15, 1890",
                deathDate: "January 12, 1976",
                topWork: "Murder on the Orient Express",
                workCount: 2134,
                topSubjects: ["Fiction", "Mystery", "Detective"],
                alternateNames: ["Christie Agatha", "Christie", "A. Christie"]
            )
        ]
        
        self.famousAuthorResults = fallbackAuthors
        print("✅ Loaded \(fallbackAuthors.count) fallback authors")
    }
    
    // MARK: - Helper Methods
    
    func getAuthorPhotoURL(photoId: Int) -> String {
        return "https://covers.openlibrary.org/a/id/\(photoId)-M.jpg"
    }
    
    func extractAuthorId(from key: String) -> String {
        return key.replacingOccurrences(of: "/authors/", with: "")
    }
    
    // MARK: - Data Completeness Check
    
    func hasCompleteData(for author: AuthorSearchResult) async -> Bool {
        let authorId = extractAuthorId(from: author.key)
        
        async let authorDetails = getAuthorDetails(authorId: authorId)
        async let authorWorks = getAuthorWorks(authorId: authorId)
        
        let (details, works) = await (authorDetails, authorWorks)
        
        return details?.bio?.isEmpty == false && !works.isEmpty
    }
    
    // MARK: - Timeout Helper
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            
            guard let result = try await group.next() else {
                throw URLError(.timedOut)
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Error Types

enum OpenLibraryError: Error {
    case invalidURL
    case networkError
    case httpError(Int)
    case decodingError
}
