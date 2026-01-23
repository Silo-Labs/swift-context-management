import FoundationModels

/// A protocol for detecting topics in conversation history.
/// Implementations can use different strategies to group entries by topic.
public protocol TopicDetector: Sendable {
    /// Detects topics in conversation entries and groups them accordingly.
    ///
    /// - Parameter entries: The conversation entries to analyze.
    /// - Returns: An array of topic groups, where each group contains entries that belong to the same topic. Each group is represented as an array of entries.
    /// - Throws: An error if topic detection fails.
    func detectTopics(in entries: [Transcript.Entry]) async throws -> [[Transcript.Entry]]
}
