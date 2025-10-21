//
//  RedditSocialPage.swift
//  Spotify Dashboard
//
//  Created by Ashfaq ahmed on 07/08/25.
//

import SwiftUI
import Combine
import Foundation

struct RedditPost: Codable, Equatable {
    let title: String
    let selftext: String
    let author: String
    let score: Int
    let numComments: Int
    let createdUTC: Double
    let thumbnail: String?
    let url: String?
    let subreddit: String
    
    enum CodingKeys: String, CodingKey {
        case title, selftext, author, score, thumbnail, url, subreddit
        case numComments = "num_comments"
        case createdUTC = "created_utc"
    }
    
    // Implement Equatable
    static func == (lhs: RedditPost, rhs: RedditPost) -> Bool {
        return lhs.title == rhs.title &&
               lhs.author == rhs.author &&
               lhs.score == rhs.score &&
               lhs.createdUTC == rhs.createdUTC &&
               lhs.subreddit == rhs.subreddit
    }
}

struct RedditResponse: Codable {
    let data: RedditData
}

struct RedditData: Codable {
    let children: [RedditChild]
}

struct RedditChild: Codable {
    let data: RedditPost
}

// MARK: - Reddit Authentication Models (keep for future OAuth implementation)
/*
struct RedditTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let scope: String
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
        case refreshToken = "refresh_token"
    }
}

struct RedditErrorResponse: Codable {
    let error: String
    let message: String?
    let reason: String?
}
*/

class RedditManager: ObservableObject {
    @Published var redditPosts: [RedditPost] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    @Published var isAuthenticated = true // Always true for public API
    @Published var authError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load posts immediately without authentication
        loadPopularPosts()
        
        // Watch for search query changes
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.loadPopularPosts()
                } else {
                    self?.searchRedditPosts(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Fetching
    
    func loadPopularPosts() {
        isLoading = true
        authError = nil
        
        guard let url = URL(string: "https://www.reddit.com/r/music/hot.json?limit=20") else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        performRedditRequest(url: url)
    }
    
    func searchRedditPosts(query: String) {
        isLoading = true
        authError = nil
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://www.reddit.com/r/music/search.json?q=\(encodedQuery)&limit=20&sort=relevance") else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        performRedditRequest(url: url)
    }
    
    private func performRedditRequest(url: URL) {
        var request = URLRequest(url: url)
        // Use your Reddit app credentials as User-Agent for identification
        request.setValue(RedditConfig.userAgent, forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                guard let data = data, error == nil else {
                    self?.authError = "Network error: \(error?.localizedDescription ?? "Unknown error")"
                    print("Reddit API error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    let redditResponse = try JSONDecoder().decode(RedditResponse.self, from: data)
                    self?.redditPosts = redditResponse.data.children.map { $0.data }
                    self?.authError = nil // Clear any previous errors
                } catch {
                    self?.authError = "Failed to load posts: \(error.localizedDescription)"
                    print("Reddit decoding error: \(error)")
                }
            }
        }.resume()
    }
}

struct RedditSocialPage: View {
    @StateObject private var redditManager = RedditManager()
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.purple.opacity(0.1),
                        Color.black.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Liquid glass overlay
                LiquidGlassOverlay(intensity: 0.4, offset: animationOffset)
                    .opacity(0.3)
                
                ScrollView {
                    VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "music.note")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    
                                    Text("Trending Music News ")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Status indicator
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(.green)
                                            .frame(width: 8, height: 8)
                                        
                                        Text("Connected")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Image(systemName: "waveform")
                                        .font(.title2)
                                        .foregroundColor(.cyan)
                                }
                                .padding(.horizontal)
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Search for artists, songs, or topics...", text: $redditManager.searchQuery)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                if !redditManager.searchQuery.isEmpty {
                                    Button("Clear") {
                                        redditManager.searchQuery = ""
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.green, .cyan],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .padding(.horizontal)
                        }
                        
                        // Posts Content
                        if redditManager.isLoading {
                            VStack(spacing: 20) {
                                ProgressView()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.green)
                                
                                Text("Loading Reddit posts...")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 50)
                        } else if redditManager.redditPosts.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "sadface")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("No posts found")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.title2)
                                
                                if !redditManager.searchQuery.isEmpty {
                                    Text("Try searching for different terms")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                }
                            }
                            .padding(.vertical, 50)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(redditManager.redditPosts.indices, id: \.self) { index in
                                    RedditPostCard(post: redditManager.redditPosts[index])
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .offset(y: 20)),
                                            removal: .opacity.combined(with: .offset(y: -20))
                                        ))
                                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.1), value: redditManager.redditPosts)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            animationOffset = 100
        }
    }
}

struct RedditPostCard: View {
    let post: RedditPost
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Post Header
            HStack {
                Text("u/\(post.author)")
                    .font(.caption)
                    .foregroundColor(.cyan)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("/r/\(post.subreddit)")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            
            // Post Title
            Text(post.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(isExpanded ? nil : 3)
                .multilineTextAlignment(.leading)
            
            // Post Content (if exists)
            if !post.selftext.isEmpty {
                Text(post.selftext)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(isExpanded ? nil : 2)
                    .multilineTextAlignment(.leading)
            }
            
            // Action Buttons
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up")
                        .font(.caption)
                    Text("\(post.score)")
                        .font(.caption)
                }
                .foregroundColor(.green)
                
                HStack(spacing: 6) {
                    Image(systemName: "bubble")
                        .font(.caption)
                    Text("\(post.numComments)")
                        .font(.caption)
                }
                .foregroundColor(.blue)
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(RelativeDateTimeFormatter().localizedString(for: Date(timeIntervalSince1970: post.createdUTC), relativeTo: Date()))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.05))
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .onTapGesture {
            if let url = URL(string: post.url ?? "https://reddit.com\(post.url ?? "")"), url.scheme != nil {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    RedditSocialPage()
}
