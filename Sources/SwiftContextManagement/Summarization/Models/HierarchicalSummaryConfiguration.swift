import Foundation

/// Configuration for hierarchical summary reduction strategy.
public struct HierarchicalSummaryConfiguration: Sendable {
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

    /// The granularity levels for hierarchical summarization.
    /// Each level represents a different scope (e.g., per-turn, per-topic, global).
    public let granularityLevels: [SummaryGranularity]

    /// The topic detector to use for per-topic summarization.
    /// Only used when `.perTopic` is included in `granularityLevels`.
    public let topicDetector: any TopicDetector

    /// Creates a hierarchical summary configuration.
    ///
    /// - Parameters:
    ///   - recentTurnsToKeep: The number of most recent conversation entries to keep verbatim. Defaults to `2`.
    ///   - summarizer: The summarizer to use. Defaults to `FoundationModelsSummarizer()`.
    ///   - summarizationInstructions: Custom instructions for summarization. If `nil`, uses default instructions.
    ///   - locale: The locale for summaries. Defaults to `"en_US"`.
    ///   - shouldKeepInstructions: Whether to preserve instruction entries. Defaults to `true`.
    ///   - granularityLevels: The granularity levels for hierarchical summarization. Defaults to a single global summary level.
    ///   - topicDetector: The topic detector to use for per-topic summarization. Defaults to `FoundationModelsTopicDetector()`.
    public init(
        recentTurnsToKeep: Int = 2,
        summarizer: (any Summarizer)? = nil,
        summarizationInstructions: String? = nil,
        locale: Locale = .enUS,
        shouldKeepInstructions: Bool = true,
        granularityLevels: [SummaryGranularity] = [.global],
        topicDetector: (any TopicDetector)? = nil
    ) {
        self.recentTurnsToKeep = recentTurnsToKeep
        self.summarizer = summarizer ?? FoundationModelsSummarizer()
        self.summarizationInstructions = summarizationInstructions
        self.locale = locale
        self.shouldKeepInstructions = shouldKeepInstructions
        self.granularityLevels = granularityLevels
        self.topicDetector = topicDetector ?? FoundationModelsTopicDetector()
    }
}
