import Foundation
import FoundationModels

/// A protocol for summarizing conversation history.
/// Implementations can use different models or strategies for summarization.
public protocol Summarizer: Sendable {
    /// Summarizes a collection of conversation entries.
    ///
    /// - Parameters:
    ///   - entries: The conversation entries to summarize.
    ///   - instructions: Optional system instructions to guide the summarization.
    ///   - language: The language code for the summary (e.g., "eng", "fra").
    /// - Returns: A summary string of the conversation entries.
    /// - Throws: An error if summarization fails.
    func summarize(
        entries: [Transcript.Entry],
        instructions: String?,
        locale: Locale
    ) async throws -> String
}
