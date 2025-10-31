# 📍 Where to See Foundation Models in Your App

## 🎯 Location: Mood Diary Tab

Foundation Models appears in the **Diary tab** of your app when analyzing reading mood patterns.

---

## 🔍 Step-by-Step Guide

### 1. Open the App
- Launch "Music Story Companion"
- Navigate to the **Diary** tab (bottom navigation)

### 2. Add a Mood Entry
- Tap the **"+"** button in the top right
- Fill in your reading session details:
  - Book title
  - Mood score (1-10)
  - Emotions (Happy, Calm, Inspired, etc.)
  - Notes
  - Reading progress
- Tap **"Save"**

### 3. View AI Insights
- Return to the Diary tab
- You'll see a card titled **"🧠 AI Insights"**
- **Look for the badge** next to the title

---

## 🍎 When Foundation Models is Active

### You'll See:
```
🧠 AI Insights  [🍎 Apple Intelligence]  📈
```

### What This Means:
- ✅ Foundation Models is available on your device
- ✅ Using Apple's 3B parameter on-device LLM
- ✅ AI-powered analysis is active
- ✅ Privacy-preserving on-device processing

---

## 📱 When Foundation Models is NOT Available

### You'll See:
```
🧠 AI Insights  📈
```

### What This Means:
- ℹ️ Foundation Models not available (iOS 26+ required)
- ✅ Using enhanced pattern analysis instead
- ✅ All features still work perfectly
- ✅ No AI badge shown

---

## 🎨 Visual Indicators

### Badge Appearance:
- **Background**: Light gray (`systemGray6`)
- **Icon**: 🍎 Apple logo
- **Text**: "Apple Intelligence"
- **Position**: Right of "AI Insights" title

### Card Layout:
```
┌─────────────────────────────────────────────┐
│ 🧠 AI Insights  [🍎 Apple Intelligence]  📈 │
├─────────────────────────────────────────────┤
│ Key Insights                                 │
│ 💡 Insight 1...                              │
│ 💡 Insight 2...                              │
│                                              │
│ Patterns Detected                            │
│ 📊 Pattern 1...                               │
│ 📊 Pattern 2...                               │
│                                              │
│ Recommendations                              │
│ ⭐ Recommendation 1...                        │
│ ⭐ Recommendation 2...                        │
└─────────────────────────────────────────────┘
```

---

## 🔧 Requirements for Foundation Models

### To See the Badge, You Need:
- **iOS 26.0+** / **macOS 26.0+** / **iPadOS 26.0+**
- **Apple Silicon** device (A17 Pro or later)
- **Apple Intelligence** enabled in Settings
- Foundation Models available in your region

### Current Status:
Since iOS 26/macOS 26 hasn't been released yet:
- Badge will appear when Apple releases the update
- Until then, you'll see enhanced pattern analysis
- App works perfectly without the badge

---

## 🧪 How to Test

### 1. Check Console Logs
When you add a mood entry, check Xcode console for:
```
✅ Apple Foundation Models available
```
or
```
ℹ️ Using enhanced pattern analysis
```

### 2. Check Badge Display
- Add multiple mood entries
- Navigate to Diary tab
- Look for the badge on the AI Insights card

### 3. Test Insights Quality
With Foundation Models:
- More natural language responses
- Context-aware recommendations
- Personalized insights

Without Foundation Models:
- Pattern-based analysis
- Rule-based recommendations
- Still helpful and functional

---

## 📊 What the AI Insights Show

### Key Insights Section:
- Overall reading experience summary
- Emotional patterns detected
- Reading habits observed

### Patterns Detected Section:
- Mood trends over time
- Genre preferences
- Reading frequency patterns

### Recommendations Section:
- Book suggestions
- Reading tips
- Personalized advice

---

## 🎯 Summary

**Where to Look**: Diary Tab → AI Insights Card → Badge next to title

**What to Expect**:
- Badge = Foundation Models active ✅
- No badge = Enhanced analysis active ✅
- Both work perfectly! 🎉

---

**Visual Guide**:
```
App Navigation
    ↓
Diary Tab (📖 bookmark icon)
    ↓
AI Insights Card (top of list)
    ↓
Look for: [🍎 Apple Intelligence] badge
```


