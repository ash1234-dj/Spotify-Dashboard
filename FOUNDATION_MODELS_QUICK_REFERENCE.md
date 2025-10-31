# 🚀 Apple Foundation Models - Quick Reference

## Before vs After

### Before (Without Foundation Models)
```swift
// Simple pattern analysis
let avgMood = entries.map { $0.moodScore }.reduce(0, +) / entries.count
if avgMood > 7 {
    recommendations.append("Keep reading!")
}
```

### After (With Foundation Models)
```swift
// AI-powered analysis with structured output
@Generable
struct MoodInsight {
    let keyInsights: [String]
    let detectedPatterns: [String]
    let personalizedRecommendations: [String]
}

let session = LanguageModelSession()
let insight = try await session.generate(prompt, type: MoodInsight.self)
```

---

## Quick Start

### 1. Check Availability
```swift
#if canImport(FoundationModels)
if #available(iOS 18.0, macOS 15.0, *) {
    // Use Foundation Models
}
#endif
```

### 2. Create Session
```swift
let session = LanguageModelSession()
```

### 3. Build Prompt
```swift
let prompt = PromptBuilder {
    "You are an AI assistant..."
    "Analyze this data: \(data)"
}
```

### 4. Generate Response
```swift
// Text response
let response = try await session.generate(prompt)

// Structured response
@Generable
struct MyStruct {
    let field1: String
    let field2: Int
}
let result = try await session.generate(prompt, type: MyStruct.self)
```

---

## Code Examples

### Mood Analysis
```swift
let generator = AIMoodInsightsGenerator()
await generator.generateInsights(from: moodEntries)
// Returns: AIInsight with insights, patterns, recommendations
```

### Book Recommendations
```swift
let manager = FoundationModelsManager()
await manager.generateRecommendations(
    basedOn: moodEntries,
    availableBooks: books
)
// Returns: [BookRecommendation]
```

### Reading Summary
```swift
let summary = await manager.generateReadingSummary(for: moodEntry)
// Returns: String with motivational summary
```

---

## File Structure

```
Spotify Dashboard/
├── MoodAnalyzer.swift              (AI Mood Analysis)
├── FoundationModelsManager.swift   (Recommendations & Summaries)
├── MoodDiaryView.swift             (UI with AI Indicators)
└── Config.swift                    (App Configuration)
```

---

## UI Indicators

### With AI Available:
```
🧠 AI Insights [🍎 Apple Intelligence]
```

### Without AI (Fallback):
```
🧠 AI Insights
```

User sees enhanced insights but no badge.

---

## Testing Checklist

- [ ] Add mood entries
- [ ] Check AI badge appears (iOS 18+)
- [ ] Verify insights display
- [ ] Test on older device
- [ ] Confirm no crashes
- [ ] Verify graceful fallback

---

## Key Features

✅ **Privacy**: 100% on-device
✅ **Free**: No API costs
✅ **Offline**: No internet needed
✅ **Universal**: Works on all devices
✅ **Smart**: AI when available, fallback when not

---

## Documentation

- 📖 **FOUNDATION_MODELS_IMPLEMENTATION.md** - Full guide
- 📋 **APPLE_FOUNDATION_MODELS_SUMMARY.md** - Summary
- 📝 **FOUNDATION_MODELS_QUICK_REFERENCE.md** - This file

---

## Apple Resources

- 🎥 [Foundation Models Tutorial](https://developer.apple.com/videos/play/meet-with-apple/205/)
- 📚 FoundationModels Framework Documentation
- 💻 WWDC25: "Meet Apple Foundation Models"

---

**Status**: ✅ Ready to Use
**Version**: 1.0
**Date**: January 2025


