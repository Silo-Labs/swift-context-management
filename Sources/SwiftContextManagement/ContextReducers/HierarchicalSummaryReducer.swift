import Foundation
import FoundationModels

/// A context reducer that implements a hierarchical summary strategy, maintaining multiple summaries
/// at different granularities (per turn, per topic, global) while keeping recent turns verbatim.
struct HierarchicalSummaryReducer: ContextReducer {
    private let configuration: HierarchicalSummaryConfiguration

    /// Creates a hierarchical summary reducer with the specified configuration.
    ///
    /// - Parameter configuration: The configuration for the hierarchical summary strategy.
    init(configuration: HierarchicalSummaryConfiguration = HierarchicalSummaryConfiguration()) {
        self.configuration = configuration
    }

    /// Reduces the transcript by creating summaries at different granularity levels.
    ///
    /// This method separates instruction entries from conversation entries, preserves all instruction entries
    /// (if enabled), creates summaries at the specified granularity levels for older conversation entries,
    /// and keeps the most recent `recentTurnsToKeep` conversation entries verbatim.
    ///
    /// - Parameter transcript: The original transcript containing all entries.
    /// - Returns: A new transcript containing instructions (if enabled), summary entries at different granularities, and recent conversation entries.
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
            for granularity in configuration.granularityLevels {
                let summaryText = try await createSummary(
                    for: Array(entriesToSummarize),
                    granularity: granularity
                )

                let summaryPrompt = Transcript.Prompt(
                    segments: [
                        .text(
                            Transcript.TextSegment(
                                content: "\(granularity.description) Summary: \(summaryText)"
                            )
                        )
                    ]
                )

                newEntries.append(.prompt(summaryPrompt))
            }
        }

        newEntries.append(contentsOf: recentEntries)

        return Transcript(entries: newEntries)
    }
}

private extension HierarchicalSummaryReducer {
    /// Creates a summary for the given entries at the specified granularity level.
    ///
    /// - Parameters:
    ///   - entries: The conversation entries to summarize.
    ///   - granularity: The granularity level for summarization.
    /// - Returns: A summary string.
    /// - Throws: An error if summarization fails.
    func createSummary(
        for entries: [Transcript.Entry],
        granularity: SummaryGranularity
    ) async throws -> String {
        switch granularity {
        case .global:
            return try await configuration.summarizer.summarize(
                entries: entries,
                instructions: configuration.summarizationInstructions,
                locale: configuration.locale
            )
        case .perTurn:
            let turns = groupEntriesIntoTurns(entries)
            var turnSummaries: [String] = []

            for turn in turns {
                let turnSummary = try await configuration.summarizer.summarize(
                    entries: turn,
                    instructions: configuration.summarizationInstructions,
                    locale: configuration.locale
                )
                turnSummaries.append(turnSummary)
            }

            return turnSummaries.joined(separator: "\n\n")
        case .perTopic:
            let topicDetector = configuration.topicDetector
            let topicGroups = try await topicDetector.detectTopics(in: entries)

            var topicSummaries: [String] = []

            for (index, topicGroup) in topicGroups.enumerated() {
                let topicSummary = try await configuration.summarizer.summarize(
                    entries: topicGroup,
                    instructions: configuration.summarizationInstructions,
                    locale: configuration.locale
                )
                topicSummaries.append("Topic \(index + 1): \(topicSummary)")
            }

            return topicSummaries.joined(separator: "\n\n")
        }
    }

    /// Groups conversation entries into turns (prompt + response pairs).
    ///
    /// - Parameter entries: The conversation entries to group.
    /// - Returns: An array of arrays, where each inner array represents a turn.
    func groupEntriesIntoTurns(_ entries: [Transcript.Entry]) -> [[Transcript.Entry]] {
        var turns: [[Transcript.Entry]] = []
        var currentTurn: [Transcript.Entry] = []

        for entry in entries {
            switch entry {
            case .prompt:
                if !currentTurn.isEmpty {
                    turns.append(currentTurn)
                }
                currentTurn = [entry]
            case .response:
                currentTurn.append(entry)
                turns.append(currentTurn)
                currentTurn = []

            default:
                currentTurn.append(entry)
            }
        }

        if !currentTurn.isEmpty {
            turns.append(currentTurn)
        }

        return turns
    }
}
