# 🔒 CRITICAL FILES TO PRESERVE

## ⚠️ READ THIS BEFORE MAKING CHANGES

This document lists all Spotify API and Firebase integration code that must be preserved during refactoring.

---

## 🎵 SPOTIFY API INTEGRATION

### Core Files:
1. **`Spotify Dashboard/SpotifyManager.swift`** ✅ CRITICAL
   - Contains ALL Spotify API integration
   - Access token management
   - Artist and track fetching
   - Search functionality
   - Language-based trending tracks
   - Cache management
   - Credentials: Client ID & Secret (lines 240-241)

2. **`Spotify Dashboard/Spotify.swift`** ✅ CRITICAL
   - UI views for Spotify data
   - Data models (Artist, Track, Album, etc.)
   - Glass card UI components
   - Main page, Artists page
   - Chart visualizations

3. **`Config.swift`** ✅ CRITICAL
   - Spotify credentials (lines 12-13)
   - Reddit credentials (lines 18-19)

### Spotify Credentials Location:
- File: `Config.swift`
- Client ID: `8daa6921d510480196865c592e3af024`
- Client Secret: `2b8a713e39aa448096ee2beeb95d609e`

### SpotifyManager Key Methods:
- `getAccessToken()` - Authentication
- `getPopularArtists()` - Fetch artists
- `getTrendingTracks()` - Fetch trending tracks
- `searchSpotify(query:)` - Search API
- `updateTrendingTracksForLanguage(_:)` - Language-based tracks
- `searchSpotifyInternal(query:)` - Internal search for Reddit integration

---

## 🔥 FIREBASE INTEGRATION

### Core Files:
1. **`SpotifyDashboardApp.swift`** ✅ CRITICAL
   - Firebase initialization (line 14)
   - App entry point

2. **`Spotify Dashboard/GoogleService-Info.plist`** ✅ CRITICAL
   - Firebase configuration
   - API keys and project settings
   - Bundle ID configuration

### Firebase Credentials:
- Project ID: `spotify-dashboard-75bb2`
- API Key: `AIzaSyDrxralsY611xxULsPOhljSQtI-9_lvflg`
- Bundle ID: `neaz1975-yahoo.com.Spotify-Dashboard`

---

## 🔗 ADDITIONAL INTEGRATIONS

### RedditManager.swift ✅ IMPORTANT
- Reddit API integration
- Music topic analysis
- Sentiment analysis
- Uses SpotifyManager internally for track matching

### PlaylistManager.swift ✅ IMPORTANT
- Community playlist management
- Voting system
- Battle system
- Uses both SpotifyManager and RedditManager

---

## 📱 VIEW FILES THAT USE THESE MANAGERS

These files depend on the integrations above:
- `ContentView.swift` - Main app entry
- `CrowdPlaylistsView.swift` - Uses PlaylistManager, SpotifyManager, RedditManager
- `MusicSocialPage.swift` - Uses RedditManager, SpotifyManager
- `ArtistFanStreamView.swift` - Uses SpotifyManager
- `LanguageSelectionView.swift` - Connects to SpotifyManager

---

## 🛡️ PROTECTION CHECKLIST

Before refactoring, ensure you:

- [ ] Backup `SpotifyManager.swift` completely
- [ ] Backup `Spotify.swift` completely
- [ ] Backup `Config.swift` completely
- [ ] Backup `SpotifyDashboardApp.swift` completely
- [ ] Backup `GoogleService-Info.plist` completely
- [ ] Backup `RedditManager.swift` completely
- [ ] Backup `PlaylistManager.swift` completely
- [ ] Document any new dependencies these files might need
- [ ] Test that Firebase still initializes after changes
- [ ] Test that Spotify API still authenticates after changes
- [ ] Verify Reddit integration still works

---

## 🔧 KEY DEPENDENCIES

### SpotifyManager uses:
- URLSession for network requests
- Codable models (Artist, Track, Album, etc.)
- Combine framework for publishers
- MainActor for UI updates

### Firebase uses:
- FirebaseCore framework
- GoogleService-Info.plist file must be in app bundle

### RedditManager uses:
- SpotifyManager (for track matching)
- URLSession for Reddit API calls
- Combine framework

### PlaylistManager uses:
- SpotifyManager (for track data)
- RedditManager (for Reddit data)
- Combine framework

---

## 🚨 DO NOT MODIFY THESE SPECIFIC SECTIONS

### In SpotifyManager.swift:
- Lines 240-241: Credentials (keep secret!)
- Lines 329-357: `getAccessToken()` method
- Lines 573-643: `searchSpotify()` method
- Lines 430-571: `updateTrendingTracksForLanguage()` method

### In SpotifyDashboardApp.swift:
- Line 14: `FirebaseApp.configure()` call

### In Config.swift:
- Lines 12-13: Spotify credentials
- Lines 18-19: Reddit credentials

---

## 📝 NOTES

- Spotify access tokens expire and are auto-refreshed by SpotifyManager
- Firebase is initialized once at app startup
- Reddit integration uses simulated authentication (demo mode)
- All managers use ObservableObject pattern for SwiftUI integration
- Caching is implemented in SpotifyManager (5-minute cache validity)

---

## 🔄 IF YOU NEED TO RESTORE

If something breaks, restore from:
1. Git history: `git checkout HEAD -- [file path]`
2. The backups created above
3. This documentation

---

**Created:** $(date)
**Purpose:** Safeguard Spotify API and Firebase integrations during refactoring
**Status:** Ready for big changes ✅

