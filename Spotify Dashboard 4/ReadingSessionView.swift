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
    
    // MARK: - Music Controls Bar
    
    var musicControlsBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 20) {
                // Play/Pause button
                Button(action: {
                    toggleMusic()
                }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .disabled(playbackManager.isLoading)
                
                VStack(alignment: .leading, spacing: 3) {
                    // Primary title shows current track or fallback label
                    Text(playbackManager.currentTitle ?? "Adaptive Mix")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Subtitle with tags and picker
                    Button(action: { showTrackPicker = true }) {
                        let tagsText = lastUsedTags.isEmpty ? "Tap to choose" : "Tap to choose • " + lastUsedTags.joined(separator: " • ")
                        Text(tagsText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .buttonStyle(.plain)
                    
                    if playbackManager.isLoading {
                        Text("Loading tracks…")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Skip button
                Button(action: { skipJamendoTrack() }) {
                    Image(systemName: "forward.end.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .disabled(jamendoQueue.count <= 1 || playbackManager.isLoading)
                
                // Volume control
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(playbackManager.volume * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Volume slider
                VStack {
                    Slider(value: Binding(
                        get: { playbackManager.volume },
                        set: { playbackManager.setVolume($0) }
                    ), in: 0...1)
                    .frame(width: 80)
                    
                    Text("Volume")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Show error message if any
            if let errorMessage = playbackManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
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
        
        Task {
            do {
                // Add timeout to prevent hanging
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        await gutendexManager.fetchBookContent(for: book)
                    }
                    
                    group.addTask {
                        try await Task.sleep(nanoseconds: 30_000_000_000) // 30 second timeout
                        throw URLError(.timedOut)
                    }
                    
                    try await group.next() // Wait for first task to complete
                    group.cancelAll() // Cancel remaining tasks
                }
                
                // Check if content was loaded successfully
                if let bookContent = gutendexManager.bookContent {
                    gutendexManager.addToRecentBooks(book)
                    
                    // Format and paginate the text into pages of 200-250 words
                    let formattedText = gutendexManager.formatBookContent(bookContent.text)
                    let paginated = paginateText(formattedText, wordsPerPage: 225)
                    
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
    
    // MARK: - Pagination Helper
    
    func paginateText(_ text: String, wordsPerPage: Int) -> [String] {
        // Split text into words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // If text is too large, process in chunks to prevent memory issues
        if words.count > 10000 {
            return paginateLargeText(words: words, wordsPerPage: wordsPerPage)
        }
        
        var pages: [String] = []
        var currentPageWords: [String] = []
        
        for word in words {
            currentPageWords.append(word)
            
            // When we reach wordsPerPage, create a page
            if currentPageWords.count >= wordsPerPage {
                let pageText = currentPageWords.joined(separator: " ")
                pages.append(pageText)
                currentPageWords.removeAll()
            }
        }
        
        // Add remaining words as last page
        if !currentPageWords.isEmpty {
            let pageText = currentPageWords.joined(separator: " ")
            pages.append(pageText)
        }
        
        print("📄 Created \(pages.count) pages from \(words.count) words")
        return pages
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
        if playbackManager.isPlaying {
            playbackManager.pausePlayback()
        } else {
            Task {
                await startAdaptiveMusic()
            }
        }
    }
    
    func startAdaptiveMusic() async {
        let tags = await computeJamendoTags()
        await MainActor.run { lastUsedTags = tags }
        // Try combined tags first; if empty, fall back to individual tags in order
        let joinTag = tags.joined(separator: ",")
        await jamendoManager.fetchTracks(tag: joinTag, limit: 20)
        var foundList: [JamendoTrack] = jamendoManager.tracks
        if foundList.isEmpty {
            for t in tags {
                await jamendoManager.fetchTracks(tag: t, limit: 20)
                if !jamendoManager.tracks.isEmpty { foundList = jamendoManager.tracks; break }
            }
        }
        if let first = foundList.first {
            jamendoQueue = foundList
            jamendoIndex = 0
            playJamendoCurrent()
        } else {
            playbackManager.errorMessage = jamendoManager.errorMessage ?? "No Jamendo tracks found for tags: \(tags.joined(separator: ", "))"
        }
    }

    // Compute Jamendo tags using Apple Foundation Models if available, else fallback heuristics
    func computeJamendoTags() async -> [String] {
        // Base safe set for reading
        var tags: [String] = ["instrumental", "ambient", "calm"]
        
        // Try to tailor to the current book
        var context = ""
        if let book = selectedBook {
            context += "Title: \(book.title)\nAuthor: \(book.primaryAuthor)\nSubjects: \(book.subjects.prefix(5).joined(separator: ", "))\n"
        }
        if let content = gutendexManager.bookContent {
            context += "Sample: \(String(content.text.prefix(800)))"
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), !context.isEmpty {
            do {
                let session = LanguageModelSession()
                let prompt = """
                You are choosing background music tags for silent reading. Return 3 short comma-separated Jamendo tags that are suitable for reading and match the book context. Prefer instrumental, ambient, calm textures. Choose from tags like: instrumental, ambient, classical, piano, strings, lo-fi, acoustic, meditation, focus.
                Context:
                \(context)
                Output only tags, comma-separated, no extra text.
                """
                let response = try await session.respond(to: prompt, options: GenerationOptions(temperature: 0.3, maximumResponseTokens: 20))
                let raw = response.content.lowercased()
                let parsed = raw
                    .replacingOccurrences(of: "\n", with: ",")
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !parsed.isEmpty { return Array(parsed.prefix(3)) }
            } catch {
                // fall back below
            }
        }
        #endif
        
        // Heuristic fallback: map subjects/title keywords
        let lowerTitle = selectedBook?.title.lowercased() ?? ""
        if lowerTitle.contains("poem") || lowerTitle.contains("poetry") {
            tags.insert("piano", at: 0)
        } else if lowerTitle.contains("horror") || lowerTitle.contains("gothic") {
            tags.insert("dark-ambient", at: 0)
        } else if lowerTitle.contains("romance") {
            tags.insert("acoustic", at: 0)
        } else if lowerTitle.contains("adventure") {
            tags.insert("orchestral", at: 0)
        }
        
        if let selected = UserDefaults.standard.array(forKey: "selectedGenres") as? [String], let first = selected.first {
            tags.append(first)
        }
        
        // Deduplicate and cap to 3
        var seen = Set<String>()
        let final = tags.filter { seen.insert($0).inserted }
        return Array(final.prefix(3))
    }

    func playJamendoCurrent() {
        guard jamendoIndex >= 0, jamendoIndex < jamendoQueue.count else { return }
        let t = jamendoQueue[jamendoIndex]
        playbackManager.playAudioURL(title: t.name, artist: t.artist_name, urlString: t.audio)
    }
    
    func skipJamendoTrack() {
        guard !jamendoQueue.isEmpty else { return }
        jamendoIndex = (jamendoIndex + 1) % jamendoQueue.count
        playJamendoCurrent()
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
