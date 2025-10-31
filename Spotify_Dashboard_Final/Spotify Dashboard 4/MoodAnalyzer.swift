//
//  MoodAnalyzer.swift
//  Music Story Companion
//
//  Created by Ashfaq ahmed on 10/08/25.
//

import Foundation
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - AI Mood Insights Generator with Apple Foundation Models

class AIMoodInsightsGenerator: ObservableObject {
    @Published var isAnalyzing = false
    @Published var latestInsight: AIInsight?
    @Published var isFoundationModelsAvailable = false
    
    init() {
        checkFoundationModelsAvailability()
    }
    
    // MARK: - Foundation Models Availability Check
    
    private func checkFoundationModelsAvailability() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            // Check actual model availability
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                isFoundationModelsAvailable = true
                print("✅ Apple Foundation Models available")
            case .unavailable(.modelNotReady):
                isFoundationModelsAvailable = false
                print("⏳ Foundation Models downloading...")
            case .unavailable(.appleIntelligenceNotEnabled):
                isFoundationModelsAvailable = false
                print("⚠️ Please enable Apple Intelligence in Settings")
            case .unavailable(.deviceNotEligible):
                isFoundationModelsAvailable = false
                print("❌ Device not eligible for Foundation Models")
            case .unavailable(let other):
                isFoundationModelsAvailable = false
                print("❓ Unknown error: \(other)")
            }
        } else {
            isFoundationModelsAvailable = false
            print("⚠️ Foundation Models requires iOS 26+")
        }
        #else
        isFoundationModelsAvailable = false
        print("ℹ️ Using enhanced pattern analysis")
        #endif
    }
    
    // MARK: - Generate Insights
    
    func generateInsights(from entries: [MoodEntry]) async {
        guard !entries.isEmpty else { return }
        
        await MainActor.run {
            isAnalyzing = true
        }
        
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *), isFoundationModelsAvailable {
            await analyzeWithFoundationModels(entries: entries)
        } else {
            await analyzeWithBasicLogic(entries: entries)
        }
        #else
        await analyzeWithBasicLogic(entries: entries)
        #endif
        
        await MainActor.run {
            isAnalyzing = false
        }
    }
    
    // MARK: - Foundation Models Analysis
    
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    private func analyzeWithFoundationModels(entries: [MoodEntry]) async {
        do {
            // Create a Language Model Session
            let session = LanguageModelSession()
            
            // Build comprehensive prompt
            let avgMood = entries.map { Double($0.moodScore) }.reduce(0, +) / Double(entries.count)
            let allEmotions = entries.flatMap { $0.emotions }
            let frequentEmotions = getFrequentEmotions(allEmotions)
            
            let recentBooks = entries.prefix(3).map { $0.bookTitle }.joined(separator: ", ")
            
            let prompt = """
            Analyze these reading mood diary entries and provide insights:
            
            Reading Statistics:
            - Total reading sessions: \(entries.count)
            - Average mood score: \(String(format: "%.1f", avgMood))/10
            - Most common emotions: \(frequentEmotions.joined(separator: ", "))
            - Recent books: \(recentBooks)
            
            Recent Entries:
            \(entries.prefix(3).map { entry in
                "- Book: \(entry.bookTitle), Mood: \(entry.moodScore)/10, Emotions: \(entry.emotions.joined(separator: ", ")), Progress: \(Int(entry.readingProgress * 100))%"
            }.joined(separator: "\n"))
            
            Please provide:
            1. 2-3 key insights about their reading experience
            2. 2-3 patterns you've detected in their mood
            3. 2-3 personalized recommendations
            4. Overall trend (improving, stable, or declining)
            
            Be encouraging, empathetic, and specific in your analysis.
            """
            
            // Get AI response using correct API
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(
                    temperature: 1,
                    maximumResponseTokens: nil
                )
            )
            
            // Parse response and create insights
            let responseText = response.content
            
            // Extract insights from AI response
            let insights = extractInsights(from: responseText)
            let patterns = extractPatterns(from: responseText)
            let recommendations = extractRecommendations(from: responseText)
            let trend = extractTrend(from: responseText, avgMood: avgMood)
            
            await MainActor.run {
                latestInsight = AIInsight(
                    id: UUID(),
                    date: Date(),
                    insights: insights,
                    patterns: patterns,
                    recommendations: recommendations,
                    trend: trend
                )
            }
            
            print("✅ Generated insights using Apple Foundation Models")
            
        } catch {
            print("❌ Foundation Models error: \(error)")
            
            // Handle specific generation errors
            if let error = error as? FoundationModels.LanguageModelSession.GenerationError {
                print("Generation error: \(error.localizedDescription)")
            }
            
            // Fallback to basic analysis
            await analyzeWithBasicLogic(entries: entries)
        }
    }
    
    // Helper functions to parse AI response
    private func extractInsights(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var insights: [String] = []
        var inInsights = false
        
        for line in lines {
            if line.lowercased().contains("insight") || line.contains("1.") {
                inInsights = true
            }
            if inInsights && (line.contains("-") || line.contains("•")) {
                let cleaned = line.replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "•", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty && !cleaned.contains("2.") && !cleaned.contains("3.") {
                    insights.append(cleaned)
                }
            }
            if insights.count >= 3 { break }
        }
        
        return insights.isEmpty ? ["You're building a great reading habit!"] : insights
    }
    
    private func extractPatterns(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var patterns: [String] = []
        var inPatterns = false
        
        for line in lines {
            if line.lowercased().contains("pattern") || line.contains("2.") {
                inPatterns = true
            }
            if inPatterns && (line.contains("-") || line.contains("•")) {
                let cleaned = line.replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "•", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty && !cleaned.contains("3.") {
                    patterns.append(cleaned)
                }
            }
            if patterns.count >= 3 { break }
        }
        
        return patterns
    }
    
    private func extractRecommendations(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var recommendations: [String] = []
        var inRecommendations = false
        
        for line in lines {
            if line.lowercased().contains("recommendation") || line.contains("3.") {
                inRecommendations = true
            }
            if inRecommendations && (line.contains("-") || line.contains("•")) {
                let cleaned = line.replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "•", with: "")
                    .trimmingCharacters(in: .whitespaces)
                if !cleaned.isEmpty {
                    recommendations.append(cleaned)
                }
            }
            if recommendations.count >= 3 { break }
        }
        
        return recommendations
    }
    
    private func extractTrend(from text: String, avgMood: Double) -> AIInsight.MoodTrend {
        let lowerText = text.lowercased()
        if lowerText.contains("improving") || lowerText.contains("trending up") || lowerText.contains("getting better") {
            return .improving
        } else if lowerText.contains("declining") || lowerText.contains("trending down") || lowerText.contains("getting worse") {
            return .declining
        } else {
            return avgMood > 6 ? .improving : avgMood < 4 ? .declining : .stable
        }
    }
    #endif
    
    // MARK: - Enhanced Analysis (Current Implementation)
    
    private func analyzeWithEnhancedLogic(entries: [MoodEntry]) async {
        await analyzeWithBasicLogic(entries: entries)
    }
    
    private func analyzeWithBasicLogic(entries: [MoodEntry]) async {
        // Basic pattern analysis (fallback)
        let recentEntries = entries.prefix(5)
        let avgMood = recentEntries.map { Double($0.moodScore) }.reduce(0, +) / Double(recentEntries.count)
        
        var insights: [String] = []
        var patterns: [String] = []
        var recommendations: [String] = []
        
        // Mood trend analysis
        if entries.count >= 2 {
            let recent = entries.prefix(2).map { $0.moodScore }
            let earlier = entries.suffix(2).map { $0.moodScore }
            
            let recentAvg = recent.reduce(0, +) / recent.count
            let earlierAvg = earlier.reduce(0, +) / earlier.count
            
            if recentAvg > earlierAvg {
                patterns.append("Your mood is improving over time")
            } else if recentAvg < earlierAvg {
                patterns.append("Your mood has been declining recently")
            } else {
                patterns.append("Your mood has been relatively stable")
            }
        }
        
        // Genre preferences
        let preferredGenres = entries.compactMap { $0.musicGenre }
        if let mostCommon = mostFrequent(in: preferredGenres) {
            patterns.append("You prefer \(mostCommon) music while reading")
        }
        
        // Emotion patterns
        let allEmotions = entries.flatMap { $0.emotions }
        let emotionCounts = Dictionary(grouping: allEmotions, by: { $0 }).mapValues { $0.count }
        let sortedEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        if !sortedEmotions.isEmpty {
            insights.append("You frequently experience: \(sortedEmotions.joined(separator: ", "))")
        }
        
        // Add additional insights based on reading patterns
        if avgMood >= 7 {
            insights.append("You're consistently enjoying your reading sessions!")
        } else if avgMood <= 4 {
            insights.append("Consider exploring different genres or reading environments")
        }
        
        // Recommendations
        if avgMood < 5 {
            recommendations.append("Try reading lighter content or music to boost your mood")
        } else if avgMood > 7 {
            recommendations.append("You're enjoying your reading experience! Keep it up!")
        } else {
            recommendations.append("Your reading routine is good! Try mixing up genres for variety")
        }
        
        // Add genre-specific recommendations
        if let mostCommon = mostFrequent(in: preferredGenres) {
            recommendations.append("Continue exploring \(mostCommon) music - it seems to work well for you")
        }
        
        let trend: AIInsight.MoodTrend = avgMood > 6 ? .improving : avgMood < 4 ? .declining : .stable
        
        await MainActor.run {
            latestInsight = AIInsight(
                id: UUID(),
                date: Date(),
                insights: insights,
                patterns: patterns,
                recommendations: recommendations,
                trend: trend
            )
        }
        
        print("✅ Generated insights using basic pattern analysis")
    }
    
    // MARK: - Helper Functions
    
    private func getFrequentEmotions(_ emotions: [String]) -> [String] {
        let counts = Dictionary(grouping: emotions, by: { $0 }).mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    private func mostFrequent<T: Hashable>(in array: [T]) -> T? {
        let counts = Dictionary(grouping: array, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

