# 🔌 API Integration Quick Reference

## 🎵 Spotify API Integration

### Authentication Endpoint
```
POST https://accounts.spotify.com/api/token
Headers:
  - Authorization: Basic [base64(clientId:clientSecret)]
  - Content-Type: application/x-www-form-urlencoded
Body: grant_type=client_credentials
```

### Search Endpoint
```
GET https://api.spotify.com/v1/search
Query Parameters:
  - q: search query
  - type: artist,track (or individual types)
  - limit: number of results (default: 20)
  - market: country code (US, GB, IN, etc.)
Headers:
  - Authorization: Bearer [access_token]
```

### Popular Artists Endpoint
```
GET https://api.spotify.com/v1/search?q=[artist_name]&type=artist&limit=1&market=[country]
Headers:
  - Authorization: Bearer [access_token]
```

### Trending Tracks Endpoint
```
GET https://api.spotify.com/v1/search?q=[query]&type=track&limit=10&market=[country]
Headers:
  - Authorization: Bearer [access_token]
```

---

## 📱 Reddit API Integration

### Subreddit Posts Endpoint
```
GET https://www.reddit.com/r/[subreddit]/hot.json?limit=[count]
Headers:
  - User-Agent: BeatWise iOS App 1.0
```

### Supported Music Subreddits:
- music, listentothis, indieheads, hiphopheads, popheads
- electronicmusic, rock, jazz, classicalmusic, country
- kpop, bollywood, tollywood, kollywood, sandalwood
- malayalammusic, bengalimusic, marathimusic, gujaratimusic
- punjabimusic, spanishmusic, frenchmusic, germanmusic
- italianmusic, portuguesemusic, koreanmusic, japanesemusic
- chinesemusic

---

## 🔥 Firebase Integration

### Initialization
```swift
import Firebase

@main
struct BeatWiseApp: App {
    init() {
        FirebaseApp.configure()
    }
}
```

### Configuration File
- File: `GoogleService-Info.plist`
- Must be in app bundle
- Contains API keys and project settings

---

## 🌍 Language Support

### Spotify Market Codes by Language:
- English: US
- Hindi/Tamil/Telugu/etc: IN
- Spanish: ES
- French: FR
- German: DE
- Italian: IT
- Portuguese: BR
- Korean: KR
- Japanese: JP
- Chinese: TW

### Language Codes:
```swift
.en, .hi, .ta, .te, .kn, .ml, .bn, .mr, .gu, .pa
.es, .fr, .de, .it, .pt, .ko, .ja, .zh
```

---

## 🔑 Credentials Storage

### Current Credentials Location:
- File: `Config.swift`
- Spotify credentials (lines 12-13)
- Reddit credentials (lines 18-19)

### Environment Variables Alternative:
Consider moving credentials to:
- Environment variables
- Secure keychain storage
- Separate config file (not committed to git)

---

## 📊 Data Models

### Key Spotify Models:
- `Artist` - id, name, popularity, images, followers
- `Track` - id, name, popularity, artists, album, preview_url
- `Album` - id, name, images, release_date
- `SpotifyImage` - url, height, width
- `ExternalUrls` - spotify

### Key Reddit Models:
- `RedditPost` - id, title, author, subreddit, score, comments
- `MusicTopic` - title, sentiment, artists, tracks
- `TrendingMusicTopic` - topic, trendingScore, spotifyMatches

---

## 🎯 Integration Points

### SpotifyManager → RedditManager:
- `searchSpotifyInternal(query:)` method
- Used to match Reddit topics with Spotify tracks

### RedditManager → SpotifyManager:
- `setSpotifyManager(_:)` method
- Enables RedditManager to search Spotify

### PlaylistManager:
- Connects RedditManager and SpotifyManager
- Creates playlists from Reddit topics and Spotify tracks

---

## ⚡ Performance Optimizations

### Caching Strategy:
- Artist cache: 5 minutes validity
- Track cache: 5 minutes validity
- Cache keys: "popular_artists", "trending_tracks_[language]"

### Concurrent Fetching:
- Uses `withTaskGroup` for parallel API calls
- Fetches multiple artists/tracks simultaneously

### Rate Limiting:
- Auto-refresh every 5 minutes
- Manual refresh available
- Debounced language changes (300ms)

---

## 🚨 Error Handling

### SpotifyManager Errors:
- Invalid URL
- HTTP Error
- No Data
- Authentication Failed (auto-retry)

### RedditManager Errors:
- Invalid URL
- No Data
- Decoding Error
- Rate Limited
- Network Error
- Authentication Required

---

## 🔄 Update Flow

### Automatic Updates:
```
Timer → every 5 minutes → updateTrendingTracksForLanguage()
```

### Manual Refresh:
```
Pull-to-refresh → refreshData() → getPopularArtists() + getTrendingTracks()
```

### Language Change:
```
LanguageSelectionView → selectedLanguage change → updateTrendingTracksForLanguage()
```

---

## 📱 UI Integration

### Managers Used by Views:
- `BeatWiseView` → SpotifyManager, RedditManager
- `CrowdPlaylistsView` → PlaylistManager, SpotifyManager, RedditManager
- `MusicSocialPage` → RedditManager, SpotifyManager
- `ArtistFanStreamView` → SpotifyManager
- `MainPage` → SpotifyManager

### State Management:
- All managers use `@Published` properties
- `@ObservedObject` for shared instances
- `@StateObject` for owned instances

---

## 🛠️ Troubleshooting

### Spotify Token Expired:
- Automatically refreshed by `getAccessToken()`
- Check console for "Failed to get access token" messages

### Firebase Not Initializing:
- Verify `GoogleService-Info.plist` is in bundle
- Check Firebase SDK is added to project
- Verify bundle ID matches Firebase project

### Reddit API Rate Limited:
- Error message: "Reddit API rate limit exceeded"
- Wait 60 seconds before retrying
- Consider adding exponential backoff

---

**Last Updated:** $(date)
**Maintained By:** Development Team

