import Foundation
import FoundationModels

/// A summarizer implementation that uses a custom LLM function.
/// This allows users to provide their own summarization logic.
public struct CustomLLMSummarizer: Summarizer {
    private let summarizeFunction: @Sendable ([Transcript.Entry], String?, Locale) async throws -> String

    /// Creates a custom LLM summarizer with a user-provided summarization function.
    ///
    /// - Parameter summarizeFunction: An async function that takes conversation entries, optional instructions, and locale, and returns a summary string.
    public init(
        summarizeFunction: @escaping @Sendable ([Transcript.Entry], String?, Locale) async throws -> String
    ) {
        self.summarizeFunction = summarizeFunction
    }

    public func summarize(
        entries: [Transcript.Entry],
        instructions: String?,
        locale: Locale
    ) async throws -> String {
        return try await summarizeFunction(entries, instructions, locale)
    }
}
