//
//  ReadingSessionView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI
import Foundation

// Minimal Jamendo models/manager (local definition to ensure availability)
struct JamendoTrack: Codable, Identifiable {
    let id: String
    let name: String
    let artist_name: String
    let audio: String
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
        let urlString = "https://api.jamendo.com/v3.0/tracks/?client_id=\(clientId)&format=json&limit=\(limit)&tags=\(encodedTag)&audioformat=mp31"
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

struct ReadingSessionView: View {
    @EnvironmentObject var gutendexManager: GutendexManager
    @StateObject private var playbackManager = SpotifyPlaybackManager()
    @StateObject private var jamendoManager = JamendoManager()
    
    @State private var readingSettings = ReadingSettings()
    @State private var currentProgress: CGFloat = 0.0
    @State private var isMusicPlaying = false
    @State private var showSettings = false
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var selectedBook: GutendexBook?
    @State private var showBookOptions = false
    @State private var showingSummary = false
    @State private var showingFullBook = false
    @State private var bookSummary = ""
    @State private var isGeneratingSummary = false
    @State private var isLoadingFullBook = false
    @State private var loadingError: String?
    @State private var showingMoodDropdown = false
    @State private var jamendoQueue: [JamendoTrack] = []
    @State private var jamendoIndex: Int = 0
    @State private var showTrackPicker = false
    @State private var lastUsedTags: [String] = []
    @State private var cachedTags: [String: [String]] = [:] // Cache tags by book ID
    @State private var isPreloadingTracks = false
    @State private var preloadTask: Task<Void, Never>?
    
    // Pagination state
    @State private var currentPage = 0
    @State private var pages: [String] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color based on settings
                (readingSettings.darkMode ? Color.black : Color(.systemBackground))
                    .ignoresSafeArea()
                
                if isLoadingFullBook {
                    // Show loading state
                    loadingFullBookView
                } else if showingFullBook, let bookContent = gutendexManager.bookContent {
                    // Show full book reading interface
                    readingFullBookView(bookContent: bookContent)
                } else if showingSummary {
                    // Show AI-generated summary
                    summaryView
                } else if showBookOptions, let book = selectedBook {
                    // Show book selection options
                    bookOptionsView(book: book)
                } else {
                    // Show search interface
                    searchInterfaceView
                }
            }
            .navigationTitle("Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSearch.toggle()
                    }) {
                        Image(systemName: showSearch ? "xmark.circle.fill" : "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                ReadingSettingsView(settings: $readingSettings)
            }
            .onAppear {
                // Load popular books when view appears
                if gutendexManager.popularBooks.isEmpty {
                    Task {
                        await gutendexManager.getPopularBooks()
                        // Initialize mood-based books with "All" mood (shows popular books)
                        await gutendexManager.fetchBooksByMood(.all)
                    }
                }
                
            }
        }
    }
    
    // MARK: - Search Interface View
    
    var searchInterfaceView: some View {
        VStack(spacing: 20) {
            if showSearch {
                // Search Bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search books...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            gutendexManager.searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !searchText.isEmpty {
                        Button(action: performSearch) {
                            Text("Search")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Search Results
                if gutendexManager.isLoading {
                    ProgressView()
                        .padding(40)
                } else if !gutendexManager.searchResults.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(gutendexManager.searchResults) { book in
                                bookSearchResultCard(book: book)
                            }
                        }
                        .padding()
                    }
                } else if !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Text("No books found")
                            .foregroundColor(.secondary)
                        
                        // Show popular books as fallback
                        if !gutendexManager.popularBooks.isEmpty {
                            Text("Popular Books:")
                                .font(.headline)
                                .padding(.top)
                            
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(gutendexManager.popularBooks.prefix(10)) { book in
                                        bookSearchResultCard(book: book)
                                    }
                                }
                                .padding()
                            }
                        }
                    }
                    .padding(40)
                } else if !gutendexManager.popularBooks.isEmpty || !gutendexManager.moodFilteredBooks.isEmpty {
                    // Show popular books when search is empty
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header with mood dropdown
                            HStack {
                                Text("Popular Books")
                                    .font(.headline)
                                
                                Spacer()
                                
                                // Mood Dropdown Button
                                Button(action: {
                                    showingMoodDropdown.toggle()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: gutendexManager.selectedMood.icon)
                                            .font(.caption)
                                        Text(gutendexManager.selectedMood.rawValue)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Image(systemName: showingMoodDropdown ? "chevron.up" : "chevron.down")
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Mood Dropdown Menu
                            if showingMoodDropdown {
                                moodDropdownMenu
                            }
                            
                            // Books List
                            if gutendexManager.isLoading {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Loading \(gutendexManager.selectedMood.rawValue) books...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(40)
                            } else {
                                let booksToShow = gutendexManager.selectedMood == .all ? gutendexManager.popularBooks : gutendexManager.moodFilteredBooks
                                
                                if booksToShow.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: gutendexManager.selectedMood.icon)
                                            .font(.system(size: 50))
                                            .foregroundColor(.purple.opacity(0.5))
                                        
                                        Text("No \(gutendexManager.selectedMood.rawValue) Books Found")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Try selecting a different mood or search for specific books")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(40)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(booksToShow.prefix(20)) { book in
                                            bookSearchResultCard(book: book)
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
            } else {
                // No book selected - show search prompt
                VStack(spacing: 24) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.purple.opacity(0.5))
                    
                    Text("Search for a Book")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Tap the search icon to find books from Gutenberg")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showSearch = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Books")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(40)
            }
        }
    }
    
    // MARK: - Book Search Result Card
    
    func bookSearchResultCard(book: GutendexBook) -> some View {
        Button(action: {
            selectedBook = book
            showBookOptions = true
            showSearch = false
        }) {
            HStack(spacing: 16) {
                // Book icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 80)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                }
                
                // Book info
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(book.primaryAuthor)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Book metadata
                    HStack(spacing: 12) {
                        Label("\(book.download_count)", systemImage: "arrow.down.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        if !book.languages.isEmpty {
                            Label(book.languages.first?.uppercased() ?? "", systemImage: "globe")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Reading Progress Bar (if user has started reading)
                    if gutendexManager.hasReadingProgress(for: book.id) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Reading Progress")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(gutendexManager.getReadingProgress(for: book.id) * 100))%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.purple)
                            }
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 4)
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.purple, Color.blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * gutendexManager.getReadingProgress(for: book.id), height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Book Options View
    
    func bookOptionsView(book: GutendexBook) -> some View {
        VStack(spacing: 24) {
            // Book Header
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 160)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                }
                
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("by \(book.primaryAuthor)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Options
            VStack(spacing: 16) {
                // Summary Button
                Button(action: {
                    generateSummary(for: book)
                }) {
                    HStack {
                        if isGeneratingSummary {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "text.alignleft")
                            Text("Read Summary")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
                .disabled(isGeneratingSummary)
                
                // Read Full Book Button
                Button(action: {
                    // Start reading progress tracking
                    gutendexManager.startReading(book: book)
                    loadFullBook(book: book)
                }) {
                    HStack {
                        if isLoadingFullBook {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "book.fill")
                            Text("Read Full Book")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
                }
                .disabled(isLoadingFullBook)
                
                // Back Button
                Button(action: {
                    showBookOptions = false
                    selectedBook = nil
                    // Navigate back to Popular Books view
                    showingFullBook = false
                    pages = []
                    currentPage = 0
                    currentProgress = 0.0
                }) {
                    Text("Back to Popular Books")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Summary View
    
    var summaryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let book = selectedBook {
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("by \(book.primaryAuthor)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    if isGeneratingSummary {
                        HStack {
                            ProgressView()
                            Text("Generating summary with AI...")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        Text(bookSummary)
                            .font(.body)
                            .lineSpacing(8)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    showingSummary = false
                    showBookOptions = true
                }
            }
        }
    }
    
    // MARK: - Loading Full Book View
    
    var loadingFullBookView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Book...")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let error = loadingError {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("Fetching full text from Gutenberg Project")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if loadingError != nil {
                Button(action: {
                    if let book = selectedBook {
                        loadFullBook(book: book)
                    }
                }) {
                    Text("Retry")
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
        .padding(40)
    }
    
    // MARK: - Reading Full Book View
    
    func readingFullBookView(bookContent: BookContent) -> some View {
        VStack(spacing: 0) {
            // Reading progress bar
            readingProgressBar
            
            // Book content with pagination
            paginatedReadingContent(bookContent: bookContent)
            
            // Page navigation
            pageNavigation
            
            // Music controls bar
            musicControlsBar
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    showingFullBook = false
                    gutendexManager.bookContent = nil
                    pages = []
                    currentPage = 0
                    showBookOptions = false
                    selectedBook = nil
                    // Navigate back to Popular Books view
                    currentProgress = 0.0
                }
            }
        }
    }
    
    // MARK: - Reading Progress Bar
    
    var readingProgressBar: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * currentProgress)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("\(Int(currentProgress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let bookContent = gutendexManager.bookContent {
                    Text("\(bookContent.estimatedReadingTime) min read")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Paginated Reading Content
    
    func paginatedReadingContent(bookContent: BookContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book header (only on first page)
                if currentPage == 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(bookContent.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(readingSettings.darkMode ? .white : .primary)
                        
                        Text("by \(bookContent.author)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Divider()
                }
                
                // Current page text
                VStack(alignment: .leading, spacing: 0) {
                    if pages.isEmpty {
                        Text("Loading pages...")
                            .foregroundColor(.secondary)
                            .padding()
                    } else if currentPage < pages.count {
                        Text(pages[currentPage])
                            .font(.system(size: readingSettings.fontSize))
                            .foregroundColor(readingSettings.darkMode ? .white : .primary)
                            .lineSpacing(readingSettings.lineSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environment(\.legibilityWeight, readingSettings.fontWeight == .bold ? .bold : .regular)
                            .fixedSize(horizontal: false, vertical: true)
                            .onAppear {
                                print("📖 Displaying page \(currentPage + 1) of \(pages.count)")
                                print("📖 Page text length: \(pages[currentPage].count) characters")
                                
                                // Update reading progress only if we have a current book and pages
                                if let book = gutendexManager.currentReadingBook, !pages.isEmpty {
                                    // Only update if the progress has actually changed
                                    let newProgress = CGFloat(currentPage) / CGFloat(max(pages.count, 1))
                                    if abs(newProgress - currentProgress) > 0.01 { // Only update if change is significant
                                        gutendexManager.updateReadingProgress(bookId: book.id, page: currentPage + 1, totalPages: pages.count)
                                        currentProgress = CGFloat(gutendexManager.getReadingProgress(for: book.id))
                                    }
                                }
                            }
                    } else {
                        Text("End of book")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(readingSettings.darkMode ? Color.black : Color(.systemBackground))
    }
    
    // MARK: - Page Navigation
    
    var pageNavigation: some View {
        HStack(spacing: 20) {
            // Previous button
            Button(action: {
                if currentPage > 0 {
                    print("🔄 Previous button pressed - current page: \(currentPage), total pages: \(pages.count)")
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage -= 1
                        currentProgress = CGFloat(currentPage) / CGFloat(max(pages.count, 1))
                        
                        // Update reading progress in manager (async to prevent blocking)
                        if let book = gutendexManager.currentReadingBook {
                            Task {
                                await MainActor.run {
                                    gutendexManager.updateReadingProgress(bookId: book.id, page: currentPage + 1, totalPages: pages.count)
                                }
                            }
                        }
                    }
                    
                    print("✅ Previous button completed - new page: \(currentPage), progress: \(currentProgress)")
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(currentPage > 0 ? Color.purple : Color.gray)
                .cornerRadius(10)
            }
            .disabled(currentPage == 0)
            
            // Page indicator
            Text("\(currentPage + 1) / \(pages.count)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Next button
            Button(action: {
                if currentPage < pages.count - 1 {
                    print("🔄 Next button pressed - current page: \(currentPage), total pages: \(pages.count)")
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                        currentProgress = CGFloat(currentPage) / CGFloat(max(pages.count, 1))
                        
                        // Update reading progress in manager (async to prevent blocking)
                        if let book = gutendexManager.currentReadingBook {
                            Task {
                                await MainActor.run {
                                    gutendexManager.updateReadingProgress(bookId: book.id, page: currentPage + 1, totalPages: pages.count)
                                }
                            }
                        }
                    }
                    
                    print("✅ Next button completed - new page: \(currentPage), progress: \(currentProgress)")
                }
            }) {
                HStack {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(currentPage < pages.count - 1 ? Color.blue : Color.gray)
                .cornerRadius(10)
            }
            .disabled(currentPage >= pages.count - 1)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Reading Content (OLD - Keeping for reference)
    
    func readingContent(bookContent: BookContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Book header
                VStack(alignment: .leading, spacing: 8) {
                    Text(bookContent.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(readingSettings.darkMode ? .white : .primary)
                    
                    Text("by \(bookContent.author)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Divider()
                
                // Book text
                VStack(alignment: .leading, spacing: 0) {
                    if bookContent.text.isEmpty {
                        VStack(spacing: 16) {
                            Text("No content available")
                                .foregroundColor(.red)
                                .font(.headline)
                            
                            Text("Book loaded but text is empty")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                        .padding()
                    } else {
                        Text(bookContent.text)
                            .font(.system(size: readingSettings.fontSize))
                            .foregroundColor(readingSettings.darkMode ? .white : .primary)
                            .lineSpacing(readingSettings.lineSpacing)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .environment(\.legibilityWeight, readingSettings.fontWeight == .bold ? .bold : .regular)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    print("📖 DISPLAYING BOOK TEXT")
                    print("📖 Text length: \(bookContent.text.count) characters")
                    print("📖 Text is empty: \(bookContent.text.isEmpty)")
                    print("📖 First 100 chars: '\(String(bookContent.text.prefix(100)))'")
                    print("📖 Book title: \(bookContent.title)")
                    print("📖 Word count: \(bookContent.wordCount)")
                }
            }
        }
        .background(readingSettings.darkMode ? Color.black : Color(.systemBackground))
    }
    
    // MARK: - Music Controls Bar (Optimized UI)
    
    var musicControlsBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.3)
            
            VStack(spacing: 12) {
                // Main controls row
                HStack(spacing: 16) {
                    // Play/Pause button - Larger, more prominent
                    Button(action: {
                        toggleMusic()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: playbackManager.isPlaying ? [Color.purple.opacity(0.2), Color.blue.opacity(0.2)] : [Color.purple, Color.blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            if playbackManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(playbackManager.isLoading && !playbackManager.isPlaying)
                    
                    // Track info - Cleaner layout
                    VStack(alignment: .leading, spacing: 4) {
                        // Track title
                        Text(playbackManager.currentTitle ?? (jamendoQueue.isEmpty ? "No music" : "Ready to play"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        // Tags/subtitle - Show only when not loading
                        if !playbackManager.isLoading {
                            Button(action: { 
                                if !jamendoQueue.isEmpty {
                                    showTrackPicker = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if !jamendoQueue.isEmpty {
                                        Image(systemName: "music.note.list")
                                            .font(.caption2)
                                    }
                                    Text(lastUsedTags.isEmpty ? (jamendoQueue.isEmpty ? "Tap play to start" : "Adaptive music ready") : lastUsedTags.prefix(2).joined(separator: " • "))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        } else {
                            // Compact loading indicator
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Preparing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Skip button - More compact
                    if !jamendoQueue.isEmpty && jamendoQueue.count > 1 {
                        Button(action: { 
                            skipJamendoTrack()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .disabled(playbackManager.isLoading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Volume control - Horizontal layout, more compact
                HStack(spacing: 12) {
                    Image(systemName: playbackManager.volume == 0 ? "speaker.slash.fill" : playbackManager.volume < 0.5 ? "speaker.wave.1.fill" : "speaker.wave.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    
                    Slider(value: Binding(
                        get: { playbackManager.volume },
                        set: { playbackManager.setVolume($0) }
                    ), in: 0...1)
                    .tint(.purple)
                    
                    Text("\(Int(playbackManager.volume * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            
            // Error message - Subtle, at bottom
            if let errorMessage = playbackManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showTrackPicker) {
            NavigationView {
                List {
                    if jamendoQueue.isEmpty {
                        Text("No tracks yet. Press play to generate an adaptive queue.")
                            .foregroundColor(.secondary)
                    }
                    ForEach(Array(jamendoQueue.enumerated()), id: \.offset) { idx, t in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(t.name).font(.subheadline).lineLimit(1).truncationMode(.tail)
                                Text(t.artist_name).font(.caption).foregroundColor(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if idx == jamendoIndex { Image(systemName: "checkmark.circle.fill").foregroundColor(.purple) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            jamendoIndex = idx
                            playJamendoCurrent()
                            showTrackPicker = false
                        }
                    }
                }
                .navigationTitle("Adaptive Tracks")
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Close") { showTrackPicker = false } } }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            print("🔍 Performing search for: '\(searchText)'")
            await gutendexManager.searchBooks(query: searchText)
            
            // If no results, try loading popular books as fallback
            if gutendexManager.searchResults.isEmpty && !gutendexManager.isLoading {
                print("⚠️ No search results, loading popular books as fallback")
                await gutendexManager.getPopularBooks()
            }
        }
    }
    
    func generateSummary(for book: GutendexBook) {
        isGeneratingSummary = true
        showingSummary = true
        
        Task {
            // Use Foundation Models to generate summary
            let foundationManager = FoundationModelsManager()
            
            // Fetch a sample of the book text for context
            await gutendexManager.fetchBookContent(for: book)
            
            if let bookContent = gutendexManager.bookContent {
                // Get first 1000 characters for context
                let sampleText = String(bookContent.text.prefix(1000))
                
                #if canImport(FoundationModels)
                if #available(iOS 26.0, macOS 26.0, *) {
                    // Generate summary using Foundation Models
                    let session = LanguageModelSession()
                    
                    let prompt = """
                    Write a comprehensive summary of this book:
                    
                    Title: \(book.title)
                    Author: \(book.primaryAuthor)
                    
                    Sample text: \(sampleText)
                    
                    Provide:
                    1. A brief overview of the story
                    2. Main themes and topics
                    3. Why someone might enjoy reading it
                    
                    Keep it engaging and 4-5 paragraphs long.
                    """
                    
                    do {
                        let response = try await session.respond(
                            to: prompt,
                            options: GenerationOptions(
                                temperature: 0.7,
                                maximumResponseTokens: nil
                            )
                        )
                        
                        await MainActor.run {
                            bookSummary = response.content
                            isGeneratingSummary = false
                        }
                    } catch {
                        await MainActor.run {
                            bookSummary = generateBasicSummary(for: book)
                            isGeneratingSummary = false
                        }
                    }
                } else {
                    await MainActor.run {
                        bookSummary = generateBasicSummary(for: book)
                        isGeneratingSummary = false
                    }
                }
                #else
                await MainActor.run {
                    bookSummary = generateBasicSummary(for: book)
                    isGeneratingSummary = false
                }
                #endif
            } else {
                await MainActor.run {
                    bookSummary = generateBasicSummary(for: book)
                    isGeneratingSummary = false
                }
            }
        }
    }
    
    func generateBasicSummary(for book: GutendexBook) -> String {
        return """
        \(book.title) by \(book.primaryAuthor)
        
        This is a classic literary work from the Gutenberg Project. It has been downloaded \(book.download_count) times, making it a popular choice among readers.
        
        With \(book.languages.joined(separator: ", ")) language support, this book continues to captivate readers across the globe. The story explores timeless themes and offers an immersive reading experience.
        
        Start reading to discover why this book has remained beloved by readers for generations. Each page brings new insights and experiences that will enrich your reading journey.
        """
    }
    
    func loadFullBook(book: GutendexBook) {
        isLoadingFullBook = true
        showBookOptions = false
        loadingError = nil
        currentPage = 0
        
        // Update recent books immediately (non-blocking)
        gutendexManager.addToRecentBooks(book)
        
        Task {
            do {
                // Fetch book content with optimized timeout
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await gutendexManager.fetchBookContent(for: book)
                    }
                    
                    group.addTask {
                        try await Task.sleep(nanoseconds: 25_000_000_000) // 25 second timeout (reduced from 30)
                        throw URLError(.timedOut)
                    }
                    
                    try await group.next() // Wait for first task to complete
                    group.cancelAll() // Cancel remaining tasks
                }
                
                // Check if content was loaded successfully
                if let bookContent = gutendexManager.bookContent {
                    // Process formatting and pagination in parallel for speed
                    let (formattedText, paginated) = await Task.detached(priority: .userInitiated) {
                        // Format text (in background)
                        let formatted = gutendexManager.formatBookContent(bookContent.text)
                        // Paginate (in background)
                        let paginated = self.paginateText(formatted, wordsPerPage: 225)
                        return (formatted, paginated)
                    }.value
                    
                    await MainActor.run {
                        pages = paginated
                        isLoadingFullBook = false
                        showingFullBook = true
                        
                        // Restore reading position if user has previous progress
                        let savedProgress = gutendexManager.getReadingProgress(for: book.id)
                        if savedProgress > 0.0 {
                            let savedPage = Int(savedProgress * Double(paginated.count))
                            currentPage = max(0, min(savedPage, paginated.count - 1))
                            currentProgress = CGFloat(savedProgress)
                            print("📖 Restored reading position: page \(currentPage + 1) of \(paginated.count)")
                        } else {
                            currentPage = 0
                            currentProgress = 0.0
                        }
                        
                        print("📖 Paginated into \(paginated.count) pages")
                    }
                    
                    // Preload adaptive music tags in background (non-blocking)
                    Task.detached(priority: .background) {
                        // Compute tags early so music is ready when user presses play
                        let tags = await self.computeJamendoTagsOptimized()
                        await MainActor.run {
                            self.cachedTags[String(book.id)] = tags
                            print("🎵 Precomputed music tags: \(tags.joined(separator: ", "))")
                            
                            // Aggressively pre-fetch tracks AND audio in background for instant playback
                            Task.detached(priority: .userInitiated) {
                                let tracks = await self.fetchTracksOptimized(tags: tags)
                                await MainActor.run {
                                    if !tracks.isEmpty {
                                        self.jamendoQueue = tracks
                                        self.jamendoIndex = 0
                                        // Update UI to show ready state
                                        if let firstTrack = tracks.first {
                                            self.playbackManager.currentTitle = "\(firstTrack.name) — \(firstTrack.artist_name)"
                                        }
                                        print("🎵 Preloaded \(tracks.count) tracks for instant playback")
                                        
                                        // CRITICAL: Preload first 2 tracks' audio data immediately in parallel
                                        // This ensures instant playback when user presses play
                                        Task.detached(priority: .userInitiated) {
                                            await withTaskGroup(of: Void.self) { group in
                                                for (index, track) in tracks.prefix(2).enumerated() {
                                                    group.addTask {
                                                        do {
                                                            let url = URL(string: track.audio)!
                                                            let (data, _) = try await URLSession.shared.data(from: url)
                                                            await MainActor.run {
                                                                self.playbackManager.preloadAudioToCache(urlString: track.audio, data: data)
                                                            }
                                                            print("🚀 Preloaded audio for track \(index + 1): \(track.name)")
                                                        } catch {
                                                            print("⚠️ Failed to preload track \(index + 1): \(error)")
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // No content loaded
                    await MainActor.run {
                        isLoadingFullBook = false
                        loadingError = "Failed to load book content. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoadingFullBook = false
                    if error is URLError && (error as? URLError)?.code == .timedOut {
                        loadingError = "Book loading timed out. Please try again."
                    } else {
                        loadingError = "Error loading book: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    // MARK: - Mood Dropdown Menu
    
    var moodDropdownMenu: some View {
        VStack(spacing: 8) {
            ForEach(ReadingMood.allCases, id: \.self) { mood in
                Button(action: {
                    print("🎭 Selected mood: \(mood.rawValue)")
                    Task {
                        await gutendexManager.fetchBooksByMood(mood)
                        print("🎭 Finished fetching books for mood: \(mood.rawValue)")
                    }
                    showingMoodDropdown = false
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: mood.icon)
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Text(mood.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if gutendexManager.selectedMood == mood {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        gutendexManager.selectedMood == mood ?
                        Color.purple.opacity(0.1) :
                        Color(.systemGray6)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Pagination Helper (Optimized)
    
    func paginateText(_ text: String, wordsPerPage: Int) -> [String] {
        // Split text into words efficiently
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // For very large books, use optimized chunking
        if words.count > 50_000 {
            return paginateVeryLargeText(text: text, wordsPerPage: wordsPerPage)
        }
        
        // For large books, use chunked processing
        if words.count > 10000 {
            return paginateLargeText(words: words, wordsPerPage: wordsPerPage)
        }
        
        // Standard pagination for smaller books (fast path)
        var pages: [String] = []
        var currentPageWords: [String] = []
        currentPageWords.reserveCapacity(wordsPerPage) // Pre-allocate for performance
        
        for word in words {
            currentPageWords.append(word)
            
            // When we reach wordsPerPage, create a page
            if currentPageWords.count >= wordsPerPage {
                pages.append(currentPageWords.joined(separator: " "))
                currentPageWords.removeAll(keepingCapacity: true) // Keep capacity for next page
            }
        }
        
        // Add remaining words as last page
        if !currentPageWords.isEmpty {
            pages.append(currentPageWords.joined(separator: " "))
        }
        
        print("📄 Created \(pages.count) pages from \(words.count) words")
        return pages
    }
    
    // Optimized pagination for very large books (>50k words)
    private func paginateVeryLargeText(text: String, wordsPerPage: Int) -> [String] {
        // Process in large chunks to avoid memory issues
        let chunkSize = 20_000 // Process 20k words at a time
        var allPages: [String] = []
        
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        for chunkStart in stride(from: 0, to: words.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, words.count)
            let chunk = Array(words[chunkStart..<chunkEnd])
            
            var currentPageWords: [String] = []
            currentPageWords.reserveCapacity(wordsPerPage)
            
            for word in chunk {
                currentPageWords.append(word)
                
                if currentPageWords.count >= wordsPerPage {
                    allPages.append(currentPageWords.joined(separator: " "))
                    currentPageWords.removeAll(keepingCapacity: true)
                }
            }
            
            // Add remaining words from this chunk (will be merged with next chunk if needed)
            if !currentPageWords.isEmpty && chunkEnd < words.count {
                // Carry over to next chunk processing
                // For now, just add as a partial page
                allPages.append(currentPageWords.joined(separator: " "))
            }
        }
        
        print("📄 Created \(allPages.count) pages from \(words.count) words (very large text)")
        return allPages
    }
    
    private func paginateLargeText(words: [String], wordsPerPage: Int) -> [String] {
        var pages: [String] = []
        let chunkSize = 1000 // Process 1000 words at a time
        
        for chunkStart in stride(from: 0, to: words.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, words.count)
            let chunk = Array(words[chunkStart..<chunkEnd])
            
            var currentPageWords: [String] = []
            
            for word in chunk {
                currentPageWords.append(word)
                
                if currentPageWords.count >= wordsPerPage {
                    let pageText = currentPageWords.joined(separator: " ")
                    pages.append(pageText)
                    currentPageWords.removeAll()
                }
            }
            
            // Add remaining words from this chunk
            if !currentPageWords.isEmpty {
                let pageText = currentPageWords.joined(separator: " ")
                pages.append(pageText)
            }
        }
        
        print("📄 Created \(pages.count) pages from \(words.count) words (large text processing)")
        return pages
    }
    
    func toggleMusic() {
        // Instant response - update UI immediately
        if playbackManager.isPlaying {
            playbackManager.pausePlayback()
        } else {
            // If we have preloaded tracks, play instantly
            if !jamendoQueue.isEmpty && jamendoIndex < jamendoQueue.count {
                // Instant playback - no loading state
                playJamendoCurrent()
            } else {
                // Start loading in background, but show UI immediately
                Task {
                    await startAdaptiveMusic()
                }
            }
        }
    }
    
    func startAdaptiveMusic() async {
        await MainActor.run {
            playbackManager.isLoading = true
        }
        
        // Get or compute tags (with caching)
        let bookId = selectedBook != nil ? String(selectedBook!.id) : ""
        let tags: [String]
        
        if let cached = cachedTags[bookId] {
            tags = cached
            print("✅ Using cached tags for book: \(bookId)")
        } else {
            tags = await computeJamendoTagsOptimized()
            await MainActor.run {
                cachedTags[bookId] = tags
            }
        }
        
        await MainActor.run { 
            lastUsedTags = tags
        }
        
        // Fetch tracks in parallel for faster loading
        let tracks = await fetchTracksOptimized(tags: tags)
        
        await MainActor.run {
            if !tracks.isEmpty {
                jamendoQueue = tracks
                jamendoIndex = 0
                
                // Update UI immediately with first track
                if let firstTrack = tracks.first {
                    playbackManager.currentTitle = "\(firstTrack.name) — \(firstTrack.artist_name)"
                }
                
                // Start playing immediately (may load in background)
                playbackManager.isLoading = false
                playJamendoCurrent()
                
                // Aggressively preload next 3 tracks in parallel
                preloadNextTrack()
            } else {
                playbackManager.isLoading = false
                playbackManager.errorMessage = jamendoManager.errorMessage ?? "No Jamendo tracks found for tags: \(tags.joined(separator: ", "))"
            }
        }
    }
    
    // Ultra-optimized parallel track fetching with timeout
    func fetchTracksOptimized(tags: [String]) async -> [JamendoTrack] {
        // Try all strategies in parallel with timeout - fastest result wins
        return await withTaskGroup(of: [JamendoTrack].self) { group in
            // Strategy 1: Combined tags (usually fastest)
            let joinTag = tags.joined(separator: ",")
            group.addTask {
                await self.jamendoManager.fetchTracks(tag: joinTag, limit: 30)
                return self.jamendoManager.tracks
            }
            
            // Strategy 2: Individual tags in parallel (fallback)
            if tags.count > 1 {
                for tag in tags.prefix(3) { // Limit to first 3 tags for speed
                    group.addTask {
                        await self.jamendoManager.fetchTracks(tag: tag, limit: 20)
                        return self.jamendoManager.tracks
                    }
                }
            }
            
            // Strategy 3: Safe fallback tags (guaranteed)
            group.addTask {
                await self.jamendoManager.fetchTracks(tag: "instrumental,ambient", limit: 25)
                return self.jamendoManager.tracks
            }
            
            // Take first non-empty result (fastest response wins!)
            for await tracks in group {
                if !tracks.isEmpty {
                    group.cancelAll() // Cancel other requests
                    return tracks
                }
            }
            
            // Fallback if all failed
            return []
        }
    }
    
    // Aggressive preloading - Load next 3 tracks in parallel for instant playback
    func preloadNextTrack() {
        guard jamendoIndex + 1 < jamendoQueue.count else { return }
        
        // Preload next 3 tracks in parallel for seamless transitions
        let tracksToPreload = min(3, jamendoQueue.count - (jamendoIndex + 1))
        
        Task.detached(priority: .userInitiated) {
            await withTaskGroup(of: Void.self) { group in
                for i in 1...tracksToPreload {
                    let trackIndex = jamendoIndex + i
                    guard trackIndex < jamendoQueue.count else { break }
                    let track = jamendoQueue[trackIndex]
                    
                    group.addTask {
                        do {
                            // Preload audio data to cache
                            let url = URL(string: track.audio)!
                            let (data, _) = try await URLSession.shared.data(from: url)
                            
                            // Store in playback manager cache immediately
                            await MainActor.run {
                                playbackManager.preloadAudioToCache(urlString: track.audio, data: data)
                            }
                            print("✅ Preloaded track \(i): \(track.name)")
                        } catch {
                            print("⚠️ Failed to preload track \(i): \(error)")
                        }
                    }
                }
            }
        }
    }

    // Optimized tag computation - runs in background with timeout
    func computeJamendoTagsOptimized() async -> [String] {
        // Fast heuristic fallback first (always works)
        let fastTags = computeFastHeuristicTags()
        
        // Try AI enhancement in background (with timeout)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if let book = selectedBook, let content = gutendexManager.bookContent {
                do {
                    let enhancedTags = try await withThrowingTaskGroup(of: [String].self) { group in
                        group.addTask {
                            let context = """
                            Title: \(book.title)
                            Author: \(book.primaryAuthor)
                            Sample: \(String(content.text.prefix(400)))
                            """
                            
                            let session = LanguageModelSession()
                            let prompt = """
                            Return 3 comma-separated Jamendo tags for reading music. Tags: instrumental, ambient, classical, piano, strings, lo-fi, acoustic, meditation, focus.
                            Context: \(context)
                            Tags only, comma-separated:
                            """
                            
                            let response = try await session.respond(
                                to: prompt, 
                                options: GenerationOptions(temperature: 0.3, maximumResponseTokens: 15)
                            )
                            
                            let parsed = response.content.lowercased()
                                .replacingOccurrences(of: "\n", with: ",")
                                .split(separator: ",")
                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                .filter { !$0.isEmpty }
                            
                            return Array(parsed.prefix(3))
                        }
                        
                        // Timeout after 2 seconds - use fast tags if AI is slow
                        group.addTask {
                            try await Task.sleep(nanoseconds: 2_000_000_000)
                            return []
                        }
                        
                        let result = try await group.next() ?? []
                        group.cancelAll()
                        return result.isEmpty ? fastTags : result
                    }
                    
                    return enhancedTags
                } catch {
                    print("⚠️ AI tag computation failed, using heuristics: \(error)")
                }
            }
        }
        #endif
        
        return fastTags
    }
    
    // Fast heuristic-based tag computation (no AI, instant)
    func computeFastHeuristicTags() -> [String] {
        var tags: [String] = ["instrumental", "ambient"]
        
        guard let book = selectedBook else {
            return tags
        }
        
        let lowerTitle = book.title.lowercased()
        let subjects = book.subjects.map { $0.lowercased() }.joined(separator: " ")
        
        // Genre detection from title/subjects
        if lowerTitle.contains("poem") || lowerTitle.contains("poetry") || subjects.contains("poetry") {
            tags.insert("piano", at: 1)
        } else if lowerTitle.contains("horror") || lowerTitle.contains("gothic") || subjects.contains("horror") {
            tags.insert("dark-ambient", at: 1)
        } else if lowerTitle.contains("romance") || subjects.contains("romance") {
            tags.insert("acoustic", at: 1)
        } else if lowerTitle.contains("adventure") || subjects.contains("adventure") {
            tags.insert("orchestral", at: 1)
        } else if subjects.contains("classical") || subjects.contains("literature") {
            tags.insert("classical", at: 1)
        } else {
            tags.insert("calm", at: 1)
        }
        
        // Add user preference if available
        if let selected = UserDefaults.standard.array(forKey: "selectedGenres") as? [String],
           let first = selected.first,
           !tags.contains(first) {
            tags.append(first)
        }
        
        // Deduplicate and cap to 3
        var seen = Set<String>()
        let final = tags.filter { seen.insert($0).inserted }
        return Array(final.prefix(3))
    }

    func playJamendoCurrent() {
        guard jamendoIndex >= 0, jamendoIndex < jamendoQueue.count else { 
            playbackManager.errorMessage = "No tracks available"
            return 
        }
        let t = jamendoQueue[jamendoIndex]
        
        // Update UI immediately - show track info right away
        playbackManager.currentTitle = "\(t.name) — \(t.artist_name)"
        
        // Play audio (may use cache for instant playback)
        playbackManager.playAudioURL(title: t.name, artist: t.artist_name, urlString: t.audio)
        
        // Preload next track in background (non-blocking)
        preloadNextTrack()
    }
    
    func skipJamendoTrack() {
        guard !jamendoQueue.isEmpty else { return }
        jamendoIndex = (jamendoIndex + 1) % jamendoQueue.count
        playJamendoCurrent()
        
        // Preload the next track after skip
        preloadNextTrack()
    }
}

// MARK: - Reading Settings

struct ReadingSettings {
    var fontSize: CGFloat = 18
    var lineSpacing: CGFloat = 8
    var fontWeight: Font.Weight = .regular
    var darkMode: Bool = false
    var autoScroll: Bool = false
    var dyslexiaFont: Bool = false
}

// MARK: - Reading Settings View

struct ReadingSettingsView: View {
    @Binding var settings: ReadingSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Font Size")
                        Slider(value: $settings.fontSize, in: 14...24, step: 1)
                        Text("\(Int(settings.fontSize))pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Line Spacing")
                        Slider(value: $settings.lineSpacing, in: 4...16, step: 2)
                        Text("\(Int(settings.lineSpacing))pt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Dark Mode", isOn: $settings.darkMode)
                    Toggle("Dyslexia-Friendly Font", isOn: $settings.dyslexiaFont)
                }
                
                Section("Reading") {
                    Toggle("Auto Scroll", isOn: $settings.autoScroll)
                    
                    Picker("Font Weight", selection: $settings.fontWeight) {
                        Text("Regular").tag(Font.Weight.regular)
                        Text("Medium").tag(Font.Weight.medium)
                        Text("Semibold").tag(Font.Weight.semibold)
                        Text("Bold").tag(Font.Weight.bold)
                    }
                }
                
                Section("Music") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adaptive music is playing based on your reading progress and story mood.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "music.note")
                            Text("Spotify Connected")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .navigationTitle("Reading Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#if canImport(FoundationModels)
import FoundationModels
#endif
