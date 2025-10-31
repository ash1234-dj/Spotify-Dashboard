//
//  MoodDiaryView.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import SwiftUI
import NaturalLanguage

struct MoodDiaryView: View {
    @EnvironmentObject var gutendexManager: GutendexManager
    @EnvironmentObject var moodTracker: MoodTracker
    @StateObject private var foundationModelsManager = FoundationModelsManager()
    
    @State private var showingNewEntry = false
    @State private var selectedEntry: MoodEntry?
    @State private var showingAISummary = false
    @State private var entryForAISummary: MoodEntry?
    @State private var isEditMode = false
    @State private var selectedEntries: Set<UUID> = []
    
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
                
                if moodTracker.entries.isEmpty {
                    emptyStateView
                } else {
                    moodEntriesList
                }
            }
            .navigationTitle("Mood Diary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !moodTracker.entries.isEmpty {
                        Button(isEditMode ? "Done" : "Edit") {
                            isEditMode.toggle()
                            if !isEditMode {
                                selectedEntries.removeAll()
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if isEditMode && !selectedEntries.isEmpty {
                            Button("Delete All") {
                                deleteSelectedEntries()
                            }
                            .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            showingNewEntry = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewMoodEntryView(moodTracker: moodTracker)
            }
            .sheet(item: $selectedEntry) { entry in
                MoodEntryDetailView(entry: entry, moodTracker: moodTracker)
            }
            .sheet(isPresented: $showingAISummary) {
                if !moodTracker.entries.isEmpty {
                    AIMoodSummaryView(entries: moodTracker.entries)
                }
            }
        }
    }
    
    // MARK: - Mood Entries List
    
    var moodEntriesList: some View {
            ScrollView {
                VStack(spacing: 16) {
                    // AI Summary Button
                    if !moodTracker.entries.isEmpty {
                        Button(action: {
                            showingAISummary = true
                        }) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .font(.title2)
                                
                                Text("Get AI Summary of All Entries")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "sparkles")
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
                        .padding(.horizontal)
                    }
                    
                    // Mood entries
                    ForEach(moodTracker.entries) { entry in
                        MoodEntryCard(
                            entry: entry,
                            onTap: {
                                selectedEntry = entry
                            },
                            onDelete: {
                                moodTracker.deleteEntry(entry)
                            },
                            isEditMode: isEditMode,
                            isSelected: selectedEntries.contains(entry.id),
                            onSelectionToggle: {
                                if selectedEntries.contains(entry.id) {
                                    selectedEntries.remove(entry.id)
                                } else {
                                    selectedEntries.insert(entry.id)
                                }
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                moodTracker.deleteEntry(entry)
                            }
                        }
                    }
                }
                .padding()
            }
    }
    
    // MARK: - Empty State
    
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 80))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("No Mood Entries Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Track your emotions and reactions while reading to get AI-powered insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                showingNewEntry = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Entry")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.purple, Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func deleteSelectedEntries() {
        let entriesToDelete = moodTracker.entries.filter { selectedEntries.contains($0.id) }
        for entry in entriesToDelete {
            moodTracker.deleteEntry(entry)
        }
        selectedEntries.removeAll()
        isEditMode = false
    }
}

// MARK: - Mood Entry Models

struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let bookTitle: String
    let moodScore: Int // 1-10
    let emotions: [String]
    let notes: String
    let readingProgress: CGFloat
    let musicGenre: String?
    
    var emoji: String {
        switch moodScore {
        case 1...3: return "😢"
        case 4...5: return "😐"
        case 6...7: return "🙂"
        case 8...9: return "😊"
        case 10: return "😍"
        default: return "😐"
        }
    }
}

struct AIInsight: Identifiable {
    let id: UUID
    let date: Date
    let insights: [String]
    let patterns: [String]
    let recommendations: [String]
    let trend: MoodTrend
    
    enum MoodTrend {
        case improving
        case stable
        case declining
        
        var emoji: String {
            switch self {
            case .improving: return "📈"
            case .stable: return "➡️"
            case .declining: return "📉"
            }
        }
        
        var color: Color {
            switch self {
            case .improving: return .green
            case .stable: return .blue
            case .declining: return .orange
            }
        }
    }
}

// MARK: - Mood Tracker

class MoodTracker: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var latestInsight: AIInsight?
    @Published var isAnalyzing = false
    
    let aiGenerator = AIMoodInsightsGenerator()
    
    init() {
        loadEntries()
        // Don't generate AI insights automatically
    }
    
    func addEntry(_ entry: MoodEntry) {
        entries.insert(entry, at: 0)
        saveEntries()
    }
    
    func deleteEntry(_ entry: MoodEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }
    
    func generateAIInsights() {
        guard !entries.isEmpty else { return }
        
        Task {
            await aiGenerator.generateInsights(from: entries)
            
            await MainActor.run {
                latestInsight = aiGenerator.latestInsight
                isAnalyzing = aiGenerator.isAnalyzing
            }
        }
    }
    
    func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "moodEntries")
        }
    }
    
    func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            entries = decoded
        }
    }
}

    // MARK: - AI Insight Card
    
struct AIInsightCard: View {
    let insight: AIInsight
    let isFoundationModelsAvailable: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("AI Insights")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if isFoundationModelsAvailable {
                    HStack(spacing: 4) {
                        Image(systemName: "applelogo")
                            .font(.caption)
                        Text("Apple Intelligence")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                Text(insight.trend.emoji)
                    .font(.title2)
            }
            
            if !insight.insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Insights")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(insight.insights, id: \.self) { insight in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(insight)
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            if !insight.patterns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Patterns Detected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(insight.patterns, id: \.self) { pattern in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(insight.trend.color)
                                .font(.caption)
                            Text(pattern)
                                .font(.subheadline)
                        }
                    }
                }
            }
            
            if !insight.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(insight.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.purple)
                                .font(.caption)
                            Text(recommendation)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Mood Entry Card

struct MoodEntryCard: View {
    let entry: MoodEntry
    let onTap: () -> Void
    let onDelete: () -> Void
    let isEditMode: Bool
    let isSelected: Bool
    let onSelectionToggle: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Selection checkbox (in edit mode)
            if isEditMode {
                Button(action: onSelectionToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Mood emoji
            Text(entry.emoji)
                .font(.system(size: 40))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.bookTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    Text(entry.emotions.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(entry.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                // Delete button (only in edit mode)
                if isEditMode {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Tap to view button (only when not in edit mode)
                if !isEditMode {
                    Button(action: onTap) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this mood entry? This action cannot be undone.")
        }
    }
}

// MARK: - New Mood Entry View

struct NewMoodEntryView: View {
    @ObservedObject var moodTracker: MoodTracker
    @EnvironmentObject var gutendexManager: GutendexManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var moodScore: Double = 5.0
    @State private var selectedEmotions: Set<String> = []
    @State private var notes = ""
    @State private var readingProgress: Double = 0.0
    @State private var selectedBook: String = ""
    @State private var showingBookPicker = false
    
    private let availableEmotions = [
        "Happy", "Sad", "Excited", "Calm", "Anxious",
        "Inspired", "Nostalgic", "Focused", "Relaxed", "Thoughtful"
    ]
    
    private func toggleEmotion(_ emotion: String) {
        print("🎭 Toggling: \(emotion), current selection: \(selectedEmotions)")
        if selectedEmotions.contains(emotion) {
            selectedEmotions.remove(emotion)
            print("✅ Removed: \(emotion)")
        } else {
            selectedEmotions.insert(emotion)
            print("✅ Added: \(emotion)")
        }
        print("🎭 New selection: \(selectedEmotions)")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Book") {
                    Button(action: {
                        showingBookPicker = true
                    }) {
                        HStack {
                            Text(selectedBook.isEmpty ? (gutendexManager.bookContent?.title ?? "No book selected") : selectedBook)
                                .foregroundColor(selectedBook.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .sheet(isPresented: $showingBookPicker) {
                    BookPickerView(selectedBook: $selectedBook)
                }
                
                Section("Mood Score") {
                    VStack(spacing: 12) {
                        Text("\(Int(moodScore))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.purple)
                        
                        Slider(value: $moodScore, in: 1...10, step: 1)
                        
                        HStack {
                            Text("😢")
                            Spacer()
                            Text("😐")
                            Spacer()
                            Text("😊")
                            Spacer()
                            Text("😍")
                        }
                        .font(.caption)
                    }
                }
                
                Section {
                    VStack(spacing: 12) {
                        ForEach(availableEmotions, id: \.self) { emotion in
                            let isSelected = selectedEmotions.contains(emotion)
                            
                            Button(action: {
                                toggleEmotion(emotion)
                            }) {
                                HStack {
                                    Text(emotion)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .foregroundColor(isSelected ? .white : .primary)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    isSelected ?
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
                                .cornerRadius(10)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Emotions")
                }
                
                Section("Notes") {
                    TextField("How did this story make you feel?", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Reading Progress") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(Int(readingProgress * 100))% Complete")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $readingProgress, in: 0...1)
                    }
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(selectedEmotions.isEmpty)
                }
            }
        }
    }
    
    func saveEntry() {
        let bookTitle = selectedBook.isEmpty ? (gutendexManager.bookContent?.title ?? "Unknown") : selectedBook
        
        let entry = MoodEntry(
            id: UUID(),
            date: Date(),
            bookTitle: bookTitle,
            moodScore: Int(moodScore),
            emotions: Array(selectedEmotions),
            notes: notes,
            readingProgress: readingProgress,
            musicGenre: UserDefaults.standard.array(forKey: "selectedGenres")?.first as? String
        )
        
        moodTracker.addEntry(entry)
        dismiss()
    }
}

// MARK: - Emotion Toggle Button

struct EmotionToggleButton: View {
    let emotion: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("🔘 Button tapped for: \(emotion), isSelected: \(isSelected)")
            action()
        }) {
            HStack {
                Text(emotion)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color.gray.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Mood Entry Detail View

struct MoodEntryDetailView: View {
    let entry: MoodEntry
    @ObservedObject var moodTracker: MoodTracker
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiSummarizer = FoundationModelsManager()
    @State private var aiSummary: String = ""
    @State private var isGeneratingSummary = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text(entry.emoji)
                            .font(.system(size: 80))
                        
                        Text(entry.bookTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(entry.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    // AI Summary Button
                    Button(action: {
                        generateAISummary()
                    }) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .font(.title3)
                            
                            Text("Get AI Summary & Solutions")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if isGeneratingSummary {
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
                    .disabled(isGeneratingSummary)
                    .padding(.horizontal)
                    
                    // AI Summary Results
                    if !aiSummary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.purple)
                                Text("AI Summary")
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                            
                            Text(aiSummary)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(title: "Mood Score", value: "\(entry.moodScore)/10")
                        InfoRow(title: "Emotions", value: entry.emotions.joined(separator: ", "))
                        InfoRow(title: "Progress", value: "\(Int(entry.readingProgress * 100))%")
                        if let genre = entry.musicGenre {
                            InfoRow(title: "Music", value: genre)
                        }
                    }
                    .padding()
                    
                    // Notes
                    if !entry.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            Text(entry.notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Entry Details")
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
    
    func generateAISummary() {
        isGeneratingSummary = true
        
        Task {
            // Create a comprehensive summary request
            let summary = await aiSummarizer.generateDetailedSummary(for: entry)
            
            await MainActor.run {
                aiSummary = summary
                isGeneratingSummary = false
            }
        }
    }
}

// MARK: - Book Picker View

struct BookPickerView: View {
    @Binding var selectedBook: String
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gutendexManager: GutendexManager
    @State private var searchText = ""
    
    var filteredBooks: [GutendexBook] {
        if searchText.isEmpty {
            return gutendexManager.allBooks
        } else {
            return gutendexManager.allBooks.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.primaryAuthor.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search books...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Book list
                List {
                    // Current reading
                    if let currentBook = gutendexManager.bookContent {
                        Section("Currently Reading") {
                            Button(action: {
                                selectedBook = currentBook.title
                                dismiss()
                            }) {
                                HStack {
                                    Text(currentBook.title)
                                    Spacer()
                                    if selectedBook == currentBook.title {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                    }
                    
                    // All books from Gutendex
                    Section("All Books (\(filteredBooks.count))") {
                        ForEach(filteredBooks.prefix(100)) { book in
                            Button(action: {
                                selectedBook = book.title
                                dismiss()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(book.primaryAuthor)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .overlay(
                                    Group {
                                        if selectedBook == book.title {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.purple)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load books if not already loaded
                if gutendexManager.allBooks.isEmpty {
                    Task {
                        await gutendexManager.getPopularBooks()
                    }
                }
            }
        }
    }
}

// MARK: - AI Mood Summary View

struct AIMoodSummaryView: View {
    let entries: [MoodEntry]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiSummarizer = FoundationModelsManager()
    @State private var selectedEntry: MoodEntry?
    @State private var aiSummary: String = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if selectedEntry == nil {
                        // Selection view
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 60))
                                .foregroundColor(.purple)
                            
                            Text("Select a Mood Entry to Analyze")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Choose which diary entry you'd like AI to analyze and provide insights for")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(entries) { entry in
                                    Button(action: {
                                        selectedEntry = entry
                                    }) {
                                        HStack {
                                            Text(entry.emoji)
                                                .font(.system(size: 30))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(entry.bookTitle)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text(entry.emotions.joined(separator: ", "))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                    } else {
                        // Analysis view
                        VStack(spacing: 20) {
                            // Selected entry info
                            VStack(spacing: 8) {
                                Text(selectedEntry!.emoji)
                                    .font(.system(size: 50))
                                
                                Text(selectedEntry!.bookTitle)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                Text("Mood: \(selectedEntry!.moodScore)/10")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            
                            // Generate button
                            Button(action: {
                                generateSummary()
                            }) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                    Text("Generate AI Summary & Tips")
                                    Spacer()
                                    if isGenerating {
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
                            .disabled(isGenerating)
                            .padding(.horizontal)
                            
                            // AI Summary
                            if !aiSummary.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "brain.head.profile")
                                            .foregroundColor(.purple)
                                        Text("AI Analysis")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                    }
                                    
                                    Text(aiSummary)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Change selection button
                            Button(action: {
                                selectedEntry = nil
                                aiSummary = ""
                            }) {
                                Text("Choose Different Entry")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("AI Summary")
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
    
    func generateSummary() {
        guard let entry = selectedEntry else { return }
        
        isGenerating = true
        
        Task {
            let summary = await aiSummarizer.generateDetailedSummary(for: entry)
            
            await MainActor.run {
                aiSummary = summary
                isGenerating = false
            }
        }
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

