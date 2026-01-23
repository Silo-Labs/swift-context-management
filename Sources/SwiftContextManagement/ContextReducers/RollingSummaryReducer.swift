import FoundationModels

/// A context reducer that implements a rolling summary strategy, replacing older conversation history
/// with a single running summary while keeping recent turns verbatim.
struct RollingSummaryReducer: ContextReducer {
    private let configuration: RollingSummaryConfiguration

    /// Creates a rolling summary reducer with the specified configuration.
    ///
    /// - Parameter configuration: The configuration for the rolling summary strategy.
    init(configuration: RollingSummaryConfiguration = RollingSummaryConfiguration()) {
        self.configuration = configuration
    }

    /// Reduces the transcript by summarizing older entries and keeping recent ones verbatim.
    ///
    /// This method separates instruction entries from conversation entries, preserves all instruction entries
    /// (if enabled), summarizes older conversation entries, and keeps the most recent `recentTurnsToKeep`
    /// conversation entries verbatim.
    ///
    /// - Parameter transcript: The original transcript containing all entries.
    /// - Returns: A new transcript containing instructions (if enabled), a summary entry, and recent conversation entries.
    /// - Throws: An error if summarization fails.
    func reduce(_ transcript: Transcript) async throws -> Transcript {
        var newEntries = [Transcript.Entry]()

        let (instructionEntries, conversationEntries) = extractInstructionsAndConversations(from: transcript)

        if configuration.shouldKeepInstructions {
            newEntries.append(contentsOf: instructionEntries)
        }

        let entriesToSummarize = conversationEntries.dropLast(configuration.recentTurnsToKeep)
        let recentEntries = Array(conversationEntries.suffix(configuration.recentTurnsToKeep))

        if !entriesToSummarize.isEmpty {
            let summaryText = try await configuration.summarizer.summarize(
                entries: Array(entriesToSummarize),
                instructions: configuration.summarizationInstructions,
                locale: configuration.locale
            )

            // Create a summary entry (using a prompt entry to represent the summary)
            let summaryPrompt = Transcript.Prompt(
                segments: [
                    .text(
                        Transcript.TextSegment(
                            content: "Summary of previous conversation: \(summaryText)"
                        )
                    )
                ]
            )
            newEntries.append(.prompt(summaryPrompt))
        }

        newEntries.append(contentsOf: recentEntries)

        return Transcript(entries: newEntries)
    }
}
