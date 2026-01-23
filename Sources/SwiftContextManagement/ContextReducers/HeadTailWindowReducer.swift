import FoundationModels

/// A context reducer that implements a head-tail window strategy, preserving initial instructions (head)
/// and the most recent conversation turns (tail) while dropping the middle part of the conversation.
///
/// The head-tail window approach keeps all instruction entries at the beginning of the transcript
/// and the most recent N conversation entries at the end, discarding conversation entries in between.
/// This strategy is useful when you want to maintain the model's behavioral instructions while
/// preserving recent context, even if older conversation history is removed.
struct HeadTailWindowReducer: ContextReducer {
    private let tailTurns: Int

    /// Creates a head-tail window reducer with the specified number of tail entries to keep.
    ///
    /// - Parameter tailTurns: The number of most recent conversation entries to preserve in the tail.
    ///                        This includes prompts, responses, tool calls, and tool outputs.
    ///                        Defaults to `2`. Older conversation entries beyond this count will be discarded,
    ///                        but all instruction entries (head) are always preserved.
    init(tailTurns: Int = 2) {
        self.tailTurns = tailTurns
    }

    /// Reduces the transcript by preserving the head (instructions) and tail (recent entries).
    ///
    /// This method separates instruction entries from conversation entries, preserves all instruction entries
    /// as the "head", and keeps only the most recent `tailTurns` number of conversation entries as the "tail".
    /// All conversation entries between the head and tail are discarded.
    ///
    /// - Parameter transcript: The original transcript containing all entries.
    /// - Returns: A new transcript containing the preserved entries (all instructions plus recent conversation entries).
    /// - Throws: This method doesn't currently throw, but the signature allows for future error handling.
    func reduce(_ transcript: Transcript) async throws -> Transcript {
        var newEntries = [Transcript.Entry]()

        let (instructionEntries, conversationEntries) = extractInstructionsAndConversations(from: transcript)

        // Keep all instructions (head)
        newEntries.append(contentsOf: instructionEntries)

        // Keep the most recent N conversation entries (tail)
        let tailEntries = conversationEntries.suffix(tailTurns)
        newEntries.append(contentsOf: tailEntries)

        return Transcript(entries: newEntries)
    }
}
