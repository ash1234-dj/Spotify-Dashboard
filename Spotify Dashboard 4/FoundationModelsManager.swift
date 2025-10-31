//
//  FoundationModelsManager.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Book Recommendation Engine using Apple Foundation Models

@MainActor
class FoundationModelsManager: ObservableObject {
    @Published var isGenerating = false
    @Published var recommendations: [BookRecommendation] = []
    @Published var currentStreamingText = ""
    
    // MARK: - Generate Author Life Lessons
    
    func generateAuthorLifeLessons(for author: AuthorSearchResult, withSummary summary: String? = nil) async -> String {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return await generateLifeLessonsWithFoundationModels(for: author, withSummary: summary)
        } else {
            return generateBasicLifeLessons(for: author, withSummary: summary)
        }
        #else
        return generateBasicLifeLessons(for: author, withSummary: summary)
        #endif
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func generateLifeLessonsWithFoundationModels(for author: AuthorSearchResult, withSummary summary: String? = nil) async -> String {
        do {
            let session = LanguageModelSession()
            
            let prompt = """
            Analyze the life and work of \(author.name) and provide practical life lessons that can be applied to modern life.
            
            Author Information:
            - Name: \(author.name)
            - Birth Date: \(author.birthDate ?? "Unknown")
            - Death Date: \(author.deathDate ?? "Unknown")
            - Famous Work: \(author.topWork ?? "Various works")
            - Number of Works: \(author.workCount ?? 0)
            - Top Subjects: \(author.topSubjects?.joined(separator: ", ") ?? "Literature")
            
            \(summary != nil ? "\nDetailed Information:\n\(summary!)" : "")
            
            Please provide:
            1. Key life lessons from their personal journey
            2. Writing and creativity insights
            3. How to apply their wisdom to modern challenges
            4. What we can learn from their struggles and successes
            5. Practical advice for personal growth
            
            Format as clear, actionable insights that anyone can apply to their daily life.
            Keep it inspiring and practical, around 4-5  paragraphs.
            """
            
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 0.7,
                    maximumResponseTokens: nil
                )
            )
            
            return response.content
            
        } catch {
            print("❌ Foundation Models error: \(error)")
            return generateBasicLifeLessons(for: author, withSummary: summary)
        }
    }
    #endif
    
    private func generateBasicLifeLessons(for author: AuthorSearchResult, withSummary summary: String? = nil) -> String {
        let authorName = author.name
        let workCount = author.workCount ?? 0
        let topWork = author.topWork ?? "their works"
        let birthDate = author.birthDate ?? "Unknown"
        let deathDate = author.deathDate ?? "Unknown"
        let subjects = author.topSubjects?.joined(separator: ", ") ?? "Literature"
        
        var lessons = """
        🌟 Life Lessons from \(authorName)
        
        \(authorName) (\(birthDate) - \(deathDate)) was a prolific writer with \(workCount) works, most famously known for "\(topWork)". Their expertise in \(subjects) offers timeless wisdom for modern life:
        
        **📚 1. The Power of Storytelling**
        \(authorName) mastered the art of storytelling, creating narratives that resonate across generations. 
        💡 **Apply to Your Life**: Share your experiences through stories. Whether in conversations, presentations, or social media, compelling stories help you connect with others and make your message memorable.
        
        **🎯 2. Persistence Through Challenges**
        Despite personal and professional obstacles, \(authorName) continued creating meaningful work.
        💡 **Apply to Your Life**: When facing setbacks, remember that consistent effort over time leads to mastery. Break large goals into smaller, manageable steps and celebrate small victories.
        
        **👥 3. Deep Human Understanding**
        \(authorName)'s works demonstrate profound insight into human nature, emotions, and relationships.
        💡 **Apply to Your Life**: Practice active listening and empathy. Try to understand others' perspectives before judging. This builds stronger relationships and helps you navigate social situations more effectively.
        
        **🔄 4. Learning from Experience**
        \(authorName) transformed personal struggles and observations into universal themes that still speak to readers today.
        💡 **Apply to Your Life**: Keep a journal to reflect on your experiences. Look for patterns in your life and extract lessons from both successes and failures.
        
        **🌱 5. Continuous Growth**
        The breadth and depth of \(authorName)'s work shows a commitment to lifelong learning and self-improvement.
        💡 **Apply to Your Life**: Dedicate time each week to learning something new. Read books, take courses, or explore new hobbies. Growth mindset leads to personal fulfillment.
        
        **📝 6. Discipline in Creation**
        Producing \(workCount) works requires incredible discipline and daily practice.
        💡 **Apply to Your Life**: Establish daily routines for your most important activities. Whether it's writing, exercising, or learning, consistency beats intensity every time.
        """
        
        // Add detailed insights if summary is available
        if let summary = summary, !summary.isEmpty {
            lessons += "\n\n**🔍 Deeper Insights from Their Life:**\n"
            
            // Extract key information from summary
            if summary.contains("Biography:") {
                let bioStart = summary.range(of: "Biography:")?.upperBound ?? summary.startIndex
                let bioEnd = summary.range(of: "\nComplete Works List:")?.lowerBound ?? summary.endIndex
                let biography = String(summary[bioStart..<bioEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !biography.isEmpty {
                    lessons += "\n**Personal Journey**: \(biography.prefix(300))...\n"
                }
            }
            
            if summary.contains("Complete Works List:") {
                lessons += "\n**Creative Legacy**: Their extensive body of work shows the power of sustained creative effort. Each piece contributed to their lasting impact on literature and culture.\n"
            }
            
            lessons += "\n**💭 Reflection Questions**:\n"
            lessons += "• What challenges in \(authorName)'s life can you relate to?\n"
            lessons += "• How can you apply their creative discipline to your own goals?\n"
            lessons += "• What stories from your life could inspire others?\n"
            lessons += "• How can you develop deeper empathy like \(authorName) demonstrated?\n"
        }
        
        lessons += "\n\n**🚀 Action Steps**:\n"
        lessons += "1. Start a daily writing or creative practice\n"
        lessons += "2. Read one of \(authorName)'s works this month\n"
        lessons += "3. Practice storytelling in your next conversation\n"
        lessons += "4. Reflect on a recent challenge and extract a lesson\n"
        lessons += "5. Share your insights with someone who might benefit\n"
        
        return lessons
    }
    
    // MARK: - Generate Book Recommendations
    
    func generateRecommendations(basedOn entries: [MoodEntry], availableBooks: [GutendexBook]) async {
        isGenerating = true
        currentStreamingText = ""
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            await generateWithFoundationModels(entries: entries, availableBooks: availableBooks)
        } else {
            await generateWithBasicLogic(entries: entries, availableBooks: availableBooks)
        }
        #else
        await generateWithBasicLogic(entries: entries, availableBooks: availableBooks)
        #endif
        
        isGenerating = false
    }
    
    // MARK: - Foundation Models Implementation
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func generateWithFoundationModels(entries: [MoodEntry], availableBooks: [GutendexBook]) async {
        do {
            // Create a Language Model Session
            let session = LanguageModelSession()
            
            // Build comprehensive prompt for book recommendations
            let avgMood = entries.map { Double($0.moodScore) }.reduce(0, +) / Double(entries.count)
            let allEmotions = entries.flatMap { $0.emotions }
            let frequentEmotions = Array(Set(allEmotions)).prefix(5)
            
            let bookList = availableBooks.prefix(20).map { "- \($0.title) by \($0.primaryAuthor)" }.joined(separator: "\n")
            
            let prompt = """
            You are a book recommendation assistant for a reading app.
            
            User Reading Profile:
            - Average mood score: \(String(format: "%.1f", avgMood))/10
            - Frequently experienced emotions: \(frequentEmotions.joined(separator: ", "))
            - Number of reading sessions: \(entries.count)
            
            Available Books:
            \(bookList)
            
            Provide 3 book recommendations that match their mood and reading preferences.
            For each book, include the title, author, why it's recommended, and how it matches their mood.
            Be specific and encouraging.
            """
            
            // Get AI response using correct API
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 1,
                    maximumResponseTokens: nil
                )
            )
            
            // Parse and create recommendations
            let recommendations = parseRecommendations(from: response.content, availableBooks: availableBooks)
            
            await MainActor.run {
                self.recommendations = recommendations
            }
            
            print("✅ Generated \(recommendations.count) book recommendations using Foundation Models")
            
        } catch {
            print("❌ Foundation Models error: \(error)")
            
            // Handle specific generation errors
            if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
                print("Generation error: \(error.localizedDescription)")
            }
            
            await generateWithBasicLogic(entries: entries, availableBooks: availableBooks)
        }
    }
    
    private func parseRecommendations(from text: String, availableBooks: [GutendexBook]) -> [BookRecommendation] {
        var recommendations: [BookRecommendation] = []
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            for book in availableBooks.prefix(10) {
                if line.lowercased().contains(book.title.lowercased()) && recommendations.count < 3 {
                    let reason = extractReason(from: text, for: book.title)
                    let moodMatch = extractMoodMatch(from: text)
                    
                    recommendations.append(BookRecommendation(
                        title: book.title,
                        author: book.primaryAuthor,
                        reason: reason,
                        moodMatch: moodMatch
                    ))
                    break
                }
            }
        }
        
        return recommendations.isEmpty ? [] : recommendations
    }
    
    private func extractReason(from text: String, for bookTitle: String) -> String {
        let lowerText = text.lowercased()
        let lowerTitle = bookTitle.lowercased()
        
        if let titleIndex = lowerText.range(of: lowerTitle) {
            let afterTitle = String(text[titleIndex.upperBound...])
            let sentences = afterTitle.components(separatedBy: ".").prefix(2)
            return sentences.joined(separator: ".").trimmingCharacters(in: .whitespaces)
        }
        
        return "This book matches your reading style perfectly!"
    }
    
    private func extractMoodMatch(from text: String) -> String {
        let lowerText = text.lowercased()
        if lowerText.contains("uplifting") || lowerText.contains("positive") {
            return "Uplifting & Positive"
        } else if lowerText.contains("calm") || lowerText.contains("peaceful") {
            return "Calm & Peaceful"
        } else if lowerText.contains("inspirational") || lowerText.contains("motivational") {
            return "Inspiring & Motivational"
        }
        return "Perfect Match"
    }
    #endif
    
    // MARK: - Basic Logic Fallback
    
    private func generateWithBasicLogic(entries: [MoodEntry], availableBooks: [GutendexBook]) async {
        // Simple recommendation based on mood score
        let avgMood = entries.map { Double($0.moodScore) }.reduce(0, +) / Double(entries.count)
        
        var recommendations: [BookRecommendation] = []
        
        // Filter books based on mood
        let matchingBooks = availableBooks.prefix(10)
        
        for (index, book) in matchingBooks.enumerated() {
            let reason: String
            let moodMatch: String
            
            if avgMood >= 7 {
                reason = "You're enjoying your reading journey! This classic story will continue inspiring you."
                moodMatch = "Positive & Inspiring"
            } else if avgMood <= 4 {
                reason = "A lighter read to boost your mood and bring joy to your reading routine."
                moodMatch = "Uplifting & Light"
            } else {
                reason = "A well-balanced story that matches your current reading pace."
                moodMatch = "Balanced & Engaging"
            }
            
            recommendations.append(BookRecommendation(
                title: book.title,
                author: book.primaryAuthor,
                reason: reason,
                moodMatch: moodMatch
            ))
            
            if recommendations.count >= 3 {
                break
            }
        }
        
        self.recommendations = recommendations
        print("✅ Generated \(recommendations.count) book recommendations using basic logic")
    }
    
    // MARK: - Generate Reading Summary
    
    func generateReadingSummary(for entry: MoodEntry) async -> String {
        isGenerating = true
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return await generateSummaryWithFoundationModels(entry: entry)
        } else {
            return await generateSummaryWithBasicLogic(entry: entry)
        }
        #else
        return await generateSummaryWithBasicLogic(entry: entry)
        #endif
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func generateSummaryWithFoundationModels(entry: MoodEntry) async -> String {
        do {
            // Create a Language Model Session
            let session = LanguageModelSession()
            
            let prompt = """
            Write a brief, encouraging summary of this reading session:
            
            Book: \(entry.bookTitle)
            Mood: \(entry.moodScore)/10
            Emotions: \(entry.emotions.joined(separator: ", "))
            Progress: \(Int(entry.readingProgress * 100))%
            
            Notes: \(entry.notes)
            
            Write 2-3 sentences that celebrate their reading progress and encourage them to continue.
            Be warm, personal, and motivational.
            """
            
            // Get AI response using correct API
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 1,
                    maximumResponseTokens: nil
                )
            )
            
            isGenerating = false
            return response.content
            
        } catch {
            print("❌ Summary generation error: \(error)")
            
            // Handle specific generation errors
            if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
                print("Generation error: \(error.localizedDescription)")
            }
            
            isGenerating = false
            return await generateSummaryWithBasicLogic(entry: entry)
        }
    }
    #endif
    
    private func generateSummaryWithBasicLogic(entry: MoodEntry) async -> String {
        isGenerating = false
        
        let moodEmoji = entry.emoji
        let progress = Int(entry.readingProgress * 100)
        
        var summary = "\(moodEmoji) Great reading session on \(entry.bookTitle)!\n\n"
        
        if progress >= 50 {
            summary += "You're making excellent progress - over halfway through!"
        } else if progress >= 25 {
            summary += "You're building momentum in your reading journey."
        } else {
            summary += "A solid start to your reading adventure."
        }
        
        summary += "\n\nKeep up the wonderful work!"
        
        return summary
    }
    
    // MARK: - Generate Detailed AI Summary
    
    func generateDetailedSummary(for entry: MoodEntry) async -> String {
        isGenerating = true
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return await generateDetailedSummaryWithFoundationModels(entry: entry)
        } else {
            return await generateDetailedSummaryWithBasicLogic(entry: entry)
        }
        #else
        return await generateDetailedSummaryWithBasicLogic(entry: entry)
        #endif
    }
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func generateDetailedSummaryWithFoundationModels(entry: MoodEntry) async -> String {
        do {
            let session = LanguageModelSession()
            
            let prompt = """
            Analyze this mood diary entry for reading and provide:
            
            1. A brief summary of their reading experience
            2. Insights about their emotional state
            3. 2-3 specific suggestions for improvement
            
            Entry Details:
            - Book: \(entry.bookTitle)
            - Mood Score: \(entry.moodScore)/10
            - Emotions: \(entry.emotions.joined(separator: ", "))
            - Progress: \(Int(entry.readingProgress * 100))%
            - Notes: \(entry.notes.isEmpty ? "No notes" : entry.notes)
            
            Be encouraging, specific, and practical in your recommendations.
            """
            
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 1,
                    maximumResponseTokens: nil
                )
            )
            
            isGenerating = false
            return response.content
            
        } catch {
            print("❌ Detailed summary error: \(error)")
            if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
                print("Generation error: \(error.localizedDescription)")
            }
            isGenerating = false
            return await generateDetailedSummaryWithBasicLogic(entry: entry)
        }
    }
    #endif
    
    private func generateDetailedSummaryWithBasicLogic(entry: MoodEntry) async -> String {
        isGenerating = false
        
        var summary = "📖 Reading Session Summary\n\n"
        
        // Summary
        summary += "You read \(entry.bookTitle) and experienced a mood score of \(entry.moodScore)/10. "
        summary += "Key emotions during this session: \(entry.emotions.joined(separator: ", ")).\n\n"
        
        // Insights
        summary += "💡 Insights:\n"
        if entry.moodScore >= 7 {
            summary += "• You had a very positive reading experience!\n"
        } else if entry.moodScore <= 4 {
            summary += "• Consider trying different reading environments or genres.\n"
        } else {
            summary += "• Your reading session was balanced and enjoyable.\n"
        }
        
        if entry.emotions.contains("Relaxed") || entry.emotions.contains("Calm") {
            summary += "• You achieved a relaxed reading state, great for comprehension.\n"
        }
        
        // Suggestions
        summary += "\n📚 Suggestions for Improvement:\n"
        summary += "• Try to maintain consistent reading times for better habit formation.\n"
        summary += "• Explore books in genres that match your current emotional state.\n"
        summary += "• Keep tracking your mood to identify patterns over time.\n"
        
        return summary
    }
}

// MARK: - Book Recommendation Model

struct BookRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let reason: String
    let moodMatch: String
}

