import FoundationModels

/// A default topic detector implementation using FoundationModels.
/// Uses the LLM to identify topics and group conversation entries accordingly.
public struct FoundationModelsTopicDetector: TopicDetector {
    private let session: LanguageModelSession

    /// Creates a FoundationModels topic detector.
    ///
    /// - Parameter session: An optional LanguageModelSession. If `nil`, creates a new session.
    public init(session: LanguageModelSession? = nil) {
        self.session = session ?? LanguageModelSession()
    }

    public func detectTopics(in entries: [Transcript.Entry]) async throws -> [[Transcript.Entry]] {
        let conversationText = entries.enumerated().map { index, entry in
            if let text = TranscriptHelpers.extractText(from: entry) {
                return "[Entry \(index)]: \(text)"
            }
            return "[Entry \(index)]: (non-text entry)"
        }.joined(separator: "\n\n")

        let topicDetectionPrompt = """
        Analyze the following conversation and identify distinct topics. 
        Group the entries by topic. For each topic, list the entry indices that belong to it.
        
        Format your response as JSON with this structure:
        {
          "topics": [
            {
              "topic": "Topic name",
              "entryIndices": [0, 1, 2]
            },
            {
              "topic": "Another topic",
              "entryIndices": [3, 4, 5]
            }
          ]
        }
        
        Conversation:
        \(conversationText)
        """

        let response = try await session.respond(to: topicDetectionPrompt, generating: [TopicDetectionResult].self)
        return try groupEntriesByTopics(
            results: response.content,
            entries: entries
        )
    }
}

private extension FoundationModelsTopicDetector {
    /// Groups entries based on topic detection results.
    ///
    /// - Parameters:
    ///   - results: The topic detection results from the LLM.
    ///   - entries: The original conversation entries.
    /// - Returns: An array of entry groups, where each group represents a topic.
    /// - Throws: An error if grouping fails (e.g., invalid indices).
    func groupEntriesByTopics(
        results: [TopicDetectionResult],
        entries: [Transcript.Entry]
    ) throws -> [[Transcript.Entry]] {
        var topicGroups: [[Transcript.Entry]] = []
        var usedIndices = Set<Int>()

        for result in results {
            let groupEntries = result.entryIndices.compactMap { index -> Transcript.Entry? in
                guard index >= 0 && index < entries.count else {
                    return nil
                }

                guard !usedIndices.contains(index) else {
                    return nil
                }

                usedIndices.insert(index)
                return entries[index]
            }

            if !groupEntries.isEmpty {
                topicGroups.append(groupEntries)
            }
        }

        let unassignedEntries = entries.enumerated()
            .filter { !usedIndices.contains($0.offset) }
            .map { $0.element }

        if !unassignedEntries.isEmpty {
            topicGroups.append(unassignedEntries)
        }

        return topicGroups.isEmpty ? [entries] : topicGroups
    }
}
