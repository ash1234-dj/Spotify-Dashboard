//
//  StorySelectionView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

struct StorySelectionView: View {
    @EnvironmentObject var gutendexManager: GutendexManager
    
    
    @State private var searchText = ""
    @State private var showingBookDetail = false
    @State private var selectedBook: GutendexBook?
    @State private var searchCategory = SearchCategory.all
    @State private var showingMoodDropdown = false
    
    enum SearchCategory: String, CaseIterable {
        case all = "All"
        case popular = "Popular"
        case recent = "Recent"
        
        var icon: String {
            switch self {
            case .all: return "book.fill"
            case .popular: return "flame.fill"
            case .recent: return "clock.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                    
                    // Category Tabs
                    categoryTabs
                    
                    // Content
                    ScrollView {
                        if gutendexManager.isLoading {
                            loadingView
                        } else if let errorMessage = gutendexManager.errorMessage {
                            errorView(message: errorMessage)
                        } else {
                            contentView
                        }
                    }
                }
            }
            .navigationTitle("Story Library")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingBookDetail) {
                if let book = selectedBook {
                    BookDetailView(book: book)
                        .environmentObject(gutendexManager)
                }
            }
            .onAppear {
                loadInitialBooks()
            }
        }
    }
    
    // MARK: - Search Bar
    
    var searchBar: some View {
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
        .padding(.top, 8)
    }
    
    // MARK: - Category Tabs
    
    var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SearchCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            searchCategory = category
                            updateContentForCategory()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.caption)
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(searchCategory == category ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            searchCategory == category ?
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [Color.gray.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Content View
    
    var contentView: some View {
        VStack(spacing: 20) {
            switch searchCategory {
            case .all:
                if !gutendexManager.searchResults.isEmpty {
                    searchResultsView
                } else if !gutendexManager.allBooks.isEmpty {
                    // Show all books when no search
                    allBooksView
                } else {
                    allBooksEmptyState
                }
            case .popular:
                if !gutendexManager.popularBooks.isEmpty {
                    popularBooksView
                } else {
                    popularBooksEmptyState
                }
            case .recent:
                if !gutendexManager.gutendexRecentBooks.isEmpty {
                    recentBooksView
                } else {
                    recentBooksEmptyState
                }
            }
        }
        .padding()
    }
    
    // MARK: - Search Results View
    
    var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(gutendexManager.searchResults) { book in
                    BookCard(book: book) {
                        selectedBook = book
                        showingBookDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - All Books View (shows all books)
    
    var allBooksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📚 All Books")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(gutendexManager.allBooks) { book in
                    BookCard(book: book) {
                        selectedBook = book
                        showingBookDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Popular Books View
    
    var popularBooksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with mood dropdown
            HStack {
                Text("🔥 Popular Books")
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
            LazyVStack(spacing: 12) {
                ForEach(gutendexManager.getCurrentMoodBooks()) { book in
                    BookCard(book: book) {
                        selectedBook = book
                        showingBookDetail = true
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
                    Task {
                        await gutendexManager.fetchBooksByMood(mood)
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
    
    // MARK: - Recent Books View (shows recently added to Gutendex)
    
    var recentBooksView: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVStack(spacing: 12) {
                ForEach(gutendexManager.gutendexRecentBooks) { book in
                    BookCard(book: book) {
                        selectedBook = book
                        showingBookDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    var allBooksEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("Loading Books...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Fetching popular books from Gutenberg Project")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    var popularBooksEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.5))
            
            Text("Loading Popular Books...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Fetching trending books from Gutenberg Project")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    var recentBooksEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("Loading Recent Books...")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Fetching recently added books from Gutendex")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Loading View
    
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading books...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Error View
    
    func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.5))
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                loadInitialBooks()
            }) {
                Text("Retry")
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(10)
            }
        }
        .padding(40)
    }
    
    // MARK: - Helper Functions
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await gutendexManager.searchBooks(query: searchText)
        }
    }
    
    func loadInitialBooks() {
        Task {
            // Fetch both popular books and recently added books
            await gutendexManager.getPopularBooks()
            await gutendexManager.getRecentlyAddedBooks()
            
            // Initialize mood-based books with "All" mood (shows popular books)
            await gutendexManager.fetchBooksByMood(.all)
        }
    }
    
    func updateContentForCategory() {
        switch searchCategory {
        case .all:
            // Keep current content
            break
        case .popular:
            // Popular books already loaded
            break
        case .recent:
            // Recent books already loaded
            break
        }
    }
}

// MARK: - Book Card Component

struct BookCard: View {
    let book: GutendexBook
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
}

// MARK: - Book Detail View

struct BookDetailView: View {
    let book: GutendexBook
    @EnvironmentObject var gutendexManager: GutendexManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isFetchingContent = false
    @State private var showingReader = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Book Header
                    VStack(spacing: 16) {
                        // Book Icon
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
                        
                        // Title
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Author
                        Text("by \(book.primaryAuthor)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Book Info
                    VStack(spacing: 16) {
                        BookInfoRow(icon: "arrow.down.circle.fill", title: "Downloads", value: "\(book.download_count)")
                        BookInfoRow(icon: "globe", title: "Languages", value: book.languages.joined(separator: ", "))
                        BookInfoRow(icon: "bookmark.fill", title: "Subjects", value: book.subjects.prefix(3).joined(separator: ", "))
                    }
                    .padding()
                    
                    // Start Reading Button
                    Button(action: {
                        startReading()
                    }) {
                        HStack {
                            if isFetchingContent {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "book.fill")
                                Text("Start Reading")
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
                    .disabled(isFetchingContent)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func startReading() {
        isFetchingContent = true
        
        Task {
            await gutendexManager.fetchBookContent(for: book)
            
            // Add to recent books
            gutendexManager.addToRecentBooks(book)
            
            await MainActor.run {
                isFetchingContent = false
                showingReader = true
            }
        }
    }
}

// MARK: - Book Info Row Component

struct BookInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

