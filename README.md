# 🎵 Music Story Companion

**An immersive iOS reading app with adaptive music, AI-powered insights, and comprehensive mood tracking**

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## 🎯 Overview

Music Story Companion is a modern iOS app that combines reading, music, and AI to create an immersive and personalized reading experience. Track your emotional journey through literature while adaptive music enhances your reading sessions.

### ✨ Key Features

- 📚 **70,000+ Free Books** - Access the complete Project Gutenberg library
- 🎵 **Adaptive Music** - Jamendo integration with mood-based track selection
- 🎭 **Mood Diary** - Track emotions and reading progress with visual analytics
- 🤖 **AI Insights** - Apple Foundation Models power personalized recommendations
- 🎙️ **Podcasts** - Discover podcasts based on your reading mood
- 👤 **Author Discovery** - Explore authors and life lessons from their works
- ☁️ **Cloud Sync** - Firebase integration for seamless data backup
- 🔐 **Multiple Auth** - Google, Apple, or Anonymous sign-in options

---

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0+
- iOS 16.0+ device or simulator
- Swift 5.0+
- CocoaPods or Swift Package Manager

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ash1234-dj/Spotify-Dashboard.git
   cd Spotify-Dashboard
   ```

2. **Open in Xcode**
   ```bash
   open "Spotify Dashboard 4/Spotify Dashboard.xcodeproj"
   ```

3. **Configure Firebase**
   - Add your `GoogleService-Info.plist` to the project
   - Ensure Firebase is configured in your project

4. **Configure API Keys**
   - Update `Config.swift` with your API keys (if needed)
   - Jamendo API is pre-configured
   - ListenNotes API is pre-configured

5. **Build and Run**
   - Select your target device
   - Press `Cmd + R` to build and run

---

## 📱 Features Explained

### 📖 Reading Interface

- **Pagination** - Books divided into readable pages (200-250 words each)
- **Progress Tracking** - Visual progress bars and percentage completion
- **Customizable** - Font size, line spacing, dark mode, dyslexia-friendly fonts
- **Bookmarks** - Save your reading position automatically
- **AI Summaries** - Generate book summaries using Apple Foundation Models

### 🎵 Adaptive Music

- **Jamendo Integration** - Free instrumental music library
- **Mood-Based Selection** - AI chooses tracks based on book content
- **Custom Controls** - Play, pause, volume, and skip functionality
- **Queue Management** - See upcoming tracks and skip between them

### 🎭 Mood Diary

- **Emotion Tracking** - Select from 10 available emotions
- **Visual Analytics** - Emoji-based mood indicators (1-10 scale)
- **Reading Progress** - Track how far you've read in each book
- **Notes** - Add personal reflections to each entry
- **AI Insights** - Get personalized patterns, trends, and recommendations

### 🤖 AI Features

**Apple Foundation Models Integration:**
- Device checks for compatibility (iOS 26+)
- Graceful fallback to pattern-based analysis
- On-device processing for privacy
- Natural Language framework for sentiment analysis

**Insights Provided:**
- Key insights about reading patterns
- Mood trend detection (Improving/Stable/Declining)
- Personalized recommendations
- Book summaries and analysis

### 🎙️ Podcasts

- **10 Mood Categories** - Calm, Inspired, Sad, Curious, Anxious, Happy, Reflective, Excited, Nostalgic, Focused
- **ListenNotes API** - Access to millions of podcasts
- **Episode Playback** - In-app streaming with progress tracking
- **AI Recommendations** - Get explanations for podcast suggestions
- **Mini Player** - Control playback from anywhere in the app

### 👤 Author Discovery

- **Open Library API** - Comprehensive author database
- **Life Lessons** - AI-generated wisdom from authors' works
- **Works Catalog** - Browse all books by an author
- **Biographical Info** - Birth/death dates, genres, and subjects

---

## 🏗️ Technical Architecture

### Tech Stack

- **UI Framework**: SwiftUI
- **AI Framework**: Apple Foundation Models (iOS 26+)
- **Language Analysis**: Natural Language framework
- **Backend**: Firebase (Firestore, Authentication)
- **Networking**: URLSession with async/await
- **Audio**: AVFoundation for playback
- **Local Storage**: UserDefaults, Core Data

### API Integrations

| API | Purpose | Status |
|-----|---------|--------|
| Gutendex | Book content from Gutenberg Project | ✅ Working |
| Open Library | Author information and life lessons | ✅ Working |
| ListenNotes | Podcast discovery and metadata | ✅ Working |
| Jamendo | Instrumental music for reading | ✅ Working |
| Firebase | Cloud sync and authentication | ✅ Working |

### File Structure

```
Spotify Dashboard 4/
├── Views/
│   ├── SpotifyDashboardApp.swift      # App entry point
│   ├── MainAppView.swift               # Tab navigation
│   ├── ReadingSessionView.swift        # Reading interface
│   ├── StorySelectionView.swift        # Book library
│   ├── MoodDiaryView.swift             # Mood tracking
│   ├── AuthorDiscoveryView.swift       # Author search
│   ├── PodcastView.swift               # Podcast discovery
│   └── SettingsView.swift              # App settings
│
├── Managers/
│   ├── GutendexManager.swift           # Book fetching
│   ├── OpenLibraryManager.swift        # Author info
│   ├── PodcastManager.swift            # ListenNotes API
│   ├── JamendoManager.swift            # Music
│   ├── SpotifyManager.swift            # Spotify auth
│   ├── MoodAnalyzer.swift              # AI insights
│   ├── FoundationModelsManager.swift   # Foundation Models
│   └── FirebaseSyncManager.swift       # Cloud sync
│
├── Models/
│   ├── Book models                     # Gutendex structures
│   ├── Mood models                     # Diary entries
│   └── Audio models                    # Playback
│
└── Resources/
    ├── GoogleService-Info.plist        # Firebase config
    ├── Assets.xcassets/                # App icons
    └── Config.swift                    # API keys
```

---

## 🎨 Design

- **Glass-morphism** - Modern frosted glass effect throughout
- **Purple-to-Blue Gradients** - Consistent color scheme
- **SF Symbols** - Native iOS icon library
- **Dark Mode** - Full support for system theme
- **Animations** - Smooth transitions and feedback
- **Accessibility** - VoiceOver, Dynamic Type, high contrast

---

## 🔒 Privacy & Security

- **On-Device AI** - Foundation Models process data locally
- **Firebase Auth** - Secure authentication options
- **No Data Collection** - Privacy-first approach
- **User-Controlled Sync** - Opt-in cloud backup
- **No Tracking** - No analytics or advertising

---

## 📊 Project Statistics

- **Total Files**: 40+ Swift files
- **Lines of Code**: ~5,000+
- **Features**: 50+ unique capabilities
- **API Integrations**: 5 external services
- **Completion**: 95%

---

## 🗺️ Roadmap

### Immediate (Next Sprint)
- [ ] Complete end-to-end testing
- [ ] App Store screenshots and metadata
- [ ] Privacy policy and terms of service
- [ ] TestFlight beta testing

### Near Future
- [ ] Spotify playback integration
- [ ] Social sharing features
- [ ] Reading goals and challenges
- [ ] Community book recommendations

### Future Ideas
- [ ] Multi-language support
- [ ] Reading analytics dashboard
- [ ] Export mood data
- [ ] Custom theme creator

---

## 🤝 Contributing

This is currently a personal project, but contributions and suggestions are welcome!

### Areas for Contribution

- 🐛 **Bug Reports** - Help improve stability
- 💡 **Feature Ideas** - Suggest new capabilities
- 🎨 **UI/UX** - Design improvements
- 📝 **Documentation** - Code comments and guides
- 🧪 **Testing** - Help test on various devices

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Project Gutenberg** - Free book library
- **Gutendex** - Gutenberg search API
- **Open Library** - Author information
- **ListenNotes** - Podcast search
- **Jamendo** - Free music
- **Firebase** - Backend services
- **Apple** - Foundation Models and SwiftUI

---

## 📞 Contact

**Developer**: Ashfaq Ahmed  
**GitHub**: [@ash1234-dj](https://github.com/ash1234-dj)  
**Repository**: [Spotify-Dashboard](https://github.com/ash1234-dj/Spotify-Dashboard)

---

## 📝 Changelog

### Version 1.0 (Current)
- ✅ Complete book library integration
- ✅ Adaptive music with Jamendo
- ✅ Mood diary with AI insights
- ✅ Podcast discovery and playback
- ✅ Author discovery with life lessons
- ✅ Firebase cloud sync
- ✅ Multiple authentication methods
- ✅ Apple Foundation Models integration

---

**Made with ❤️ using Swift and SwiftUI**

*Transform your reading experience with Music Story Companion* 📚🎵✨

