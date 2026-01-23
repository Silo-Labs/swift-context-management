import FoundationModels

/// Utility for chunking conversation entries with token limits and overlap.
struct ConversationChunker {
    /// Default maximum tokens per chunk (1000 tokens).
    static let defaultMaxTokensPerChunk: Int = 1000

    /// Default overlap tokens between chunks (200 tokens = 20% of 1000).
    static let defaultOverlapTokens: Int = 200

    /// Chunks entries into groups that fit within the token limit, with overlap between chunks.
    ///
    /// - Parameters:
    ///   - entries: The entries to chunk.
    ///   - maxTokensPerChunk: Maximum tokens per chunk. Defaults to 1000.
    ///   - overlapTokens: Number of tokens to overlap between chunks. Defaults to 200 (20%).
    /// - Returns: An array of entry chunks, where each chunk fits within the token limit.
    static func chunkEntries(
        _ entries: [Transcript.Entry],
        maxTokensPerChunk: Int = defaultMaxTokensPerChunk,
        overlapTokens: Int = defaultOverlapTokens
    ) -> [[Transcript.Entry]] {
        guard !entries.isEmpty else { return [] }

        var chunks: [[Transcript.Entry]] = []
        var currentChunk: [Transcript.Entry] = []
        var currentTokenCount = 0

        for entry in entries {
            let entryTokens = TranscriptHelpers.estimateTokens(for: entry)

            if currentTokenCount + entryTokens > maxTokensPerChunk && !currentChunk.isEmpty {
                chunks.append(currentChunk)

                // Start new chunk with overlap
                var overlapTokenCount = 0
                var overlapEntries: [Transcript.Entry] = []

                for i in (0..<currentChunk.count).reversed() {
                    let overlapEntryTokens = TranscriptHelpers.estimateTokens(for: currentChunk[i])
                    if overlapTokenCount + overlapEntryTokens <= overlapTokens {
                        overlapEntries.insert(currentChunk[i], at: 0)
                        overlapTokenCount += overlapEntryTokens
                    } else {
                        break
                    }
                }

                // Start new chunk with overlap entries
                currentChunk = overlapEntries
                currentTokenCount = overlapTokenCount
            }

            currentChunk.append(entry)
            currentTokenCount += entryTokens
        }

        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks.isEmpty ? [entries] : chunks
    }

    /// Estimates total tokens for a collection of entries.
    ///
    /// - Parameter entries: The entries to estimate.
    /// - Returns: Total estimated token count.
    public static func estimateTotalTokens(_ entries: [Transcript.Entry]) -> Int {
        entries.reduce(0) { $0 + TranscriptHelpers.estimateTokens(for: $1) }
    }

    /// Checks if the transcript with a new entry would fit within the context window.
    ///
    /// - Parameters:
    ///   - transcript: The existing transcript entries.
    ///   - newEntry: The new entry to be added.
    /// - Returns: `true` if the transcript plus new entry fits within the limit, `false` otherwise.
    static func fitsInContextWindow(
        transcript: [Transcript.Entry],
        newEntry: Transcript.Entry
    ) -> Bool {
        let currentTokens = estimateTotalTokens(transcript)
        let newEntryTokens = TranscriptHelpers.estimateTokens(for: newEntry)
        return (currentTokens + newEntryTokens) <= Constants.contextWindowLimit
    }
    
    /// Checks if the transcript fits within the context window.
    ///
    /// - Parameters:
    ///   - transcript: The transcript entries to check.
    /// - Returns: `true` if the transcript fits within the limit, `false` otherwise.
    static func fitsInContextWindow(
        transcript: [Transcript.Entry]
    ) -> Bool {
        let totalTokens = estimateTotalTokens(transcript)
        return totalTokens <= Constants.contextWindowLimit
    }
}
