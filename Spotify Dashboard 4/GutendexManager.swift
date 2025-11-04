//
//  GutendexManager.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import Combine

// MARK: - Reading Mood Enum

enum ReadingMood: String, CaseIterable {
    case all = "All"
    case adventure = "Adventure"
    case romance = "Romance"
    case mystery = "Mystery"
    case horror = "Horror"
    case fantasy = "Fantasy"
    case sciFi = "Sci-Fi"
    case comedy = "Comedy"
    case drama = "Drama"
    case philosophy = "Philosophy"
    
    var icon: String {
        switch self {
        case .all: return "book.fill"
        case .adventure: return "map.fill"
        case .romance: return "heart.fill"
        case .mystery: return "questionmark.circle.fill"
        case .horror: return "moon.fill"
        case .fantasy: return "sparkles"
        case .sciFi: return "atom"
        case .comedy: return "face.smiling.fill"
        case .drama: return "theatermasks.fill"
        case .philosophy: return "brain.head.profile"
        }
    }
    
    var searchKeywords: [String] {
        switch self {
        case .all: return []
        case .adventure: return ["adventure", "journey", "exploration", "quest", "travel"]
        case .romance: return ["romance", "love story", "romantic", "marriage", "courtship", "passion", "wedding", "relationship", "affection", "romantic fiction"]
        case .mystery: return ["mystery", "detective", "crime", "murder", "investigation"]
        case .horror: return ["horror", "ghost", "monster", "terror", "fear", "supernatural"]
        case .fantasy: return ["fantasy", "magic", "fairy", "wizard", "dragon", "enchanted"]
        case .sciFi: return ["science fiction", "space", "future", "robot", "alien", "technology"]
        case .comedy: return ["comedy", "humor", "funny", "wit", "satire", "joke"]
        case .drama: return ["drama", "tragedy", "serious", "emotional", "conflict"]
        case .philosophy: return ["philosophy", "wisdom", "ethics", "morality", "thought", "reasoning"]
        }
    }
}

// MARK: - Gutendex Data Models

struct GutendexResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [GutendexBook]
}

struct GutendexBook: Codable, Identifiable {
    let id: Int
    let title: String
    let authors: [GutendexAuthor]
    let translators: [GutendexAuthor]
    let subjects: [String]
    let bookshelves: [String]
    let languages: [String]
    let copyright: Bool?
    let media_type: String
    let formats: [String: String]
    let download_count: Int
    
    var primaryAuthor: String {
        authors.first?.name ?? "Unknown Author"
    }
    
    var textURL: String? {
        // Use direct Gutenberg URL for reliable plain text
        return "https://www.gutenberg.org/cache/epub/\(id)/pg\(id).txt"
    }
}

struct GutendexAuthor: Codable {
    let name: String
    let birth_year: Int?
    let death_year: Int?
}

// MARK: - Book Content Model

struct BookContent: Identifiable {
    let id: String
    let title: String
    let author: String
    let text: String
    let downloadCount: Int
    let languages: [String]
    let subjects: [String]
    let fetchedAt: Date
    
    var wordCount: Int {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    
    var estimatedReadingTime: Int {
        // Average reading speed: 200 words per minute
        max(1, wordCount / 200)
    }
}

// MARK: - Gutendex Manager

class GutendexManager: ObservableObject {
    @Published var searchResults: [GutendexBook] = []
    @Published var bookContent: BookContent?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recentBooks: [GutendexBook] = [] // User's recently viewed books
    @Published var popularBooks: [GutendexBook] = [] // Most downloaded books
    @Published var allBooks: [GutendexBook] = [] // All/trending books
    @Published var gutendexRecentBooks: [GutendexBook] = [] // Recently added to Gutendex
    @Published var moodFilteredBooks: [GutendexBook] = [] // Books filtered by mood
    @Published var selectedMood: ReadingMood = .all // Currently selected mood
    
    // MARK: - Reading Progress Tracking
    @Published var readingProgress: [Int: Double] = [:] // bookId: progress percentage (0.0 to 1.0)
    @Published var currentReadingBook: GutendexBook?
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = GutendexConfig.baseURL
    
    // Cache for book content
    private var bookContentCache: [Int: BookContent] = [:]
    private let cacheExpiry: TimeInterval = 3600 // 1 hour
    
    // Optimized URLSession for fast book loading
    private lazy var fastSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0 // Faster timeout for book text
        config.timeoutIntervalForResource = 30.0
        config.waitsForConnectivity = false // Don't wait for connectivity
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 100 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024, diskPath: nil) // 100MB memory, 500MB disk
        config.httpMaximumConnectionsPerHost = 4 // Allow parallel connections
        return URLSession(configuration: config)
    }()
    
    init() {
        loadRecentBooks()
        loadReadingProgressFromStorage()
    }
    
    // MARK: - Search Books
    
    func searchBooks(query: String) async {
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
        
        print("🔍 Searching Gutendex for: '\(query)'")
        
        // Construct proper search URL with multiple parameters
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedQuery
        
        // Gutendex search format: /books?search={query}&page=1
        let urlString = "\(baseURL)/books?search=\(encodedQuery)&page=1"
        
        print("🔗 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                self.errorMessage = "Invalid search URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            // Use optimized session with timeout and caching
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8.0)
            let (data, response) = try await fastSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GutendexError.networkError
            }
            
            print("📊 HTTP Status: \(httpResponse.statusCode)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                let statusCode = httpResponse.statusCode
                print("❌ HTTP Error: \(statusCode)")
                throw GutendexError.httpError(statusCode)
            }
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response preview: \(String(responseString.prefix(500)))")
            }
            
            let gutendexResponse = try JSONDecoder().decode(GutendexResponse.self, from: data)
            
            await MainActor.run {
                self.searchResults = gutendexResponse.results
                self.isLoading = false
                print("✅ Found \(gutendexResponse.results.count) books")
                
                if gutendexResponse.results.isEmpty {
                    print("⚠️ No results found for query: '\(query)'")
                }
            }
            
        } catch {
            print("❌ Search error details: \(error)")
            
            if let decodingError = error as? DecodingError {
                print("❌ Decoding error: \(decodingError)")
            }
            
            await MainActor.run {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Fetch Book Content
    
    func fetchBookContent(for book: GutendexBook) async {
        // Check cache first
        if let cachedContent = bookContentCache[book.id] {
            let age = Date().timeIntervalSince(cachedContent.fetchedAt)
            if age < cacheExpiry {
                await MainActor.run {
                    self.bookContent = cachedContent
                }
                print("✅ Using cached book content for: \(book.title)")
                return
            }
        }
        
        // Build direct Gutenberg URL
        let textURL = "https://www.gutenberg.org/cache/epub/\(book.id)/pg\(book.id).txt"
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("📖 Fetching book content for: \(book.title)")
        print("🔗 URL: \(textURL)")
        
        guard let url = URL(string: textURL) else {
            await MainActor.run {
                self.errorMessage = "Invalid book URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            // Use optimized session with timeout and caching
            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15.0)
            let (data, response) = try await fastSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GutendexError.networkError
            }
            
            print("📊 HTTP Status: \(httpResponse.statusCode)")
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw GutendexError.httpError(httpResponse.statusCode)
            }
            
            guard let text = String(data: data, encoding: .utf8) else {
                throw GutendexError.decodingError
            }
            
            // Process text in background for faster UI response
            let processedText = await Task.detached(priority: .userInitiated) {
                // Clean up Gutenberg license text efficiently
                var cleanedText = text
                
                // Remove Gutenberg footer efficiently
                if let endRange = cleanedText.range(of: "END OF THE PROJECT GUTENBERG", options: .caseInsensitive) {
                    cleanedText = String(cleanedText[..<endRange.lowerBound])
                }
                
                // Remove excessive newlines efficiently
                cleanedText = cleanedText.replacingOccurrences(of: "\n\n\n\n+", with: "\n\n\n", options: .regularExpression)
                
                return cleanedText.count > 500 ? cleanedText : text
            }.value
            
            let content = BookContent(
                id: "\(book.id)",
                title: book.title,
                author: book.primaryAuthor,
                text: processedText,
                downloadCount: book.download_count,
                languages: book.languages,
                subjects: book.subjects,
                fetchedAt: Date()
            )
            
            // Cache the content
            bookContentCache[book.id] = content
            
            await MainActor.run {
                self.bookContent = content
                self.isLoading = false
                print("✅ Loaded book content: \(processedText.count) characters")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch book: \(error.localizedDescription)"
                self.bookContent = nil  // Clear content on error
                self.isLoading = false
                print("❌ Failed to fetch book: \(error)")
            }
        }
    }
    
    // MARK: - Text Cleaning
    
    private func cleanGutenbergText(_ text: String) -> String {
        var cleaned = text
        
        // ONLY remove the "END OF PROJECT GUTENBERG" footer at the very end
        // Everything else stays untouched
        if let endRange = cleaned.range(of: "END OF THE PROJECT GUTENBERG", options: .caseInsensitive) {
            cleaned = String(cleaned[..<endRange.lowerBound])
        }
        
        // Remove excessive whitespace (more than 3 consecutive newlines) but keep content
        cleaned = cleaned.replacingOccurrences(of: "\n\n\n\n+", with: "\n\n\n", options: .regularExpression)
        
        // DON'T trim - keep everything
        return cleaned
    }
    
    // MARK: - Get Popular Books
    
    func getPopularBooks() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("📚 Fetching popular books from Gutendex...")
        
        // Fetch most popular books (most downloaded)
        let popularURLString = "\(baseURL)\(GutendexConfig.booksEndpoint)?sort=popular&limit=50"
        
        guard let popularURL = URL(string: popularURLString) else {
            await MainActor.run {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            return
        }
        
        do {
            // Use optimized session with caching
            let request = URLRequest(url: popularURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8.0)
            let (data, response) = try await fastSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GutendexError.networkError
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw GutendexError.httpError(httpResponse.statusCode)
            }
            
            let gutendexResponse = try JSONDecoder().decode(GutendexResponse.self, from: data)
            
            await MainActor.run {
                self.popularBooks = Array(gutendexResponse.results.prefix(20))
                self.allBooks = Array(gutendexResponse.results)
                self.isLoading = false
                print("✅ Loaded \(self.popularBooks.count) popular books and \(self.allBooks.count) total books")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to fetch popular books: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Failed to fetch popular books: \(error)")
            }
        }
    }
    
    // MARK: - Get Recently Added Books
    
    func getRecentlyAddedBooks() async {
        print("📚 Fetching recently added books from Gutendex...")
        
        // Fetch books sorted by ID descending (higher ID = newer book)
        let recentURLString = "\(baseURL)\(GutendexConfig.booksEndpoint)?sort=-id&limit=50"
        
        guard let recentURL = URL(string: recentURLString) else {
            print("❌ Invalid URL for recent books")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: recentURL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GutendexError.networkError
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw GutendexError.httpError(httpResponse.statusCode)
            }
            
            let gutendexResponse = try JSONDecoder().decode(GutendexResponse.self, from: data)
            
            await MainActor.run {
                // Sort by ID descending (higher ID = newer in Gutendex)
                let sortedBooks = gutendexResponse.results.sorted { $0.id > $1.id }
                self.gutendexRecentBooks = Array(sortedBooks.prefix(20))
                print("✅ Loaded \(self.gutendexRecentBooks.count) recently added books")
            }
            
        } catch {
            print("❌ Failed to fetch recent books: \(error)")
        }
    }
    
    // MARK: - Recent Books Management
    
    func addToRecentBooks(_ book: GutendexBook) {
        // Remove if already exists
        recentBooks.removeAll { $0.id == book.id }
        
        // Add to beginning
        recentBooks.insert(book, at: 0)
        
        // Keep only last 10
        if recentBooks.count > 10 {
            recentBooks = Array(recentBooks.prefix(10))
        }
        
        saveRecentBooks()
    }
    
    private func saveRecentBooks() {
        if let encoded = try? JSONEncoder().encode(recentBooks) {
            UserDefaults.standard.set(encoded, forKey: "recentBooks")
        }
    }
    
    private func loadRecentBooks() {
        if let data = UserDefaults.standard.data(forKey: "recentBooks"),
           let decoded = try? JSONDecoder().decode([GutendexBook].self, from: data) {
            recentBooks = decoded
        }
    }
    
    // MARK: - Mood-Based Book Filtering
    
    func fetchBooksByMood(_ mood: ReadingMood) async {
        await MainActor.run {
            self.selectedMood = mood
            self.isLoading = true
            self.errorMessage = nil
        }
        
        print("🎭 Fetching books for mood: \(mood.rawValue)")
        
        if mood == .all {
            // For "All", just show popular books
            await getPopularBooks()
            await MainActor.run {
                self.moodFilteredBooks = self.popularBooks
                self.isLoading = false
            }
            return
        }
        
        // For specific moods, search using keywords in PARALLEL with multiple strategies
        var allMoodBooks: [GutendexBook] = []
        var foundAnyBooks = false
        
        await withTaskGroup(of: [GutendexBook].self) { group in
            // Strategy 1: Search by keywords (primary keywords)
            for keyword in mood.searchKeywords.prefix(6) { // Limit to first 6 for speed
                group.addTask {
                    let trimmedQuery = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                    let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedQuery
                    
                    // Search multiple pages for better results
                    var allBooks: [GutendexBook] = []
                    for page in 1...3 { // Search first 3 pages
                        let urlString = "\(self.baseURL)/books?search=\(encodedQuery)&page=\(page)"
                        
                        guard let url = URL(string: urlString) else {
                            continue
                        }
                        
                        do {
                            let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8.0)
                            let (data, response) = try await self.fastSession.data(for: request)
                            
                            guard let httpResponse = response as? HTTPURLResponse,
                                  200...299 ~= httpResponse.statusCode else {
                                continue
                            }
                            
                            let gutendexResponse = try JSONDecoder().decode(GutendexResponse.self, from: data)
                            allBooks.append(contentsOf: gutendexResponse.results)
                            
                            // If no more pages, stop
                            if gutendexResponse.next == nil {
                                break
                            }
                            
                        } catch {
                            print("⚠️ Error searching page \(page) for keyword \(keyword): \(error.localizedDescription)")
                            continue
                        }
                    }
                    
                    print("✅ Found \(allBooks.count) books for keyword '\(keyword)'")
                    return allBooks
                }
            }
            
            // Strategy 2: Search by subjects/topics (using subjects endpoint)
            // Search for books that have matching subjects
            group.addTask {
                // Try searching with mood name directly as subject
                let subjectQuery = mood.rawValue.lowercased()
                let urlString = "\(self.baseURL)/books?topic=\(subjectQuery)&page=1"
                
                guard let url = URL(string: urlString) else {
                    return []
                }
                
                do {
                    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8.0)
                    let (data, response) = try await self.fastSession.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          200...299 ~= httpResponse.statusCode else {
                        return []
                    }
                    
                    let gutendexResponse = try JSONDecoder().decode(GutendexResponse.self, from: data)
                    print("✅ Found \(gutendexResponse.results.count) books by subject '\(subjectQuery)'")
                    return gutendexResponse.results
                    
                } catch {
                    print("⚠️ Error searching by subject: \(error.localizedDescription)")
                    return []
                }
            }
            
            // Strategy 3: Fallback - search popular books filtered by subjects
            // This ensures we always have some results
            group.addTask {
                // Get popular books and filter by subjects containing mood keywords
                let urlString = "\(self.baseURL)/books?sort=popularity&page=1&limit=100"
                
                guard let url = URL(string: urlString) else {
                    return []
                }
                
                do {
                    let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 8.0)
                    let (data, response) = try await self.fastSession.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          200...299 ~= httpResponse.statusCode else {
                        return []
                    }
                    
                    let gutendexResponse = try JSONDecoder().decode(GutendexResponse.self, from: data)
                    
                    // Filter books by subjects that match mood keywords
                    let matchingBooks = gutendexResponse.results.filter { book in
                        let allSubjects = book.subjects.joined(separator: " ").lowercased()
                        return mood.searchKeywords.contains { keyword in
                            allSubjects.contains(keyword.lowercased())
                        }
                    }
                    
                    print("✅ Found \(matchingBooks.count) popular books matching mood '\(mood.rawValue)'")
                    return matchingBooks
                    
                } catch {
                    print("⚠️ Error searching popular books: \(error.localizedDescription)")
                    return []
                }
            }
            
            // Collect all results in parallel
            for await books in group {
                if !books.isEmpty {
                    foundAnyBooks = true
                }
                // Add unique books (avoid duplicates)
                for book in books {
                    if !allMoodBooks.contains(where: { $0.id == book.id }) {
                        allMoodBooks.append(book)
                    }
                }
            }
        }
        
        // If still no books found, fall back to showing popular books with a note
        if allMoodBooks.isEmpty {
            print("⚠️ No books found for mood '\(mood.rawValue)', falling back to popular books")
            await getPopularBooks()
            await MainActor.run {
                // Filter popular books by subjects for better relevance
                self.moodFilteredBooks = self.popularBooks.filter { book in
                    let allSubjects = book.subjects.joined(separator: " ").lowercased()
                    let allText = (book.title + " " + book.primaryAuthor + " " + allSubjects).lowercased()
                    return mood.searchKeywords.contains { keyword in
                        allText.contains(keyword.lowercased())
                    }
                }
                
                // If still empty, just show all popular books
                if self.moodFilteredBooks.isEmpty {
                    self.moodFilteredBooks = Array(self.popularBooks.prefix(20))
                }
                
                self.isLoading = false
                print("✅ Loaded \(self.moodFilteredBooks.count) books for mood: \(mood.rawValue) (fallback)")
            }
            return
        }
        
        // Sort by download count (most popular first) and take top 50
        let sortedBooks = allMoodBooks.sorted { $0.download_count > $1.download_count }
        let topBooks = Array(sortedBooks.prefix(50))
        
        await MainActor.run {
            self.moodFilteredBooks = topBooks
            self.isLoading = false
            print("✅ Loaded \(topBooks.count) books for mood: \(mood.rawValue)")
        }
    }
    
    func getCurrentMoodBooks() -> [GutendexBook] {
        if selectedMood == .all {
            return popularBooks
        } else {
            return moodFilteredBooks
        }
    }
    
    // MARK: - Clear Cache
    
    func clearCache() {
        bookContentCache.removeAll()
        print("🗑️ Cleared book content cache")
    }
    // MARK: - Reading Progress Management
    
    func startReading(book: GutendexBook) {
        currentReadingBook = book
        
        // Check if user has previous reading progress for this book
        if let savedProgress = readingProgress[book.id], savedProgress > 0.0 {
            // User has previous progress - restore their position
            print("📖 Resuming reading: \(book.title) - Previous progress: \(Int(savedProgress * 100))%")
            
            // Load the saved reading state
            loadCurrentReadingState()
            
            // If we have saved state for this book, use it
            if let savedState = UserDefaults.standard.dictionary(forKey: "currentReadingState"),
               let savedBookId = savedState["bookId"] as? String,
               let savedBookIdInt = Int(savedBookId),
               savedBookIdInt == book.id {
                
                if let savedPage = savedState["currentPage"] as? String,
                   let savedPageInt = Int(savedPage) {
                    currentPage = savedPageInt
                    print("📖 Restored to page: \(currentPage)")
                }
                
                if let savedTotalPages = savedState["totalPages"] as? String,
                   let savedTotalPagesInt = Int(savedTotalPages) {
                    totalPages = savedTotalPagesInt
                    print("📖 Restored total pages: \(totalPages)")
                }
            }
        } else {
            // New reading session - start from beginning
            currentPage = 1
            totalPages = estimateTotalPages(for: book)
            readingProgress[book.id] = 0.0
            print("📖 Starting new reading session: \(book.title)")
        }
        
        // Save current reading state
        saveCurrentReadingState()
        saveReadingProgressToStorage()
        
        print("📖 Started reading: \(book.title) - Page \(currentPage)/\(totalPages)")
    }
    
    func updateReadingProgress(bookId: Int, page: Int, totalPages: Int? = nil) {
        guard let book = currentReadingBook, book.id == bookId else { return }
        
        currentPage = page
        
        // Use provided totalPages or fall back to estimated totalPages
        let actualTotalPages = totalPages ?? self.totalPages
        let progress = Double(page) / Double(actualTotalPages)
        readingProgress[bookId] = min(progress, 1.0)
        
        // Auto-save progress
        saveReadingProgressToStorage()
        saveCurrentReadingState()
        
        print("📊 Updated progress for \(book.title): \(Int(progress * 100))% (page \(page)/\(actualTotalPages))")
    }
    
    func getReadingProgress(for bookId: Int) -> Double {
        return readingProgress[bookId] ?? 0.0
    }
    
    func hasReadingProgress(for bookId: Int) -> Bool {
        return readingProgress[bookId] != nil && readingProgress[bookId]! > 0.0
    }
    
    private func estimateTotalPages(for book: GutendexBook) -> Int {
        // Estimate pages based on download count and typical book length
        // This is a rough estimation - in a real app, you'd get actual page count
        let basePages = 300
        let downloadFactor = min(Double(book.download_count) / 100000.0, 2.0)
        return Int(Double(basePages) * downloadFactor)
    }
    
    func formatBookContent(_ content: String) -> String {
        // Optimized formatting - process in chunks for large books
        if content.count > 100_000 {
            // For very large books, use optimized processing
            return formatLargeBookContent(content)
        }
        
        // Fast formatting for smaller books
        var formattedContent = content
        
        // Fix common formatting issues efficiently (single pass where possible)
        formattedContent = formattedContent.replacingOccurrences(of: "  ", with: " ")
        formattedContent = formattedContent.replacingOccurrences(of: "\n ", with: "\n")
        formattedContent = formattedContent.replacingOccurrences(of: " \n", with: "\n")
        
        // Clean up multiple spaces and newlines using regex (more efficient)
        formattedContent = formattedContent.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        formattedContent = formattedContent.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        return formattedContent.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Optimized formatting for large books (>100k characters)
    private func formatLargeBookContent(_ content: String) -> String {
        // Process in chunks to avoid memory issues
        let chunkSize = 50_000
        var chunks: [String] = []
        
        var startIndex = content.startIndex
        while startIndex < content.endIndex {
            let endIndex = content.index(startIndex, offsetBy: min(chunkSize, content.distance(from: startIndex, to: content.endIndex)), limitedBy: content.endIndex) ?? content.endIndex
            let chunk = String(content[startIndex..<endIndex])
            
            // Quick formatting on chunk
            var formattedChunk = chunk
            formattedChunk = formattedChunk.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
            formattedChunk = formattedChunk.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            
            chunks.append(formattedChunk)
            startIndex = endIndex
        }
        
        return chunks.joined().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Data Persistence
    
    private func saveReadingProgressToStorage() {
        // Convert reading progress dictionary to a format that can be saved to UserDefaults
        // Convert both keys (Int) and values (Double) to String for UserDefaults compatibility
        let progressData = readingProgress.map { (key, value) in
            (String(key), String(value))
        }
        let progressDict = Dictionary(uniqueKeysWithValues: progressData)
        UserDefaults.standard.set(progressDict, forKey: "readingProgress")
        print("💾 Saved reading progress for \(readingProgress.count) books")
    }
    
    private func loadReadingProgressFromStorage() {
        // Load reading progress from UserDefaults
        if let progressData = UserDefaults.standard.dictionary(forKey: "readingProgress") as? [String: String] {
            readingProgress = [:]
            for (key, value) in progressData {
                if let bookId = Int(key), let progress = Double(value) {
                    readingProgress[bookId] = progress
                }
            }
            print("📂 Loaded reading progress for \(readingProgress.count) books")
        }
        
        // Load current reading state
        loadCurrentReadingState()
    }
    
    private func saveCurrentReadingState() {
        // Save current book and page information
        if let book = currentReadingBook {
            let currentState = [
                "bookId": String(book.id),
                "bookTitle": book.title,
                "bookAuthor": book.primaryAuthor,
                "currentPage": String(currentPage),
                "totalPages": String(totalPages)
            ]
            UserDefaults.standard.set(currentState, forKey: "currentReadingState")
            print("💾 Saved current reading state: \(book.title) - Page \(currentPage)/\(totalPages)")
        }
    }
    
    private func loadCurrentReadingState() {
        // Load current reading state
        if let currentState = UserDefaults.standard.dictionary(forKey: "currentReadingState"),
           let bookIdString = currentState["bookId"] as? String,
           let bookId = Int(bookIdString),
           let currentPageString = currentState["currentPage"] as? String,
           let currentPage = Int(currentPageString),
           let totalPagesString = currentState["totalPages"] as? String,
           let totalPages = Int(totalPagesString) {
            
            self.currentPage = currentPage
            self.totalPages = totalPages
            
            // Try to find the book in our current books list
            if let book = findBookById(bookId) {
                self.currentReadingBook = book
                print("📂 Restored reading state: \(book.title) - Page \(currentPage)/\(totalPages)")
            }
        }
    }
    
    private func findBookById(_ bookId: Int) -> GutendexBook? {
        // Search through all book lists to find the book
        let allBooks = popularBooks + recentBooks + allBooks + gutendexRecentBooks + moodFilteredBooks
        
        // Remove duplicates based on ID
        let uniqueBooks = Array(Set(allBooks.map { $0.id })).compactMap { id in
            allBooks.first { $0.id == id }
        }
        
        return uniqueBooks.first { $0.id == bookId }
    }
    
    func clearReadingProgress() {
        readingProgress.removeAll()
        currentReadingBook = nil
        currentPage = 1
        totalPages = 1
        
        // Clear from storage
        UserDefaults.standard.removeObject(forKey: "readingProgress")
        UserDefaults.standard.removeObject(forKey: "currentReadingState")
        
        print("🗑️ Cleared all reading progress")
    }
}

// MARK: - Error Types

enum GutendexError: Error {
    case invalidURL
    case networkError
    case httpError(Int)
    case decodingError
    case noTextAvailable
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .noTextAvailable:
            return "No text format available"
        }
    }
}

