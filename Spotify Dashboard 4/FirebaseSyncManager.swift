//
//  FirebaseSyncManager.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

// MARK: - Firebase Data Models

struct ReadingSession: Codable, Identifiable {
    let id: String
    let bookTitle: String
    let bookAuthor: String
    let startTime: Date
    let endTime: Date?
    let readingProgress: Double
    let musicGenre: String?
    let notes: String?
    
    init(id: String = UUID().uuidString,
         bookTitle: String,
         bookAuthor: String,
         startTime: Date = Date(),
         endTime: Date? = nil,
         readingProgress: Double = 0.0,
         musicGenre: String? = nil,
         notes: String? = nil) {
        self.id = id
        self.bookTitle = bookTitle
        self.bookAuthor = bookAuthor
        self.startTime = startTime
        self.endTime = endTime
        self.readingProgress = readingProgress
        self.musicGenre = musicGenre
        self.notes = notes
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
}

struct MoodDiaryEntry: Codable, Identifiable {
    let id: String
    let date: Date
    let bookTitle: String
    let moodScore: Int
    let emotions: [String]
    let notes: String
    let readingProgress: Double
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

// MARK: - Firebase Sync Manager

class FirebaseSyncManager: ObservableObject {
    enum StorageMode {
        case local
        case firestore
    }
    
    @Published var readingSessions: [ReadingSession] = []
    @Published var moodDiaryEntries: [MoodDiaryEntry] = []
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let db = Firestore.firestore()
    private let userId: String
    private let storageMode: StorageMode = .local // Default to local-only while sign-in is disabled
    
    // UserDefaults keys
    private let readingSessionsKey = "local_readingSessions"
    private let moodDiaryKey = "local_moodDiaryEntries"
    
    init() {
        // For now, use a demo user ID
        // In production, this would be the authenticated user's ID
        self.userId = "demo_user_\(UUID().uuidString)"
        print("🔐 Firebase Sync Manager initialized for user: \(userId)")
    }
    
    // MARK: - Save Reading Session
    
    func saveReadingSession(_ session: ReadingSession) async {
        isSyncing = true
        switch storageMode {
        case .local:
            // Append to local array and persist
            var all = await loadReadingSessionsLocal()
            if let idx = all.firstIndex(where: { $0.id == session.id }) {
                all[idx] = session
            } else {
                all.insert(session, at: 0)
            }
            await saveReadingSessionsLocal(all)
            await MainActor.run {
                self.readingSessions = all
                self.isSyncing = false
                self.lastSyncDate = Date()
                self.syncError = nil
                print("✅ Saved reading session locally: \(session.bookTitle)")
            }
        case .firestore:
            do {
                let sessionData: [String: Any] = [
                    "id": session.id,
                    "bookTitle": session.bookTitle,
                    "bookAuthor": session.bookAuthor,
                    "startTime": Timestamp(date: session.startTime),
                    "endTime": session.endTime != nil ? Timestamp(date: session.endTime!) : NSNull(),
                    "readingProgress": session.readingProgress,
                    "musicGenre": session.musicGenre ?? NSNull(),
                    "notes": session.notes ?? NSNull()
                ]
                try await db.collection("users").document(userId)
                    .collection("readingSessions").document(session.id)
                    .setData(sessionData)
                await MainActor.run {
                    self.isSyncing = false
                    self.lastSyncDate = Date()
                    self.syncError = nil
                    print("✅ Saved reading session (Firestore): \(session.bookTitle)")
                }
            } catch {
                await MainActor.run {
                    self.isSyncing = false
                    self.syncError = "Failed to save session: \(error.localizedDescription)"
                    print("❌ Failed to save reading session: \(error)")
                }
            }
        }
    }
    
    // MARK: - Save Mood Diary Entry
    
    func saveMoodDiaryEntry(_ entry: MoodDiaryEntry) async {
        isSyncing = true
        switch storageMode {
        case .local:
            var all = await loadMoodDiaryLocal()
            if let idx = all.firstIndex(where: { $0.id == entry.id }) {
                all[idx] = entry
            } else {
                all.insert(entry, at: 0)
            }
            await saveMoodDiaryLocal(all)
            await MainActor.run {
                self.moodDiaryEntries = all
                self.isSyncing = false
                self.lastSyncDate = Date()
                self.syncError = nil
                print("✅ Saved mood diary entry locally")
            }
        case .firestore:
            do {
                let entryData: [String: Any] = [
                    "id": entry.id,
                    "date": Timestamp(date: entry.date),
                    "bookTitle": entry.bookTitle,
                    "moodScore": entry.moodScore,
                    "emotions": entry.emotions,
                    "notes": entry.notes,
                    "readingProgress": entry.readingProgress,
                    "musicGenre": entry.musicGenre ?? NSNull()
                ]
                try await db.collection("users").document(userId)
                    .collection("moodDiary").document(entry.id)
                    .setData(entryData)
                await MainActor.run {
                    self.isSyncing = false
                    self.lastSyncDate = Date()
                    self.syncError = nil
                    print("✅ Saved mood diary entry (Firestore)")
                }
            } catch {
                await MainActor.run {
                    self.isSyncing = false
                    self.syncError = "Failed to save diary entry: \(error.localizedDescription)"
                    print("❌ Failed to save mood diary entry: \(error)")
                }
            }
        }
    }
    
    // MARK: - Load Reading Sessions
    
    func loadReadingSessions() async {
        isSyncing = true
        switch storageMode {
        case .local:
            let sessions = await loadReadingSessionsLocal()
            await MainActor.run {
                self.readingSessions = sessions
                self.isSyncing = false
                self.lastSyncDate = Date()
                print("✅ Loaded \(sessions.count) local reading sessions")
            }
        case .firestore:
            do {
                let snapshot = try await db.collection("users").document(userId)
                    .collection("readingSessions")
                    .order(by: "startTime", descending: true)
                    .limit(to: 50)
                    .getDocuments()
                
                let sessions = snapshot.documents.compactMap { doc -> ReadingSession? in
                    let data = doc.data()
                    guard let bookTitle = data["bookTitle"] as? String,
                          let bookAuthor = data["bookAuthor"] as? String,
                          let startTimestamp = data["startTime"] as? Timestamp else {
                        return nil
                    }
                    let endTimestamp = data["endTime"] as? Timestamp
                    let endTime = endTimestamp?.dateValue()
                    return ReadingSession(
                        id: data["id"] as? String ?? doc.documentID,
                        bookTitle: bookTitle,
                        bookAuthor: bookAuthor,
                        startTime: startTimestamp.dateValue(),
                        endTime: endTime,
                        readingProgress: data["readingProgress"] as? Double ?? 0.0,
                        musicGenre: data["musicGenre"] as? String,
                        notes: data["notes"] as? String
                    )
                }
                await MainActor.run {
                    self.readingSessions = sessions
                    self.isSyncing = false
                    self.lastSyncDate = Date()
                    print("✅ Loaded \(sessions.count) reading sessions (Firestore)")
                }
            } catch {
                await MainActor.run {
                    self.isSyncing = false
                    self.syncError = "Failed to load sessions: \(error.localizedDescription)"
                    print("❌ Failed to load reading sessions: \(error)")
                }
            }
        }
    }
    
    // MARK: - Load Mood Diary Entries
    
    func loadMoodDiaryEntries() async {
        isSyncing = true
        switch storageMode {
        case .local:
            let entries = await loadMoodDiaryLocal()
            await MainActor.run {
                self.moodDiaryEntries = entries
                self.isSyncing = false
                self.lastSyncDate = Date()
                print("✅ Loaded \(entries.count) local mood diary entries")
            }
        case .firestore:
            do {
                let snapshot = try await db.collection("users").document(userId)
                    .collection("moodDiary")
                    .order(by: "date", descending: true)
                    .limit(to: 100)
                    .getDocuments()
                let entries = snapshot.documents.compactMap { doc -> MoodDiaryEntry? in
                    let data = doc.data()
                    guard let dateTimestamp = data["date"] as? Timestamp,
                          let bookTitle = data["bookTitle"] as? String,
                          let moodScore = data["moodScore"] as? Int,
                          let emotions = data["emotions"] as? [String],
                          let notes = data["notes"] as? String else {
                        return nil
                    }
                    return MoodDiaryEntry(
                        id: data["id"] as? String ?? doc.documentID,
                        date: dateTimestamp.dateValue(),
                        bookTitle: bookTitle,
                        moodScore: moodScore,
                        emotions: emotions,
                        notes: notes,
                        readingProgress: data["readingProgress"] as? Double ?? 0.0,
                        musicGenre: data["musicGenre"] as? String
                    )
                }
                await MainActor.run {
                    self.moodDiaryEntries = entries
                    self.isSyncing = false
                    self.lastSyncDate = Date()
                    print("✅ Loaded \(entries.count) mood diary entries (Firestore)")
                }
            } catch {
                await MainActor.run {
                    self.isSyncing = false
                    self.syncError = "Failed to load diary entries: \(error.localizedDescription)"
                    print("❌ Failed to load mood diary entries: \(error)")
                }
            }
        }
    }
    
    // MARK: - Sync All Data
    
    func syncAllData() async {
        print("🔄 Starting full sync...")
        await loadReadingSessions()
        await loadMoodDiaryEntries()
        print("✅ Full sync completed")
    }
    
    // MARK: - Delete Reading Session
    
    func deleteReadingSession(_ session: ReadingSession) async {
        switch storageMode {
        case .local:
            var all = await loadReadingSessionsLocal()
            all.removeAll { $0.id == session.id }
            await saveReadingSessionsLocal(all)
            await MainActor.run {
                self.readingSessions = all
                print("✅ Deleted local reading session")
            }
        case .firestore:
            do {
                try await db.collection("users").document(userId)
                    .collection("readingSessions").document(session.id)
                    .delete()
                await MainActor.run {
                    self.readingSessions.removeAll { $0.id == session.id }
                    print("✅ Deleted reading session (Firestore)")
                }
            } catch {
                await MainActor.run {
                    self.syncError = "Failed to delete session: \(error.localizedDescription)"
                    print("❌ Failed to delete reading session: \(error)")
                }
            }
        }
    }
    
    // MARK: - Delete Mood Diary Entry
    
    func deleteMoodDiaryEntry(_ entry: MoodDiaryEntry) async {
        switch storageMode {
        case .local:
            var all = await loadMoodDiaryLocal()
            all.removeAll { $0.id == entry.id }
            await saveMoodDiaryLocal(all)
            await MainActor.run {
                self.moodDiaryEntries = all
                print("✅ Deleted local mood diary entry")
            }
        case .firestore:
            do {
                try await db.collection("users").document(userId)
                    .collection("moodDiary").document(entry.id)
                    .delete()
                await MainActor.run {
                    self.moodDiaryEntries.removeAll { $0.id == entry.id }
                    print("✅ Deleted mood diary entry (Firestore)")
                }
            } catch {
                await MainActor.run {
                    self.syncError = "Failed to delete entry: \(error.localizedDescription)"
                    print("❌ Failed to delete mood diary entry: \(error)")
                }
            }
        }
    }

    // MARK: - Local storage helpers
    private func saveReadingSessionsLocal(_ sessions: [ReadingSession]) async {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: readingSessionsKey)
        } catch {
            print("⚠️ Failed to save local reading sessions: \(error)")
        }
    }
    
    private func loadReadingSessionsLocal() async -> [ReadingSession] {
        guard let data = UserDefaults.standard.data(forKey: readingSessionsKey) else { return [] }
        do {
            return try JSONDecoder().decode([ReadingSession].self, from: data)
        } catch {
            print("⚠️ Failed to load local reading sessions: \(error)")
            return []
        }
    }
    
    private func saveMoodDiaryLocal(_ entries: [MoodDiaryEntry]) async {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: moodDiaryKey)
        } catch {
            print("⚠️ Failed to save local mood diary entries: \(error)")
        }
    }
    
    private func loadMoodDiaryLocal() async -> [MoodDiaryEntry] {
        guard let data = UserDefaults.standard.data(forKey: moodDiaryKey) else { return [] }
        do {
            return try JSONDecoder().decode([MoodDiaryEntry].self, from: data)
        } catch {
            print("⚠️ Failed to load local mood diary entries: \(error)")
            return []
        }
    }
}

