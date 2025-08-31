import SwiftUI
import Charts
import Combine

struct SpotifyDashboardView: View {
    @State private var selectedTab = 0
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var animationOffset: CGFloat = 0
    @State private var liquidGlowIntensity: Double = 0.6
    @State private var searchText: String = ""
    
    // Prevent tab switching during language updates
    @State private var isLanguageUpdating = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainPage(spotifyManager: spotifyManager)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ArtistsPage(spotifyManager: spotifyManager)
                .tabItem {
                    Label("Artists", systemImage: "music.microphone")
                }
                .tag(1)
            
            RedditSocialPage()
                .tabItem {
                    Label("Social", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(2)
        }
        .onAppear {
            Task {
                await spotifyManager.getPopularArtists()
                await spotifyManager.getTrendingTracks()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await spotifyManager.getPopularArtists()
                await spotifyManager.getTrendingTracks()
            }
        }
        .id(selectedTab) // Stable ID to prevent unwanted navigation resets
    }
}

// MARK: - iOS 26 Liquid Glass Components

struct LiquidGlassOverlay: View {
    let intensity: Double
    let offset: CGFloat
    
    var body: some View {
        ZStack {
            // Multiple liquid shapes with different animations
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.green.opacity(0.6),
                            Color.cyan.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: offset, y: -offset * 0.5)
                .blur(radius: 20)
            
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.4),
                            Color.pink.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 250, height: 400)
                .offset(x: -offset * 0.8, y: offset * 1.2)
                .blur(radius: 25)
                .rotationEffect(.degrees(offset * 0.5))
        }
    }
}

struct FloatingGlassNavigation: View {
    @Binding var selectedTab: Int
    @State private var isPressed = false
    @State private var glassShimmer: Double = 0
    
    var body: some View {
        HStack(spacing: 40) {
            FloatingNavItem(
                icon: "house.fill",
                label: "Main",
                isSelected: selectedTab == 0,
                isPressed: isPressed && selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            
            FloatingNavItem(
                icon: "person.3.fill",
                label: "Artists",
                isSelected: selectedTab == 1,
                isPressed: isPressed && selectedTab == 1
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background {
            // Enhanced glass effect with shimmer
            ZStack {
                // Base glass
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                
                // Shimmer overlay
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.0),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: glassShimmer)
                    .mask(RoundedRectangle(cornerRadius: 24))
                
                // Border glow
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.cyan.opacity(0.2),
                                Color.green.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .shadow(color: .green.opacity(0.2), radius: 12, x: 0, y: 0)
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                glassShimmer = 200
            }
        }
    }
}

struct FloatingNavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let isPressed: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Selection background
                if isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.green.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay {
                            Circle()
                                .stroke(Color.green.opacity(0.4), lineWidth: 1)
                        }
                }
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.green, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(
                    isSelected ?
                    LinearGradient(
                        colors: [Color.green, Color.cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.white.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Enhanced Glass Components

struct GlassCard: View {
    let content: AnyView
    var cornerRadius: CGFloat = 16
    var glowColor: Color = .green
    
    var body: some View {
        content
            .background {
                ZStack {
                    // Base glass
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.thinMaterial)
                        .environment(\.colorScheme, .dark)
                    
                    // Inner glow
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [
                                    glowColor.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 100
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
            }
            .shadow(color: glowColor.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Main Page (Enhanced with Glass Effects)
struct MainPage: View {
    @State private var searchText = ""
    @State private var activeSearchText = ""
    @State private var isSearchActive = false
    @State private var isSearching = false
    @ObservedObject var spotifyManager: SpotifyManager
    
    // Your existing computed properties remain the same
    var filteredArtists: [Artist] {
        if !isSearchActive {
            return spotifyManager.popularArtists
        }
        return spotifyManager.popularArtists.filter { artist in
            artist.name.localizedCaseInsensitiveContains(activeSearchText)
        }
    }
    
    var filteredTracks: [Track] {
        if !isSearchActive {
            return spotifyManager.trendingTracks
        }
        return spotifyManager.trendingTracks.filter { track in
            track.name.localizedCaseInsensitiveContains(activeSearchText) ||
            track.artists.contains { $0.name.localizedCaseInsensitiveContains(activeSearchText) } ||
            track.album.name.localizedCaseInsensitiveContains(activeSearchText)
        }
    }
    
    var artistSpecificTracks: [Track] {
        if !isSearchActive {
            return spotifyManager.trendingTracks
        }
        
        let artistTracks = spotifyManager.trendingTracks.filter { track in
            track.artists.contains { artist in
                artist.name.localizedCaseInsensitiveContains(activeSearchText)
            }
        }
        
        if !artistTracks.isEmpty {
            return artistTracks
        }
        
        return filteredTracks
    }
    
    var dynamicChartData: [DataPoint] {
        if !isSearchActive {
            return sampleData
        }
        
        if filteredArtists.isEmpty && filteredTracks.isEmpty {
            let searchHash = abs(activeSearchText.hashValue % 100) + 50
            let baseValue = searchHash * 10
            
            return [
                DataPoint(month: "Aug", value: baseValue),
                DataPoint(month: "Sep", value: baseValue + 50),
                DataPoint(month: "Oct", value: baseValue + 100),
                DataPoint(month: "Nov", value: baseValue + 150)
            ]
        }
        
        let artistCount = filteredArtists.count
        let trackCount = filteredTracks.count
        
        let artistPopularitySum = filteredArtists.reduce(0) { sum, artist in
            sum + (artist.popularity ?? 50)
        }
        let trackPopularitySum = filteredTracks.reduce(0) { sum, track in
            sum + (track.popularity ?? 45)
        }
        
        let searchHash = abs(activeSearchText.hashValue % 100) + 20
        let artistMultiplier = max(artistPopularitySum / max(artistCount, 1), 40)
        let trackMultiplier = max(trackPopularitySum / max(trackCount, 1), 35)
        
        let baseValue = (artistMultiplier + trackMultiplier) * searchHash / 15
        
        return [
            DataPoint(month: "Aug", value: max(baseValue * 60 / 100, 50)),
            DataPoint(month: "Sep", value: max(baseValue * 75 / 100, 75)),
            DataPoint(month: "Oct", value: max(baseValue * 90 / 100, 100)),
            DataPoint(month: "Nov", value: max(baseValue, 125))
        ]
    }
    
    private func performSearch() {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedSearchText.isEmpty else {
            clearSearch()
            return
        }
        
        isSearching = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            activeSearchText = trimmedSearchText
            isSearchActive = true
            isSearching = false
        }
    }
    
    private func clearSearch() {
        searchText = ""
        activeSearchText = ""
        isSearchActive = false
        isSearching = false
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with liquid glass effect
                GlassCard(content: AnyView(
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Spotify Insights 📱")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("iOS 26 Experience")
                                .font(.caption)
                                .foregroundColor(.green.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await spotifyManager.getPopularArtists()
                                await spotifyManager.getTrendingTracks()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .medium))
                                Text("Refresh")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                            }
                        }
                        .disabled(spotifyManager.isLoading)
                        .opacity(spotifyManager.isLoading ? 0.6 : 1.0)
                    }
                    .padding()
                ), cornerRadius: 20, glowColor: .cyan)
                
                // Enhanced Search Bar with liquid glass
                GlassCard(content: AnyView(
                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 16))
                            
                            TextField("Search artist, album, track...", text: $searchText)
                                .foregroundColor(.white)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onSubmit {
                                    performSearch()
                                }
                                .disabled(isSearching)
                            
                            if !searchText.isEmpty {
                                Button(action: clearSearch) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Button(action: performSearch) {
                                HStack(spacing: 6) {
                                    if isSearching {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Search")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.green, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 2)
                            }
                            .disabled(isSearching)
                        }
                    }
                    .padding()
                ), cornerRadius: 16, glowColor: .green)
                
                // Search Results Indicator
                if isSearchActive && !activeSearchText.isEmpty {
                    GlassCard(content: AnyView(
                        HStack {
                            Text("Search Results for:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\"\(activeSearchText)\"")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                            Text("- \(filteredArtists.count) artists, \(filteredTracks.count) tracks")
                                .font(.caption)
                                .foregroundColor(.cyan)
                            Spacer()
                            Button("Clear") {
                                clearSearch()
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    ), cornerRadius: 12, glowColor: .yellow)
                }
                
                // Enhanced Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    EnhancedStatCard(
                        title: "Total Listeners",
                        value: formatNumber(!isSearchActive ?
                            calculateTotalListeners(from: spotifyManager) :
                            (filteredArtists.isEmpty && filteredTracks.isEmpty ?
                                calculateEstimatedListeners(for: activeSearchText) :
                                calculateTotalListeners(from: filteredArtists, filteredTracks: filteredTracks))),
                        change: !isSearchActive ? "+15%" : "Search Results",
                        icon: "person.3.fill",
                        glowColor: .blue
                    )
                    
                    EnhancedStatCard(
                        title: "Active Listeners",
                        value: formatNumber(!isSearchActive ?
                            calculateActiveListeners(from: spotifyManager) :
                            (filteredArtists.isEmpty && filteredTracks.isEmpty ?
                                calculateEstimatedActiveListeners(for: activeSearchText) :
                                calculateActiveListeners(from: filteredArtists, filteredTracks: filteredTracks))),
                        change: !isSearchActive ? "+8%" : "Filtered",
                        icon: "waveform.path.ecg",
                        glowColor: .green
                    )
                    
                    EnhancedStatCard(
                        title: "Total Streams",
                        value: formatNumber(!isSearchActive ?
                            calculateTotalStreams(from: spotifyManager) :
                            (filteredTracks.isEmpty ?
                                calculateEstimatedStreams(for: activeSearchText) :
                                calculateTotalStreams(from: filteredTracks))),
                        change: !isSearchActive ? "+22%" : "Results",
                        icon: "play.circle.fill",
                        glowColor: .purple
                    )
                    
                    EnhancedStatCard(
                        title: "Subscriptions",
                        value: formatNumber(!isSearchActive ?
                            calculateSubscriptions(from: spotifyManager) :
                            (filteredArtists.isEmpty && filteredTracks.isEmpty ?
                                calculateEstimatedSubscriptions(for: activeSearchText) :
                                calculateSubscriptions(from: filteredArtists, filteredTracks: filteredTracks))),
                        change: !isSearchActive ? "+12%" : "Data",
                        icon: "crown.fill",
                        glowColor: .orange
                    )
                }
                
                // Error message if any
                if let errorMessage = spotifyManager.errorMessage {
                    GlassCard(content: AnyView(
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        .padding()
                    ), cornerRadius: 12, glowColor: .red)
                }
                
                // Enhanced Performance Chart
                GlassCard(content: AnyView(
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Performance")
                                .font(.headline)
                                .foregroundColor(.white)
                            if isSearchActive && !activeSearchText.isEmpty {
                                Text("(Search Results)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                        }
                        
                        Chart {
                            ForEach(dynamicChartData) { item in
                                LineMark(
                                    x: .value("Month", item.month),
                                    y: .value("Streams", item.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: isSearchActive ? [Color.yellow, Color.orange] : [Color.green, Color.cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                
                                AreaMark(
                                    x: .value("Month", item.month),
                                    y: .value("Streams", item.value)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: isSearchActive ?
                                        [Color.yellow.opacity(0.3), Color.orange.opacity(0.1)] :
                                        [Color.green.opacity(0.3), Color.cyan.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding()
                ), cornerRadius: 16, glowColor: isSearchActive ? .yellow : .green)
                
                Spacer()
            }
            .padding()
        }
        .refreshable {
            Task {
                await spotifyManager.getPopularArtists()
                await spotifyManager.getTrendingTracks()
            }
        }
    }
}

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let change: String
    let icon: String
    let glowColor: Color
    @State private var isAnimating = false
    
    var body: some View {
        GlassCard(content: AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [glowColor, glowColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Spacer()
                    
                    Text(change)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(change.hasPrefix("+") ? .green : .yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .padding()
        ), cornerRadius: 16, glowColor: glowColor)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Enhanced Artists Page with Proper Refresh and API Search
struct ArtistsPage: View {
    @ObservedObject var spotifyManager: SpotifyManager
    @State private var artistSearchText = ""
    @State private var isRefreshing = false
    @State private var isSearching = false
    @State private var searchResults: SearchResults?
    @State private var currentLanguage: Language = .english
    
    @State private var artistThumbnails: [String: String] = [:]
    
    // Track IDs to detect changes even when count stays the same
    var trendingTrackIDs: [String] { spotifyManager.trendingTracks.map { $0.id } }
    
    // Build a unique list of artists from the currently loaded trending tracks (which reflect the selected language)
    var languageDrivenArtists: [Artist] {
        // Create a lookup table of richer artist objects (often include images)
        let enrichedById: [String: Artist] = Dictionary(uniqueKeysWithValues: spotifyManager.popularArtists.map { ($0.id, $0) })
        
        var seen = Set<String>()
        var unique: [Artist] = []
        for track in spotifyManager.trendingTracks {
            for artist in track.artists {
                if !seen.contains(artist.id) {
                    seen.insert(artist.id)
                    // Prefer the enriched artist (with images) when available
                    if let enriched = enrichedById[artist.id] {
                        unique.append(enriched)
                    } else {
                        unique.append(artist)
                    }
                }
            }
        }
        // Fallback to popularArtists if trendingTracks is empty
        return unique.isEmpty ? spotifyManager.popularArtists : unique
    }
    
    // Fallback image for artists derived from richer sources: prefer artist images from popularArtists,
    // then album art where the artist is the SOLE contributor on the track,
    // then album art where artist is primary, and finally any album art.
    var artistImageFallbacks: [String: String] {
        var map: [String: String] = [:]
        
        // 1) Prefer known artist images from popularArtists (often include proper artist photos)
        for a in spotifyManager.popularArtists {
            if let url = a.images?.first?.url {
                map[a.id] = url
            }
        }
        
        // 2) Use album art where the artist is the SOLE contributor on the track
        for track in spotifyManager.trendingTracks where track.artists.count == 1 {
            guard let only = track.artists.first, map[only.id] == nil, let albumURL = track.album.images.first?.url else { continue }
            map[only.id] = albumURL
        }
        
        // 3) Use album art where the artist is primary (first artist on the track)
        for track in spotifyManager.trendingTracks {
            if let primary = track.artists.first, map[primary.id] == nil, let albumURL = track.album.images.first?.url {
                map[primary.id] = albumURL
            }
        }
        
        // 4) As a last resort, assign any album art for remaining artists
        for track in spotifyManager.trendingTracks {
            guard let albumURL = track.album.images.first?.url else { continue }
            for a in track.artists where map[a.id] == nil {
                map[a.id] = albumURL
            }
        }
        
        return map
    }
    
    var filteredArtistsPage: [Artist] {
        if let searchResults = searchResults {
            return searchResults.artists
        }
        let base = languageDrivenArtists
        if artistSearchText.isEmpty {
            return base
        }
        return base.filter { artist in
            artist.name.localizedCaseInsensitiveContains(artistSearchText)
        }
    }
    
    var filteredTracksPage: [Track] {
        if let searchResults = searchResults {
            return searchResults.tracks
        }
        
        if artistSearchText.isEmpty {
            return spotifyManager.trendingTracks
        }
        return spotifyManager.trendingTracks.filter { track in
            track.name.localizedCaseInsensitiveContains(artistSearchText) ||
            track.artists.contains { $0.name.localizedCaseInsensitiveContains(artistSearchText) } ||
            track.album.name.localizedCaseInsensitiveContains(artistSearchText)
        }
    }
    
    // Enhanced refresh function that connects to your Spotify API
    private func refreshData() async {
        isRefreshing = true
        
        // Clear search results and text when refreshing
        searchResults = nil
        artistSearchText = ""
        
        // Call your Spotify API methods to fetch fresh data
        await spotifyManager.getPopularArtists()
        await spotifyManager.getTrendingTracks()
        
        isRefreshing = false
    }
    
    // New function to perform Spotify API search
    private func performSpotifySearch() async {
        guard !artistSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = nil
            return
        }
        
        isSearching = true
        
        // Call Spotify Search API through your SpotifyManager
        await spotifyManager.searchSpotify(query: artistSearchText)
        
        // Get the search results from SpotifyManager
        searchResults = spotifyManager.searchResults
        
        isSearching = false
    }
    
    private func clearSearch() {
        artistSearchText = ""
        searchResults = nil
    }
    
    private func fetchArtistThumbnailsIfNeeded(for artists: [Artist]) async {
        // Example: Placeholder for actual thumbnail fetching logic
        // For now, just update a dummy dictionary or do nothing.
        // This is where you'd fetch or cache thumbnail URLs as needed.
        // Simulate async delay
        await Task.yield()
        
        // Example: Assign fallback images or dummy URLs
        var newMap: [String: String] = [:]
        for artist in artists {
            if let url = artistImageFallbacks[artist.id] {
                newMap[artist.id] = url
            }
        }
        DispatchQueue.main.async {
            artistThumbnails = newMap
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GlassCard(content: AnyView(
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Popular Artists")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Latest trending artists & tracks")
                                    .font(.caption)
                                    .foregroundColor(.green.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            // Enhanced Refresh Button with Spotify API connection
                            Button(action: {
                                Task {
                                    await refreshData()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .medium))
                                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                        .animation(
                                            isRefreshing ?
                                            .linear(duration: 1.0).repeatForever(autoreverses: false) :
                                            .default,
                                            value: isRefreshing
                                        )
                                    
                                    Text(isRefreshing ? "Refreshing..." : "Refresh")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: isRefreshing ?
                                        [Color.yellow, Color.orange] :
                                        [Color.green, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(
                                    color: isRefreshing ?
                                    .yellow.opacity(0.4) :
                                    .green.opacity(0.4),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            }
                            .disabled(isRefreshing || spotifyManager.isLoading)
                            .opacity((isRefreshing || spotifyManager.isLoading) ? 0.6 : 1.0)
                        }
                        
                        // Enhanced Search Bar with Spotify API integration
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 16))
                            
                            TextField("Search artists, tracks, albums...", text: $artistSearchText)
                                .foregroundColor(.white)
                                .textFieldStyle(PlainTextFieldStyle())
                                .onSubmit {
                                    Task {
                                        await performSpotifySearch()
                                    }
                                }
                                .disabled(isSearching || isRefreshing)
                            
                            if !artistSearchText.isEmpty {
                                Button(action: clearSearch) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.system(size: 16))
                                }
                            }
                            
                            // Search button that calls Spotify API
                            if !artistSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button(action: {
                                    Task {
                                        await performSpotifySearch()
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        if isSearching {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "magnifyingglass")
                                                .font(.system(size: 12, weight: .medium))
                                            Text("Search Artist ")
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(10)
                                    .shadow(color: .cyan.opacity(0.4), radius: 3, x: 0, y: 1)
                                }
                                .disabled(isSearching || isRefreshing)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        }
                    }
                    .padding()
                ), cornerRadius: 16, glowColor: .green)
                
                // Search status indicator
                if searchResults != nil {
                    GlassCard(content: AnyView(
                        HStack {
                            Text("Spotify Search Results for:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Text("\"\(artistSearchText)\"")
                                .font(.caption)
                                .foregroundColor(.cyan)
                                .fontWeight(.medium)
                            Text("- \(filteredArtistsPage.count) artists")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Spacer()
                            Button("Show All") {
                                clearSearch()
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    ), cornerRadius: 12, glowColor: .cyan)
                }
                
                // Search indicator
                if isSearching {
                    GlassCard(content: AnyView(
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                                .scaleEffect(0.8)
                            
                            Text("Searching Spotify API...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                        }
                        .padding()
                    ), cornerRadius: 12, glowColor: .cyan)
                }
                if isRefreshing {
                    GlassCard(content: AnyView(
                        HStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                .scaleEffect(0.8)
                            
                            Text("Fetching latest data from Spotify API...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                        }
                        .padding()
                    ), cornerRadius: 12, glowColor: .green)
                }
                
                // Error message if any
                if let errorMessage = spotifyManager.errorMessage {
                    GlassCard(content: AnyView(
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Spacer()
                            
                            Button("Retry") {
                                Task {
                                    await refreshData()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                        .padding()
                    ), cornerRadius: 12, glowColor: .red)
                }
                
                // Language Selection for Trending Tracks
                LanguageSelectionView(
                    selectedLanguage: $spotifyManager.selectedLanguage,
                    spotifyManager: spotifyManager
                )
                
                // Trending Tracks Section
                if !spotifyManager.trendingTracks.isEmpty {
                    GlassCard(content: AnyView(
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("\(spotifyManager.selectedLanguage.displayName) Trending Tracks")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(spotifyManager.trendingTracks.count)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            
                            LazyVStack(spacing: 12) {
                                ForEach(spotifyManager.trendingTracks.prefix(8), id: \.id) { track in
                                    TrendingTrackRow(track: track)
                                }
                            }
                        }
                        .padding()
                    ), cornerRadius: 16, glowColor: .green)
                }
                
                // Artists Grid
                if !filteredArtistsPage.isEmpty {
                    GlassCard(content: AnyView(
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Artists")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                if searchResults != nil {
                                    Text("(Spotify Search - \(filteredArtistsPage.count) found)")
                                        .font(.caption)
                                        .foregroundColor(.cyan)
                                } else if !artistSearchText.isEmpty {
                                    Text("(Local Filter - \(filteredArtistsPage.count) found)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                Spacer()
                            }
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(filteredArtistsPage.prefix(6), id: \.id) { artist in
                                    ArtistCard(artist: artist, searchText: artistSearchText, fallbackImageURL: artistThumbnails[artist.id] ?? artistImageFallbacks[artist.id])
                                }
                            }
                        }
                        .padding()
                    ), cornerRadius: 16, glowColor: .green)
                }
                
                // No results message
                if !artistSearchText.isEmpty && filteredArtistsPage.isEmpty && !isSearching {
                    GlassCard(content: AnyView(
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No results found")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(searchResults != nil ?
                                "No results found in Spotify for '\(artistSearchText)'" :
                                "Try searching for a different artist, track, or album")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    ), cornerRadius: 16, glowColor: .gray)
                }
                
                Spacer()
            }
            .padding()
        }
        .refreshable {
            // Pull-to-refresh functionality that calls your Spotify API
            Task {
                await refreshData()
            }
        }
        .onChange(of: spotifyManager.selectedLanguage) { newLanguage in
            currentLanguage = newLanguage
            Task {
                // When language changes (used by Trending Tracks), also refresh Popular Artists
                // so the Artists grid updates to the selected language.
                isRefreshing = true
                // Reset local search state so the grid reflects fresh language-specific data
                searchResults = nil
                artistSearchText = ""
                await spotifyManager.getPopularArtists()
                await fetchArtistThumbnailsIfNeeded(for: languageDrivenArtists)
                isRefreshing = false
            }
        }
        .onChange(of: trendingTrackIDs) { _ in
            Task { await fetchArtistThumbnailsIfNeeded(for: languageDrivenArtists) }
        }
        .onAppear {
            Task { await fetchArtistThumbnailsIfNeeded(for: languageDrivenArtists) }
        }
    }
}

// MARK: - Your existing components (ArtistCard, TrackRow)
struct ArtistCard: View {
    let artist: Artist
    let searchText: String
    let fallbackImageURL: String?
    
    var body: some View {
        GlassCard(content: AnyView(
            VStack(spacing: 8) {
                AsyncImage(url: URL(string: artist.images?.first?.url ?? fallbackImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            searchText.isEmpty ?
                                LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [Color.green, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                )
                
                Text(artist.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let popularity = artist.popularity {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text("\(popularity)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
        ), cornerRadius: 12, glowColor: searchText.isEmpty ? .green : .cyan)
        .frame(width: 120)
    }
}

struct TrackRow: View {
    let track: Track
    let searchText: String
    @State private var isPressed = false
    
    var body: some View {
        GlassCard(content: AnyView(
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artists.map { $0.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Text(track.album.name)
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    if let popularity = track.popularity {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text("\(popularity)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: track.external_urls.spotify) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                                .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isPressed = false
                        }
                        if let url = URL(string: track.external_urls.spotify) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .padding()
        ), cornerRadius: 12, glowColor: searchText.isEmpty ? .green : .cyan)
    }
}
// MARK: - Add these to the END of your SpotifyDashboardView.swift file

struct DataPoint: Identifiable {
    let id = UUID()
    let month: String
    let value: Int
}

let sampleData: [DataPoint] = [
    DataPoint(month: "Aug", value: 300),
    DataPoint(month: "Sep", value: 600),
    DataPoint(month: "Oct", value: 750),
    DataPoint(month: "Nov", value: 1200)
]

// MARK: - Helper Functions
func formatNumber(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    
    if number >= 1_000_000 {
        let millions = Double(number) / 1_000_000
        return String(format: "%.1fM", millions)
    } else if number >= 1_000 {
        let thousands = Double(number) / 1_000
        return String(format: "%.1fK", thousands)
    } else {
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

func calculateTotalListeners(from manager: SpotifyManager) -> Int {
    let artistPopularitySum = manager.popularArtists.reduce(0) { sum, artist in
        sum + (artist.popularity ?? 0)
    }
    let trackPopularitySum = manager.trendingTracks.reduce(0) { sum, track in
        sum + (track.popularity ?? 0)
    }
    
    let baseListeners = (artistPopularitySum * 30000) + (trackPopularitySum * 15000)
    return max(baseListeners, 2400000)
}

func calculateActiveListeners(from manager: SpotifyManager) -> Int {
    let totalListeners = calculateTotalListeners(from: manager)
    return Int(Double(totalListeners) * 0.37)
}

func calculateTotalStreams(from manager: SpotifyManager) -> Int {
    let totalPopularity = manager.trendingTracks.reduce(0) { sum, track in
        sum + (track.popularity ?? 0)
    }
    let baseStreams = totalPopularity * 250000
    return max(baseStreams, 18700000)
}

func calculateSubscriptions(from manager: SpotifyManager) -> Int {
    let totalListeners = calculateTotalListeners(from: manager)
    return Int(Double(totalListeners) * 0.019)
}

func calculateTotalListeners(from artists: [Artist], filteredTracks: [Track]) -> Int {
    let artistListeners = artists.reduce(0) { sum, artist in
        if let followers = artist.followers?.total {
            return sum + followers
        } else {
            let popularity = artist.popularity ?? 50
            let uniqueMultiplier = abs(artist.name.hashValue % 25000) + 15000
            return sum + (popularity * uniqueMultiplier)
        }
    }
    
    let trackListeners = filteredTracks.reduce(0) { sum, track in
        let popularity = track.popularity ?? 45
        let uniqueMultiplier = abs(track.name.hashValue % 20000) + 5000
        return sum + (popularity * uniqueMultiplier)
    }
    
    let totalListeners = artistListeners + trackListeners
    return max(totalListeners, 50000)
}

func calculateActiveListeners(from artists: [Artist], filteredTracks: [Track]) -> Int {
    let totalListeners = calculateTotalListeners(from: artists, filteredTracks: filteredTracks)
    let avgPopularity = calculateAveragePopularity(artists: artists, tracks: filteredTracks)
    let activePercentage = Double(avgPopularity) / 100.0 * 0.5 + 0.2
    
    return Int(Double(totalListeners) * activePercentage)
}

func calculateTotalStreams(from tracks: [Track]) -> Int {
    if tracks.isEmpty {
        return 250000
    }
    
    let totalStreams = tracks.reduce(0) { sum, track in
        let popularity = track.popularity ?? 40
        let trackHash = abs(track.id.hashValue % 200000) + 50000
        let artistBonus = track.artists.count * 10000
        return sum + (popularity * trackHash) + artistBonus
    }
    
    return max(totalStreams, 150000)
}

func calculateSubscriptions(from artists: [Artist], filteredTracks: [Track]) -> Int {
    let totalListeners = calculateTotalListeners(from: artists, filteredTracks: filteredTracks)
    let avgPopularity = calculateAveragePopularity(artists: artists, tracks: filteredTracks)
    let subscriptionRate = Double(avgPopularity) / 100.0 * 0.025 + 0.005
    
    return max(Int(Double(totalListeners) * subscriptionRate), 500)
}

func calculateAveragePopularity(artists: [Artist], tracks: [Track]) -> Int {
    var totalPopularity = 0
    var count = 0
    
    for artist in artists {
        if let popularity = artist.popularity {
            totalPopularity += popularity
            count += 1
        }
    }
    
    for track in tracks {
        if let popularity = track.popularity {
            totalPopularity += popularity
            count += 1
        }
    }
    
    return count > 0 ? totalPopularity / count : 55
}

func calculateEstimatedListeners(for searchTerm: String) -> Int {
    let searchHash = abs(searchTerm.hashValue % 500000) + 100000
    return searchHash
}

func calculateEstimatedActiveListeners(for searchTerm: String) -> Int {
    let totalListeners = calculateEstimatedListeners(for: searchTerm)
    return Int(Double(totalListeners) * 0.35)
}

func calculateEstimatedStreams(for searchTerm: String) -> Int {
    let searchHash = abs(searchTerm.hashValue % 2000000) + 500000
    return searchHash
}

func calculateEstimatedSubscriptions(for searchTerm: String) -> Int {
    let totalListeners = calculateEstimatedListeners(for: searchTerm)
    return Int(Double(totalListeners) * 0.015)
}

// MARK: - Trending Track Row Component
struct TrendingTrackRow: View {
    let track: Track
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Track artwork (if available)
            AsyncImage(url: URL(string: track.album.images.first?.url ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.2))
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.green)
                    )
            }
            .frame(width: 48, height: 48)
            .cornerRadius(8)
            
            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(track.artists.map { $0.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Track stats
            VStack(alignment: .trailing, spacing: 2) {
                if let popularity = track.popularity {
                    Text("\(popularity)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Text("popularity")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Play button
            Button(action: {
                if let url = URL(string: track.preview_url ?? ""), !url.absoluteString.isEmpty {
                    // Play preview audio
                    // In a real implementation, you'd integrate audio playback here
                    print("Playing preview for: \(track.name)")
                }
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(track.preview_url?.isEmpty != false)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(isHovered ? 0.1 : 0.05))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if let spotifyUrl = URL(string: track.external_urls.spotify) {
                UIApplication.shared.open(spotifyUrl)
            }
        }
    }
}

