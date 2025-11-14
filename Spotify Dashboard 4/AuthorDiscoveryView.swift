//
//  AuthorDiscoveryView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI

struct AuthorDiscoveryView: View {
    @EnvironmentObject var gutendexManager: GutendexManager
    @EnvironmentObject var openLibraryManager: OpenLibraryManager
    @StateObject private var wikidataManager = WikidataManager()
    @StateObject private var foundationModelsManager = FoundationModelsManager()
    
    // Force UI updates when Wikidata data arrives
    @State private var refreshTrigger = 0
    
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
                        .environmentObject(wikidataManager)
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
                    .environmentObject(openLibraryManager)
                    .environmentObject(wikidataManager)
                    .id("\(author.id)-\(refreshTrigger)") // Force refresh when Wikidata data arrives
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
                    .environmentObject(openLibraryManager)
                    .environmentObject(wikidataManager)
                    .id("\(author.id)-\(refreshTrigger)") // Force refresh when Wikidata data arrives
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
        guard !searchText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else { return }
        
        Task {
            // Search Open Library (shows results immediately)
            await openLibraryManager.searchAuthors(query: searchText)
            
            // CRITICAL: INSTANTLY fetch Wikidata data for ALL search results in parallel (not detached - immediate start)
            let searchResultNames = openLibraryManager.searchResults.map { $0.name }
            if !searchResultNames.isEmpty {
                print("🌐 INSTANT: Fetching Wikidata data for ALL \(searchResultNames.count) search results...")
                // Start immediately (don't detach - we want it to start right away)
                Task {
                    await self.wikidataManager.fetchAuthorInfoBatch(authorNames: searchResultNames)
                    print("✅ Wikidata data INSTANTLY loaded for ALL \(searchResultNames.count) search results")
                    
                    // Force UI update when Wikidata data arrives
                    await MainActor.run {
                        // Trigger UI refresh to show biographies instantly in cards
                        refreshTrigger += 1
                    }
                }
            }
        }
    }
    
    func loadFamousAuthors() {
        Task {
            // Load famous authors from Open Library (shows immediately)
            await openLibraryManager.loadFamousAuthors()
            
            // CRITICAL: INSTANTLY fetch Wikidata data for ALL authors in parallel (not detached - immediate start)
            let authorNames = openLibraryManager.famousAuthorResults.map { $0.name }
            if !authorNames.isEmpty {
                print("🌐 INSTANT: Fetching Wikidata data for ALL \(authorNames.count) famous authors...")
                // Start immediately (don't detach - we want it to start right away)
                Task {
                    await self.wikidataManager.fetchAuthorInfoBatch(authorNames: authorNames)
                    print("✅ Wikidata data INSTANTLY loaded for ALL \(authorNames.count) authors")
                    
                    // Force UI update when Wikidata data arrives
                    await MainActor.run {
                        // Trigger UI refresh to show biographies instantly in cards
                        refreshTrigger += 1
                    }
                }
            }
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
    @EnvironmentObject var openLibraryManager: OpenLibraryManager
    @EnvironmentObject var wikidataManager: WikidataManager
    @State private var biographyPreview: String?
    @State private var isLoadingBio = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Author cover
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                    
                    if let url = authorPhotoURL {
                        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.purple)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.purple)
                    }
                }
                .frame(width: 60, height: 80)
                
                // Author info
                VStack(alignment: .leading, spacing: 6) {
                    Text(author.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Show biography preview if available
                    if let bio = biographyPreview, !bio.isEmpty {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    } else if let topWork = author.topWork {
                        Text("Famous for: \(topWork)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Author metadata
                    HStack(spacing: 12) {
                        if let birthDate = author.birthDate {
                            Label(formatDate(birthDate), systemImage: "calendar")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        if let workCount = author.workCount {
                            Label("\(workCount) works", systemImage: "book.fill")
                                .font(.caption2)
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
        .onAppear {
            loadBiographyPreview()
        }
    }
    
    func loadBiographyPreview() {
        // CRITICAL: Check both caches first for instant display
        let authorId = openLibraryManager.extractAuthorId(from: author.key)
        
        // Check Open Library cache (instant)
        if let detail = openLibraryManager.authorDetails[authorId],
           let bio = detail.bio, !bio.isEmpty {
            biographyPreview = String(bio.prefix(100)) + (bio.count > 100 ? "..." : "")
            
            if let photoId = detail.photos?.first {
                let urlString = openLibraryManager.getAuthorPhotoURL(photoId: photoId)
                if let url = URL(string: urlString) {
                    openLibraryManager.authorPhotoURLs[authorId] = url
                }
            }
            return
        }
        
        // CRITICAL: Check Wikidata cache FIRST (instant - PRIMARY source)
        // Also check if batch fetch is in progress (data might arrive soon)
        if let wikidataInfo = wikidataManager.authorInfo.values.first(where: { $0.name == author.name }) {
            if let bio = wikidataInfo.biography, !bio.isEmpty {
                biographyPreview = String(bio.prefix(100)) + (bio.count > 100 ? "..." : "")
                if let imageString = wikidataInfo.imageURL,
                   let url = URL(string: imageString),
                   openLibraryManager.authorPhotoURLs[authorId] == nil {
                    openLibraryManager.authorPhotoURLs[authorId] = url
                }
                return
            } else if let desc = wikidataInfo.description, !desc.isEmpty {
                biographyPreview = String(desc.prefix(100)) + (desc.count > 100 ? "..." : "")
                if let imageString = wikidataInfo.imageURL,
                   let url = URL(string: imageString),
                   openLibraryManager.authorPhotoURLs[authorId] == nil {
                    openLibraryManager.authorPhotoURLs[authorId] = url
                }
                return
            }
        }
        
        // CRITICAL: Load biography FAST - Open Library FIRST (usually faster!), Wikidata as enhancement
        // Show immediately from whichever responds first
        if biographyPreview == nil && !isLoadingBio {
            isLoadingBio = true
            
            // Priority 1: Open Library (FASTEST - show immediately!)
            Task {
                let detail = await openLibraryManager.getAuthorDetails(authorId: authorId)
                await MainActor.run {
                    if let bio = detail?.bio, !bio.isEmpty {
                        biographyPreview = String(bio.prefix(100)) + (bio.count > 100 ? "..." : "")
                        isLoadingBio = false
                        print("✅ Open Library bio INSTANT for: \(author.name)")
                        // Notify UI to refresh
                        NotificationCenter.default.post(name: NSNotification.Name("AuthorDataUpdated"), object: nil)
                        return
                    }
                    // If no bio, mark as done loading
                    isLoadingBio = false
                }
            }
            
            // Priority 2: Wikidata (enhancement - don't wait, show if available)
            Task {
                // Check cache first
                if let wikidataInfo = wikidataManager.authorInfo.values.first(where: { $0.name == author.name }) {
                    await MainActor.run {
                        if biographyPreview == nil, let bio = wikidataInfo.biography ?? wikidataInfo.description, !bio.isEmpty {
                            biographyPreview = String(bio.prefix(100)) + (bio.count > 100 ? "..." : "")
                            isLoadingBio = false
                            print("✅ Wikidata bio from cache INSTANT for: \(author.name)")
                            
                            if let imageString = wikidataInfo.imageURL,
                               let url = URL(string: imageString),
                               openLibraryManager.authorPhotoURLs[authorId] == nil {
                                openLibraryManager.authorPhotoURLs[authorId] = url
                            }
                            return
                        }
                    }
                }
                
                // If no cache, fetch with short timeout
                do {
                    let wikidata = try await withThrowingTaskGroup(of: WikidataAuthorInfo?.self) { group in
                        group.addTask {
                            return await wikidataManager.getAuthorInfo(authorName: author.name)
                        }
                        
                        // Timeout after 1.5 seconds (fast!)
                        group.addTask {
                            try await Task.sleep(nanoseconds: 1_500_000_000)
                            return nil as WikidataAuthorInfo?
                        }
                        
                        let result = try await group.next()
                        group.cancelAll()
                        return result ?? nil
                    }
                    
                    await MainActor.run {
                        // Only use Wikidata if Open Library didn't provide bio
                        if biographyPreview == nil, let bio = wikidata?.biography ?? wikidata?.description, !bio.isEmpty {
                            biographyPreview = String(bio.prefix(100)) + (bio.count > 100 ? "..." : "")
                            print("✅ Wikidata bio loaded for: \(author.name)")
                            
                            if let imageString = wikidata?.imageURL,
                               let url = URL(string: imageString),
                               openLibraryManager.authorPhotoURLs[authorId] == nil {
                                openLibraryManager.authorPhotoURLs[authorId] = url
                            }
                        }
                        if biographyPreview == nil {
                            isLoadingBio = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        if biographyPreview == nil {
                            isLoadingBio = false
                        }
                    }
                }
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        return dateString
    }
    
    private var authorPhotoURL: URL? {
        let authorId = openLibraryManager.extractAuthorId(from: author.key)
        
        if let cached = openLibraryManager.authorPhotoURLs[authorId] {
            return cached
        }
        
        if let wikidataMatch = wikidataManager.authorInfo.values.first(where: { info in
            if info.name.caseInsensitiveCompare(author.name) == .orderedSame {
                return true
            }
            if let alternates = author.alternateNames {
                return alternates.contains {
                    $0.caseInsensitiveCompare(info.name) == .orderedSame ||
                    $0.localizedCaseInsensitiveContains(info.name) ||
                    info.name.localizedCaseInsensitiveContains($0)
                }
            }
            return false
        }),
        let imageString = wikidataMatch.imageURL,
        let url = URL(string: imageString) {
            return url
        }
        
        return nil
    }
}

// MARK: - Author Detail View

struct AuthorDetailView: View {
    let author: AuthorSearchResult
    @EnvironmentObject var openLibraryManager: OpenLibraryManager
    @EnvironmentObject var wikidataManager: WikidataManager
    @EnvironmentObject var foundationModelsManager: FoundationModelsManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var authorDetail: AuthorDetail?
    @State private var authorWorks: [AuthorWork] = []
    @State private var wikidataInfo: WikidataAuthorInfo?
    @State private var isLoading = true
    @State private var showingAILessons = false
    @State private var aiLessons = ""
    @State private var isGeneratingLessons = false
    
    private var authorPhotoURL: URL? {
        let authorId = openLibraryManager.extractAuthorId(from: author.key)
        
        if let cached = openLibraryManager.authorPhotoURLs[authorId] {
            return cached
        }
        
        if let photoId = authorDetail?.photos?.first ?? openLibraryManager.authorDetails[authorId]?.photos?.first {
            let urlString = openLibraryManager.getAuthorPhotoURL(photoId: photoId)
            return URL(string: urlString)
        }
        
        if let wikidata = (wikidataInfo ?? wikidataManager.authorInfo.values.first(where: self.matchesAuthorName)),
           let imageString = wikidata.imageURL {
            return URL(string: imageString)
        }
        
        return nil
    }
    
    private var authorImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
            
            if let url = authorPhotoURL {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.purple)
            }
        }
        .frame(width: 120, height: 160)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // CRITICAL: ALWAYS show content immediately - never show loading!
                    if let detail = authorDetail {
                        authorDetailContent(detail: detail)
                    } else {
                        // ALWAYS show basic info with AI button - data loads silently
                        authorBasicInfo
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
                authorImageView
                
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
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    var authorBasicInfo: some View {
        VStack(spacing: 24) {
            // Author Header (basic)
            VStack(spacing: 16) {
                authorImageView
                
                Text(author.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let birth = author.birthDate {
                    Text("Born: \(birth)")
                        .font(.headline)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            
            // AI Life Lessons Button - ALWAYS SHOW FOR EVERY AUTHOR
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
            
            // Biography section - ALWAYS SHOW (loads instantly)
            VStack(alignment: .leading, spacing: 12) {
                Text("Biography")
                    .font(.headline)
                    .fontWeight(.bold)
                
                BiographyView(
                    author: author,
                    authorDetail: authorDetail,
                    wikidataInfo: wikidataInfo,
                    openLibraryManager: openLibraryManager,
                    wikidataManager: wikidataManager,
                    loadAllAuthorData: { await loadAllAuthorData() }
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Works section - ALWAYS SHOW (loads instantly)
            let allWorks = combineWorks()
            VStack(alignment: .leading, spacing: 16) {
                Text("Notable Works")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                if !allWorks.isEmpty {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(allWorks.prefix(20).enumerated()), id: \.offset) { index, work in
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
                        
                        if allWorks.count > 20 {
                            Text("... and \(allWorks.count - 20) more works")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                } else {
                    // Show at least top work if available
                    if let topWork = author.topWork {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            
                            Text(topWork)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    func authorDetailContent(detail: AuthorDetail) -> some View {
        VStack(spacing: 24) {
            // Author Header
            VStack(spacing: 16) {
                authorImageView
                
                // Name - Use Wikidata name if available (usually more complete), otherwise Open Library
                let displayName = wikidataInfo?.name ?? detail.name
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Dates - Combined from both sources
                let displayBirthDate = wikidataInfo?.birthDate ?? detail.birthDate ?? author.birthDate
                let displayDeathDate = wikidataInfo?.deathDate ?? detail.deathDate ?? author.deathDate
                
                if let birth = displayBirthDate, let death = displayDeathDate {
                    Text("\(birth) - \(death)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else if let birth = displayBirthDate {
                    Text("Born: \(birth)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Occupation - From Wikidata
                if let wikidata = wikidataInfo, !wikidata.occupations.isEmpty {
                    Text(wikidata.occupations.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .padding(.top, 4)
                }
            }
            .padding()
            
            // AI Life Lessons Button - ALWAYS show for EVERY author (check all sources including cache)
            let authorId = openLibraryManager.extractAuthorId(from: author.key)
            let cachedDetail = openLibraryManager.authorDetails[authorId]
            let cachedWikidata = wikidataManager.authorInfo.values.first(where: { $0.name == author.name })
            
            // Check bio from ALL sources (current + cache + both APIs)
            let hasBioData = 
                (detail.bio != nil && !detail.bio!.isEmpty) || 
                (cachedDetail?.bio != nil && !cachedDetail!.bio!.isEmpty) ||
                (wikidataInfo?.biography != nil && !wikidataInfo!.biography!.isEmpty) ||
                (cachedWikidata?.biography != nil && !cachedWikidata!.biography!.isEmpty) ||
                (wikidataInfo?.description != nil && !wikidataInfo!.description!.isEmpty) ||
                (cachedWikidata?.description != nil && !cachedWikidata!.description!.isEmpty)
            
            // Check works from ALL sources
            let hasWorksData = 
                !authorWorks.isEmpty || 
                (wikidataInfo?.works.isEmpty == false) ||
                (cachedWikidata?.works.isEmpty == false) ||
                (author.workCount ?? 0) > 0 ||
                (cachedDetail?.authorWorks?.isEmpty == false) ||
                (detail.authorWorks?.isEmpty == false)
            
            // CRITICAL: ALWAYS show AI button for EVERY author - NO CONDITIONS!
            // AI functionality works with ANY author - even just name and basic info
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
            
            // Biography - Combined from both sources
                VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Biography")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Show data sources
                    HStack(spacing: 8) {
                        if detail.bio != nil {
                            Image(systemName: "book.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        if wikidataInfo != nil {
                            Image(systemName: "globe")
                                .font(.caption)
                                .foregroundColor(.purple)
                        }
                    }
                }
                
                // CRITICAL: Prioritize Wikidata FIRST, then Open Library, then cache
                BiographyView(
                    author: author,
                    authorDetail: authorDetail,
                    wikidataInfo: wikidataInfo,
                    openLibraryManager: openLibraryManager,
                    wikidataManager: wikidataManager,
                    loadAllAuthorData: { await loadAllAuthorData() }
                )
                .id("\(author.id)-\(authorDetail?.name ?? "")-\(wikidataInfo?.name ?? "")")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Works - Combined from both sources
            let allWorks = combineWorks()
            if !allWorks.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                    Text("Notable Works")
                        .font(.headline)
                        .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Show sources
                        HStack(spacing: 8) {
                            if !authorWorks.isEmpty {
                                Image(systemName: "book.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if let wikidata = wikidataInfo, !wikidata.works.isEmpty {
                                Image(systemName: "globe")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(Array(allWorks.prefix(20).enumerated()), id: \.offset) { index, work in
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
                        
                        if allWorks.count > 20 {
                            Text("... and \(allWorks.count - 20) more works")
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
        isLoading = true
        Task {
            await loadAllAuthorData()
        }
    }
    
    func combineWorks() -> [(title: String, source: String)] {
        var works: [(title: String, source: String)] = []
        var seenTitles = Set<String>()
        
        // CRITICAL: Check ALL sources including cache
            let authorId = openLibraryManager.extractAuthorId(from: author.key)
        let cachedWikidata = wikidataManager.authorInfo.values.first(where: { $0.name == author.name })
        let cachedDetail = openLibraryManager.authorDetails[authorId]
        
        // Priority 1: Wikidata works (current or cached)
        if let wikidata = wikidataInfo ?? cachedWikidata {
            for work in wikidata.works {
                let title = work.title.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !seenTitles.contains(title) {
                    works.append((work.title, "Wikidata"))
                    seenTitles.insert(title)
                }
            }
        }
        
        // Priority 2: Open Library works from current list
        for work in authorWorks {
            let title = work.title.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !seenTitles.contains(title) {
                works.append((work.title, "Open Library"))
                seenTitles.insert(title)
            }
        }
        
        // Priority 3: Open Library works from detail object (current or cached)
        if let detail = authorDetail ?? cachedDetail, let detailWorks = detail.authorWorks {
            for work in detailWorks {
                let title = work.title.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !seenTitles.contains(title) {
                    works.append((work.title, "Open Library"))
                    seenTitles.insert(title)
                }
            }
        }
        
        return works
    }
    
    func loadAllAuthorData() async {
        print("🔄 Loading author data INSTANTLY for: \(author.name)")
        
        let authorId = openLibraryManager.extractAuthorId(from: author.key)
        print("📝 Open Library Author ID: \(authorId)")
        
        // CRITICAL: Check ALL caches FIRST for INSTANT display (no loading state!)
        // Priority: Open Library cache first (usually has data), then Wikidata
        
        // ALWAYS start with isLoading = false (never show loading!)
        await MainActor.run {
            self.isLoading = false
        }
        
        // Check Open Library cache FIRST (most reliable)
        if let cachedDetail = openLibraryManager.authorDetails[authorId] {
            await MainActor.run {
                self.authorDetail = cachedDetail
                print("✅ INSTANT: Cached Open Library - Bio: \(cachedDetail.bio?.count ?? 0) chars")
            }
        }
        
        // Check Open Library works cache
        if let cachedWorks = openLibraryManager.authorWorks[authorId], !cachedWorks.isEmpty {
            await MainActor.run {
                self.authorWorks = cachedWorks
                print("✅ INSTANT: Cached works - \(cachedWorks.count) items")
            }
        }
        
        // Check Wikidata cache (enhancement)
        if let cachedWikidata = wikidataManager.authorInfo.values.first(where: { $0.name == author.name }) {
            await MainActor.run {
                self.wikidataInfo = cachedWikidata
                print("✅ INSTANT: Cached Wikidata - Bio: \(cachedWikidata.biography?.count ?? 0) chars")
            }
        }
        
        // CRITICAL: Fetch both APIs in parallel - show FIRST one that responds (fastest wins!)
        // Don't wait for both - show immediately from whichever responds first
        
        // Priority 1: Open Library (usually faster - show this first!)
        // CRITICAL: Load immediately and show without delay
        Task {
            let detail = await openLibraryManager.getAuthorDetails(authorId: authorId)
            if let detail = detail {
                await MainActor.run {
                    self.authorDetail = detail
                    // Always show Open Library data immediately (don't wait!)
                    self.isLoading = false
                    print("✅ Open Library INSTANT: \(detail.name) - Bio: \(detail.bio?.count ?? 0) chars")
                    
                    if let photoId = detail.photos?.first {
                        let urlString = openLibraryManager.getAuthorPhotoURL(photoId: photoId)
                        if let url = URL(string: urlString) {
                            openLibraryManager.authorPhotoURLs[authorId] = url
                        }
                    }
                    // Notify that data has updated
                    NotificationCenter.default.post(name: NSNotification.Name("AuthorDataUpdated"), object: nil)
                }
            } else {
                // If Open Library fails, still show UI (don't block on loading)
                await MainActor.run {
                    self.isLoading = false // Never block UI
                }
            }
        }
        
        // Priority 2: Open Library works (fetch immediately - don't wait)
        Task {
            let works = await openLibraryManager.getAuthorWorks(authorId: authorId)
            await MainActor.run {
                self.authorWorks = works
                // Always show works if available
                if !works.isEmpty {
                    if self.isLoading {
                        self.isLoading = false // Show works immediately
                    }
                    print("✅ Open Library works INSTANT: \(works.count) works")
                    // Notify that data has updated
                    NotificationCenter.default.post(name: NSNotification.Name("AuthorDataUpdated"), object: nil)
                }
            }
        }
        
        // Priority 3: Wikidata (in background - enhance if available, but don't wait)
        Task {
            do {
                let wikidata = try await withThrowingTaskGroup(of: WikidataAuthorInfo?.self) { group in
                    group.addTask {
                        return await self.wikidataManager.getAuthorInfo(authorName: author.name)
                    }
                    
                    // Timeout after 2 seconds (don't wait too long)
                    group.addTask {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                        return nil as WikidataAuthorInfo?
                    }
                    
                    let result = try await group.next()
                    group.cancelAll()
                    return result ?? nil
                }
                
                if let wikidata = wikidata {
                    await MainActor.run {
                        self.wikidataInfo = wikidata
                        print("✅ Wikidata enhanced data: \(wikidata.name) - Bio: \(wikidata.biography?.count ?? 0) chars, Works: \(wikidata.works.count)")
                        
                        if openLibraryManager.authorPhotoURLs[authorId] == nil,
                            let imageString = wikidata.imageURL,
                            let url = URL(string: imageString) {
                            openLibraryManager.authorPhotoURLs[authorId] = url
                        }
                        // Notify that data has updated
                        NotificationCenter.default.post(name: NSNotification.Name("AuthorDataUpdated"), object: nil)
                    }
                }
            } catch {
                // Wikidata failed - Open Library already shown, so ignore
                print("⚠️ Wikidata failed - Open Library already providing data")
            }
        }
        
        // CRITICAL: Don't wait - show data immediately as it arrives!
        // Open Library already set isLoading = false above
        // This ensures UI is never blocked
        
        await MainActor.run {
            // Ensure loading is false (data should already be showing)
            if self.isLoading && (self.authorDetail != nil || !self.authorWorks.isEmpty) {
                self.isLoading = false
            }
            
            // Force non-loading state (better to show partial data than loading spinner)
            if self.isLoading {
                self.isLoading = false // Never block UI with loading
            }
                
                // Log summary for AI lessons
                let summary = createAuthorSummary()
            print("🤖 AI Summary: \(summary.count) characters")
        }
    }
    
    func generateAILessons() {
        isGeneratingLessons = true
        showingAILessons = true
        
        Task {
            // CRITICAL: Create comprehensive summary from ALL available data
            // Ensure we have the latest data before generating
            let authorId = openLibraryManager.extractAuthorId(from: author.key)
            
            // Refresh data if needed
            if authorDetail == nil {
                let detail = await openLibraryManager.getAuthorDetails(authorId: authorId)
                await MainActor.run {
                    self.authorDetail = detail
                }
            }
            
            if wikidataInfo == nil {
                let wikidata = await wikidataManager.getAuthorInfo(authorName: author.name)
                await MainActor.run {
                    self.wikidataInfo = wikidata
                }
            }
            
            if authorWorks.isEmpty {
                let works = await openLibraryManager.getAuthorWorks(authorId: authorId)
                await MainActor.run {
                    self.authorWorks = works
                }
            }
            
            // Create comprehensive summary from ALL available data
            let authorSummary = createAuthorSummary()
            
            // Generate AI lessons with the complete summary
            let lessons = await foundationModelsManager.generateAuthorLifeLessons(for: author, withSummary: authorSummary)
            
            await MainActor.run {
                aiLessons = lessons
                isGeneratingLessons = false
            }
        }
    }
    
    func createAuthorSummary() -> String {
        var summary = "Author: \(author.name)\n\n"
        
        // BIOGRAPHY - CRITICAL: Check ALL sources (cache, current state, both APIs)
        var biographyText = ""
        let authorId = openLibraryManager.extractAuthorId(from: author.key)
        let cachedDetail = openLibraryManager.authorDetails[authorId]
        let cachedWikidata = wikidataManager.authorInfo.values.first(where: { $0.name == author.name })
        
        // Priority 1: Wikidata (current, state, or cached) - PRIMARY SOURCE
        if let wikidata = wikidataInfo ?? cachedWikidata {
            biographyText = wikidata.biography ?? wikidata.description ?? ""
        }
        
        // Priority 2: Open Library (current, state, or cached) - RELIABLE fallback
        if biographyText.isEmpty {
            biographyText = authorDetail?.bio ?? cachedDetail?.bio ?? ""
        }
        
        // CRITICAL: Always include biography if available (from ANY source)
        if !biographyText.isEmpty {
            summary += "Biography: \(biographyText)\n\n"
        } else {
            // Even if no bio, at least mention the author
            summary += "Author Information: \(author.name) is a documented author.\n\n"
        }
        
        // DATES - Combine from both sources
        var birthDate = wikidataInfo?.birthDate ?? author.birthDate
        var deathDate = wikidataInfo?.deathDate ?? author.deathDate
        
        if let detail = authorDetail {
            if birthDate == nil {
                birthDate = detail.birthDate
            }
            if deathDate == nil {
                deathDate = detail.deathDate
            }
        }
        
        if let birth = birthDate {
            summary += "Birth Date: \(birth)\n"
        }
        
        if let death = deathDate {
            summary += "Death Date: \(death)\n"
        }
        
        // OCCUPATION - From Wikidata
        if let wikidata = wikidataInfo, !wikidata.occupations.isEmpty {
            summary += "Occupation: \(wikidata.occupations.joined(separator: ", "))\n"
        }
        
        // WORKS - Combine from both sources (critical for AI)
        if let topWork = author.topWork {
            summary += "Famous Work: \(topWork)\n"
        }
        
        if let workCount = author.workCount {
            summary += "Total Works (Open Library): \(workCount)\n"
        }
        
        // Get all works - CRITICAL: Check ALL sources (cache, current state, both APIs)
        var allWorksList: [String] = []
        
        // Priority 1: Wikidata works (current, state, or cached)
        if let wikidata = wikidataInfo ?? cachedWikidata, !wikidata.works.isEmpty {
            allWorksList.append(contentsOf: wikidata.works.map { $0.title })
        }
        
        // Priority 2: Open Library works (current list)
        if !authorWorks.isEmpty {
            allWorksList.append(contentsOf: authorWorks.map { $0.title })
        }
        
        // Priority 3: Open Library works from detail object (current or cached)
        if let detail = authorDetail ?? cachedDetail, let works = detail.authorWorks, !works.isEmpty {
            allWorksList.append(contentsOf: works.map { $0.title })
        }
        
        // CRITICAL: Always include top work if no works list yet
        if allWorksList.isEmpty, let topWork = author.topWork {
            allWorksList.append(topWork)
        }
        
        // Remove duplicates and show works
        let uniqueWorks = Array(Set(allWorksList))
        if !uniqueWorks.isEmpty {
            summary += "\nNotable Works (\(uniqueWorks.count) total):\n"
            for work in uniqueWorks.prefix(20) {
                summary += "- \(work)\n"
            }
            if uniqueWorks.count > 20 {
                summary += "... and \(uniqueWorks.count - 20) more works\n"
            }
        } else if let topWork = author.topWork {
            // At least mention the famous work even if works list is empty
            summary += "\nFamous Work: \(topWork)\n"
        }
        
        // SUBJECTS
        if let topSubjects = author.topSubjects, !topSubjects.isEmpty {
            summary += "\nMain Subjects: \(topSubjects.joined(separator: ", "))\n"
        }
        
        // PERSONAL INFO
        if let detail = authorDetail, let personalName = detail.personalName {
            summary += "\nPersonal Name: \(personalName)\n"
        }
        
        summary += "\n--- Data Sources: Open Library API + Wikidata API ---"
        
        // CRITICAL: Ensure we always have enough data for AI (even if minimal)
        if summary.count < 100 {
            summary += "\n\nAdditional Context:\n"
            summary += "Author: \(author.name)\n"
            if let workCount = author.workCount {
                summary += "Total documented works: \(workCount)\n"
            }
            if let topWork = author.topWork {
                summary += "Notable work: \(topWork)\n"
            }
        }
        
        return summary
    }
    
    private func matchesAuthorName(_ info: WikidataAuthorInfo) -> Bool {
        if info.name.caseInsensitiveCompare(author.name) == .orderedSame {
            return true
        }
        
        if let alternates = author.alternateNames {
            return alternates.contains { alt in
                alt.caseInsensitiveCompare(info.name) == .orderedSame ||
                alt.localizedCaseInsensitiveContains(info.name) ||
                info.name.localizedCaseInsensitiveContains(alt)
            }
        }
        
        return false
    }
}

// MARK: - Biography View Component

struct BiographyView: View {
    let author: AuthorSearchResult
    @State var authorDetail: AuthorDetail?
    @State var wikidataInfo: WikidataAuthorInfo?
    @ObservedObject var openLibraryManager: OpenLibraryManager
    @ObservedObject var wikidataManager: WikidataManager
    let loadAllAuthorData: () async -> Void
    @State private var hasLoaded = false
    
    // PERMANENT SOLUTION: Compute biography using computed property (not in View builder)
    private var combinedBio: String {
        let authorId = openLibraryManager.extractAuthorId(from: author.key)
        let cachedDetail = openLibraryManager.authorDetails[authorId]
        let cachedWikidata = wikidataManager.authorInfo.values.first(where: { $0.name == author.name })
        
        // Priority 1: Wikidata (current, state, or cached) - PRIMARY SOURCE
        if let wikidata = wikidataInfo ?? cachedWikidata {
            if let bio = wikidata.biography, !bio.isEmpty {
                return bio
            }
            if let desc = wikidata.description, !desc.isEmpty {
                return desc
            }
        }
        
        // Priority 2: Open Library (current, state, or cached) - RELIABLE fallback
        if let bio = authorDetail?.bio, !bio.isEmpty {
            return bio
        }
        if let bio = cachedDetail?.bio, !bio.isEmpty {
            return bio
        }
        
        // If still no bio, return empty (but Open Library should have tried)
        return ""
    }
    
    var body: some View {
        Group {
            if !combinedBio.isEmpty {
                Text(combinedBio)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .onAppear {
                        // Update state when bio appears
                        let authorId = openLibraryManager.extractAuthorId(from: author.key)
                        authorDetail = openLibraryManager.authorDetails[authorId]
                        wikidataInfo = wikidataManager.authorInfo.values.first(where: { $0.name == author.name })
                    }
            } else {
                // CRITICAL: Load data silently in background - don't show loading state!
                // Just show empty space that will populate instantly
                Text("")
                    .font(.subheadline)
                    .frame(height: 20)
                .task {
                    // Load data immediately
                    await loadAllAuthorData()
                    // Update state after loading
                    let authorId = openLibraryManager.extractAuthorId(from: author.key)
                    authorDetail = openLibraryManager.authorDetails[authorId]
                    wikidataInfo = wikidataManager.authorInfo.values.first(where: { $0.name == author.name })
                }
                .onAppear {
                    // Update state immediately when view appears (check cache first!)
                    let authorId = openLibraryManager.extractAuthorId(from: author.key)
                    // CRITICAL: Update from cache immediately for instant display
                    authorDetail = openLibraryManager.authorDetails[authorId]
                    wikidataInfo = wikidataManager.authorInfo.values.first(where: { $0.name == author.name })
                }
                .task(id: openLibraryManager.authorDetails.count) {
                    // Update when Open Library cache changes
                    let authorId = openLibraryManager.extractAuthorId(from: author.key)
                    if let detail = openLibraryManager.authorDetails[authorId] {
                        authorDetail = detail
                    }
                }
                .task(id: wikidataManager.authorInfo.count) {
                    // Update when Wikidata cache changes
                    if let wikidata = wikidataManager.authorInfo.values.first(where: { $0.name == author.name }) {
                        wikidataInfo = wikidata
                    }
                }
            }
        }
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
