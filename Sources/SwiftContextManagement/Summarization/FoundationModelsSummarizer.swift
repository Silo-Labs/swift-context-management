import Foundation
import FoundationModels

/// Errors that can occur during FoundationModels summarization.
public enum FoundationModelsSummarizerError: Error {
    case missingInstructionsForSpecifiedLocale
    case cannotSummarizeEmptyEntries
}

/// A default summarizer implementation using FoundationModels.
public struct FoundationModelsSummarizer: Summarizer {
    private static let defaultSummarizationInstructions = """
    Summarize the following conversation briefly, preserving only essential facts and decisions. Remove examples, repetition, and implementation details. Provide only the summary content directly without any introductory phrases, explanations, or meta-commentary. Start immediately with the summary.
    """

    /// Creates a FoundationModels summarizer.
    public init() {}

    /// Summarizes a conversation using FoundationModels.
    ///
    /// Uses a reactive approach: tries to summarize directly, and if the context window
    /// is exceeded, automatically splits the entries and retries recursively.
    ///
    /// - Parameters:
    ///   - entries: The conversation entries to summarize.
    ///   - instructions: Optional instructions for the summarization. Must be provided if the locale is not English.
    ///   - locale: The locale to use for the summarization.
    /// - Returns: A summary of the conversation.
    /// - Throws: An error if the summarization fails.
    public func summarize(
        entries: [Transcript.Entry],
        instructions: String?,
        locale: Locale = .enUS
    ) async throws -> String {
        guard !entries.isEmpty else {
            throw FoundationModelsSummarizerError.cannotSummarizeEmptyEntries
        }
        
        if locale.identifier != Locale.enUS.identifier, instructions == nil {
            throw FoundationModelsSummarizerError.missingInstructionsForSpecifiedLocale
        }

        let summarizationPrompt = instructions ?? Self.defaultSummarizationInstructions
        return try await summarizeWithRetry(entries: entries, instructions: summarizationPrompt)
    }
}

private extension FoundationModelsSummarizer {
    /// Attempts to summarize entries, automatically splitting if context window is exceeded.
    ///
    /// - Parameters:
    ///   - entries: The entries to summarize.
    ///   - instructions: The summarization instructions.
    /// - Returns: A summary string.
    func summarizeWithRetry(
        entries: [Transcript.Entry],
        instructions: String
    ) async throws -> String {
        do {
            // Try to summarize directly
            return try await summarizeDirectly(entries: entries, instructions: instructions)
        } catch let error as LanguageModelSession.GenerationError {
            // Check if it's a context window error
            if case .exceededContextWindowSize = error {
                // Split and retry
                return try await summarizeInParts(entries: entries, instructions: instructions)
            }
            throw error
        }
    }
    
    /// Summarizes entries directly in a single LLM call.
    func summarizeDirectly(
        entries: [Transcript.Entry],
        instructions: String
    ) async throws -> String {
        let conversationText = entries
            .compactMap { TranscriptHelpers.extractText(from: $0) }
            .joined(separator: "\n\n")

        let prompt = """
        \(instructions)
        
        Conversation to summarize:
        \(conversationText)
        
        Provide the summary now (no introductory phrases):
        """
        
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt)
        return response.content
    }
    
    /// Splits entries into parts, summarizes each part, then combines the summaries.
    func summarizeInParts(
        entries: [Transcript.Entry],
        instructions: String
    ) async throws -> String {
        // Split entries in half
        let midpoint = entries.count / 2
        guard midpoint > 0 else {
            // Only one entry but still too large - summarize the text directly
            return try await summarizeLargeEntry(entries[0], instructions: instructions)
        }
        
        let firstHalf = Array(entries[0..<midpoint])
        let secondHalf = Array(entries[midpoint...])
        
        // Recursively summarize each half (will split further if needed)
        let firstSummary = try await summarizeWithRetry(entries: firstHalf, instructions: instructions)
        let secondSummary = try await summarizeWithRetry(entries: secondHalf, instructions: instructions)
        
        // Combine the two summaries
        return try await combineSummaries([firstSummary, secondSummary])
    }
    
    /// Handles the edge case of a single entry that's too large for the context window.
    func summarizeLargeEntry(
        _ entry: Transcript.Entry,
        instructions: String
    ) async throws -> String {
        guard let text = TranscriptHelpers.extractText(from: entry) else {
            return ""
        }
        
        // Split the text itself in half and summarize each part
        let midpoint = text.count / 2
        let splitIndex = text.index(text.startIndex, offsetBy: midpoint)
        
        let firstHalf = String(text[..<splitIndex])
        let secondHalf = String(text[splitIndex...])
        
        let firstSummary = try await summarizeText(firstHalf, instructions: instructions)
        let secondSummary = try await summarizeText(secondHalf, instructions: instructions)
        
        return try await combineSummaries([firstSummary, secondSummary])
    }
    
    /// Summarizes raw text with retry on context window errors.
    func summarizeText(
        _ text: String,
        instructions: String
    ) async throws -> String {
        let prompt = """
        \(instructions)
        
        Text to summarize:
        \(text)
        
        Provide the summary now (no introductory phrases):
        """
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                // Text still too large, split it further
                let midpoint = text.count / 2
                guard midpoint > 100 else {
                    // Text is very small but still failing - just truncate
                    return String(text.prefix(500)) + "..."
                }
                
                let splitIndex = text.index(text.startIndex, offsetBy: midpoint)
                let firstHalf = String(text[..<splitIndex])
                let secondHalf = String(text[splitIndex...])
                
                let firstSummary = try await summarizeText(firstHalf, instructions: instructions)
                let secondSummary = try await summarizeText(secondHalf, instructions: instructions)
                
                return try await combineSummaries([firstSummary, secondSummary])
            }
            throw error
        }
    }
    
    /// Combines multiple summaries into one coherent summary.
    func combineSummaries(_ summaries: [String]) async throws -> String {
        let combinedText = summaries.enumerated()
            .map { "Part \($0.offset + 1):\n\($0.element)" }
            .joined(separator: "\n\n")
        
        let prompt = """
        Combine and synthesize the following summaries into a single coherent summary. Preserve all important information and maintain chronological flow. Provide only the combined summary content directly without any introductory phrases.
        
        Summaries to combine:
        \(combinedText)
        
        Combined summary (no introductory phrases):
        """
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                // Too many summaries to combine at once - split them
                let midpoint = summaries.count / 2
                guard midpoint > 0 else {
                    // Only one summary but still too large - just return it
                    return summaries[0]
                }
                
                let firstGroup = Array(summaries[0..<midpoint])
                let secondGroup = Array(summaries[midpoint...])
                
                let firstCombined = try await combineSummaries(firstGroup)
                let secondCombined = try await combineSummaries(secondGroup)
                
                return try await combineSummaries([firstCombined, secondCombined])
            }
            throw error
        }
    }
}
