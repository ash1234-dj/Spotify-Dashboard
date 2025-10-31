//
//  AuthorDiscoveryView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

struct AuthorDiscoveryView: View {
    @EnvironmentObject var gutendexManager: GutendexManager
    @EnvironmentObject var spotifyManager: SpotifyManager
    @EnvironmentObject var openLibraryManager: OpenLibraryManager
    @StateObject private var foundationModelsManager = FoundationModelsManager()
    
    @State private var searchText = ""
    @State private var selectedAuthor: AuthorSearchResult?
    @State private var showingAuthorDetail = false
    @State private var showingAILessons = false
    @State private var aiLessons = ""
    @State private var isGeneratingLessons = false
    
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
                    
                    // Content
                    ScrollView {
                        if openLibraryManager.isLoading && openLibraryManager.famousAuthorResults.isEmpty {
                            loadingView
                        } else if let errorMessage = openLibraryManager.errorMessage {
                            errorView(message: errorMessage)
                        } else {
                            contentView
                            
                            // Show loading indicator at bottom if still loading more authors
                            if openLibraryManager.isLoading && !openLibraryManager.famousAuthorResults.isEmpty {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.purple)
                                    Text("Loading remaining authors...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Author Discovery")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAuthorDetail) {
                if let author = selectedAuthor {
                    AuthorDetailView(author: author)
                        .environmentObject(openLibraryManager)
                        .environmentObject(foundationModelsManager)
                }
            }
            .sheet(isPresented: $showingAILessons) {
                if let author = selectedAuthor {
                    AILifeLessonsView(author: author, lessons: aiLessons, isGenerating: isGeneratingLessons)
                        .environmentObject(foundationModelsManager)
                }
            }
            .onAppear {
                loadFamousAuthors()
            }
        }
    }
    
    // MARK: - Search Bar
    
    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search authors...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    performSearch()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    openLibraryManager.searchResults = []
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
    
    // MARK: - Content View
    
    var contentView: some View {
        VStack(spacing: 20) {
            if !searchText.isEmpty {
                searchResultsView
            } else {
                famousAuthorsView
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
                ForEach(openLibraryManager.searchResults) { author in
                    AuthorCard(author: author) {
                        selectedAuthor = author
                        showingAuthorDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Famous Authors View
    
    var famousAuthorsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🌟 Famous Authors")
                .font(.headline)
            .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(openLibraryManager.famousAuthorResults) { author in
                    AuthorCard(author: author) {
                        selectedAuthor = author
                        showingAuthorDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)
            
            Text("Loading authors...")
                .foregroundColor(.secondary)
                .font(.subheadline)
            
            Text("This will only take a moment")
                .foregroundColor(.secondary)
                .font(.caption)
                .opacity(0.7)
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
                if searchText.isEmpty {
                    loadFamousAuthors()
                } else {
                    performSearch()
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
        .padding(40)
    }
    
    // MARK: - Helper Functions
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            await openLibraryManager.searchAuthors(query: searchText)
        }
    }
    
    func loadFamousAuthors() {
        Task {
            await openLibraryManager.loadFamousAuthors()
        }
    }
    
    func generateAILessons() {
        guard let author = selectedAuthor else { return }
        
        isGeneratingLessons = true
        showingAILessons = true
        
        Task {
            let lessons = await foundationModelsManager.generateAuthorLifeLessons(for: author)
            
            await MainActor.run {
                aiLessons = lessons
                isGeneratingLessons = false
            }
        }
    }
}

// MARK: - Author Card Component

struct AuthorCard: View {
    let author: AuthorSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Author icon
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
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.purple)
                }
                
                // Author info
                VStack(alignment: .leading, spacing: 8) {
                    Text(author.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let topWork = author.topWork {
                        Text("Famous for: \(topWork)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Author metadata
                    HStack(spacing: 12) {
                        if let birthDate = author.birthDate {
                            Label(formatDate(birthDate), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if let workCount = author.workCount {
                            Label("\(workCount) works", systemImage: "book.fill")
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
    
    func formatDate(_ dateString: String) -> String {
        // Simple date formatting - you can enhance this
        return dateString
    }
}

// MARK: - Author Detail View

struct AuthorDetailView: View {
    let author: AuthorSearchResult
    @EnvironmentObject var openLibraryManager: OpenLibraryManager
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var authorDetail: AuthorDetail?
    @State private var authorWorks: [AuthorWork] = []
    @State private var isLoading = true
    @State private var showingAILessons = false
    @State private var aiLessons = ""
    @State private var isGeneratingLessons = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingView
                    } else if let detail = authorDetail {
                        authorDetailContent(detail: detail)
                    } else {
                        // Fallback content when author details fail to load
                        fallbackAuthorContent
                    }
                }
            }
            .navigationTitle("Author Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAILessons) {
                AILifeLessonsView(author: author, lessons: aiLessons, isGenerating: isGeneratingLessons)
                    .environmentObject(foundationModelsManager)
            }
        }
        .onAppear {
            loadAuthorDetails()
        }
    }
    
    var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading author details...")
                .foregroundColor(.secondary)
        }
        .padding(40)
    }
    
    var fallbackAuthorContent: some View {
        VStack(spacing: 24) {
            // Author Header
            VStack(spacing: 16) {
                // Author Icon
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
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                }
                
                // Name
                Text(author.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Dates
                if let birthDate = author.birthDate, let deathDate = author.deathDate {
                    Text("\(birthDate) - \(deathDate)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let birthDate = author.birthDate {
                    Text("Born: \(birthDate)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Work Count
                if let workCount = author.workCount {
                    Text("\(workCount) works")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding()
            
            // AI Life Lessons Button (only show if data is complete)
            if authorDetail != nil && !authorWorks.isEmpty {
                Button(action: {
                    generateAILessons()
                }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                    
                    Text("Get AI Life Lessons")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isGeneratingLessons {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .foregroundColor(.white)
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
            .disabled(isGeneratingLessons)
            .padding(.horizontal)
            }
            
            // Basic Information
            VStack(alignment: .leading, spacing: 12) {
                Text("Basic Information")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if let topWork = author.topWork {
                    Text("Famous Work: \(topWork)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                if let topSubjects = author.topSubjects, !topSubjects.isEmpty {
                    Text("Subjects: \(topSubjects.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Text("Note: Detailed biography could not be loaded from Open Library.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    func authorDetailContent(detail: AuthorDetail) -> some View {
        VStack(spacing: 24) {
            // Author Header
            VStack(spacing: 16) {
                // Author Icon
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
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                }
                
                // Name
                Text(detail.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Dates
                if let birthDate = detail.birthDate, let deathDate = detail.deathDate {
                    Text("\(birthDate) - \(deathDate)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let birthDate = detail.birthDate {
                    Text("Born: \(birthDate)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // AI Life Lessons Button (only show if data is complete)
            if authorDetail != nil && !authorWorks.isEmpty {
                Button(action: {
                    generateAILessons()
                }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                    
                    Text("Get AI Life Lessons")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isGeneratingLessons {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .foregroundColor(.white)
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
            .disabled(isGeneratingLessons)
            .padding(.horizontal)
            } // Close conditional for AI Life Lessons
            
            // Biography
            if let bio = detail.bio, !bio.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Biography")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
                .padding()
            }
            
            // Works
            if !authorWorks.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notable Works")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(authorWorks.prefix(15)) { work in
                            HStack {
                                Image(systemName: "book.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                
                                Text(work.title)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        if authorWorks.count > 15 {
                            Text("... and \(authorWorks.count - 15) more works")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    func loadAuthorDetails() {
        print("🔄 Loading author details for: \(author.name)")
        isLoading = true
        
        Task {
            let authorId = openLibraryManager.extractAuthorId(from: author.key)
            print("📝 Author ID: \(authorId)")
            
            // Load author details and works in parallel
            async let details = openLibraryManager.getAuthorDetails(authorId: authorId)
            async let authorWorks = openLibraryManager.getAuthorWorks(authorId: authorId)
            
            let (authorDetail, works) = await (details, authorWorks)
            
            await MainActor.run {
                if let detail = authorDetail {
                    self.authorDetail = detail
                    print("✅ Author details loaded: \(detail.name)")
                    if let bio = detail.bio, !bio.isEmpty {
                        print("📖 Biography loaded: \(bio.prefix(100))...")
                    } else {
                        print("⚠️ No biography available for this author")
                    }
                } else {
                    print("❌ Failed to load author details")
                }
                
                self.authorWorks = works
                self.isLoading = false
                print("📚 Author works loaded: \(works.count) works")
                
                // Log summary for AI lessons
                let summary = createAuthorSummary()
                print("🤖 AI Summary created: \(summary.count) characters")
            }
        }
    }
    
    func generateAILessons() {
        isGeneratingLessons = true
        showingAILessons = true
        
        Task {
            // Create a comprehensive summary from the detailed author information
            let authorSummary = createAuthorSummary()
            let lessons = await foundationModelsManager.generateAuthorLifeLessons(for: author, withSummary: authorSummary)
            
            await MainActor.run {
                aiLessons = lessons
                isGeneratingLessons = false
            }
        }
    }
    
    func createAuthorSummary() -> String {
        var summary = "Author: \(author.name)\n"
        
        if let birthDate = author.birthDate {
            summary += "Birth Date: \(birthDate)\n"
        }
        
        if let deathDate = author.deathDate {
            summary += "Death Date: \(deathDate)\n"
        }
        
        if let topWork = author.topWork {
            summary += "Famous Work: \(topWork)\n"
        }
        
        if let workCount = author.workCount {
            summary += "Total Works: \(workCount)\n"
        }
        
        if let topSubjects = author.topSubjects, !topSubjects.isEmpty {
            summary += "Main Subjects: \(topSubjects.joined(separator: ", "))\n"
        }
        
        // Add detailed information if available
        if let detail = authorDetail {
            if let bio = detail.bio, !bio.isEmpty {
                summary += "\nBiography: \(bio)\n"
            }
            
            if let personalName = detail.personalName {
                summary += "Personal Name: \(personalName)\n"
            }
            
            if let works = detail.authorWorks, !works.isEmpty {
                summary += "\nNotable Works:\n"
                for work in works.prefix(10) {
                    summary += "- \(work.title)\n"
                }
            }
        }
        
        // Add works from the separate works array (more comprehensive)
        if !authorWorks.isEmpty {
            summary += "\nComplete Works List:\n"
            for work in authorWorks.prefix(15) {
                summary += "- \(work.title)\n"
            }
            if authorWorks.count > 15 {
                summary += "... and \(authorWorks.count - 15) more works\n"
            }
        }
        
        return summary
    }
}

// MARK: - AI Life Lessons View

struct AILifeLessonsView: View {
    let author: AuthorSearchResult
    let lessons: String
    let isGenerating: Bool
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                        
                        Text("AI Life Lessons")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("From \(author.name)'s Life")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Lessons Content
                    if isGenerating {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Generating life lessons...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                    } else if !lessons.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Life Lessons & Insights")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(lessons)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .lineSpacing(6)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Life Lessons")
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
