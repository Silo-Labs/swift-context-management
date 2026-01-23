import Foundation
import FoundationModels

/// Configuration for rolling summary reduction strategy.
public struct RollingSummaryConfiguration: Sendable {
    /// The number of recent conversation entries to keep verbatim (not summarized).
    public let recentTurnsToKeep: Int

    /// The summarizer to use for creating summaries.
    public let summarizer: any Summarizer

    /// Optional custom instructions for the summarization process.
    public let summarizationInstructions: String?

    /// The locale for summaries
    public let locale: Locale

    /// Whether to preserve instruction entries at the beginning of the transcript.
    public let shouldKeepInstructions: Bool

    /// Creates a rolling summary configuration.
    ///
    /// - Parameters:
    ///   - recentTurnsToKeep: The number of most recent conversation entries to keep verbatim. Defaults to `2`.
    ///   - summarizer: The summarizer to use. Defaults to `FoundationModelsSummarizer()`.
    ///   - summarizationInstructions: Custom instructions for summarization. If `nil`, uses default instructions.
    ///   - locale: The locale for summaries. Defaults to `"en_US"`.
    ///   - shouldKeepInstructions: Whether to preserve instruction entries. Defaults to `true`.
    public init(
        recentTurnsToKeep: Int = 2,
        summarizer: (any Summarizer)? = nil,
        summarizationInstructions: String? = nil,
        locale: Locale = .enUS,
        shouldKeepInstructions: Bool = true
    ) {
        self.recentTurnsToKeep = recentTurnsToKeep
        self.summarizer = summarizer ?? FoundationModelsSummarizer()
        self.summarizationInstructions = summarizationInstructions
        self.locale = locale
        self.shouldKeepInstructions = shouldKeepInstructions
    }
}
