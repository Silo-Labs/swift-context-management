import FoundationModels

/// A context reducer that implements a sliding window strategy, keeping only the most recent conversation turns
/// while optionally preserving instruction entries.
///
/// The sliding window approach discards older conversation history, keeping only the most recent N turns
/// to stay within the context window size.
struct SlidingWindowReducer: ContextReducer {
    private let turns: Int
    private let shouldKeepInstructions: Bool

    /// Creates a sliding window reducer with the specified number of turns to keep.
    ///
    /// - Parameters:
    ///   - turns: The number of most recent conversation entries to preserve. This includes prompts,
    ///            responses, tool calls, and tool outputs. Older entries beyond this count will be discarded.
    ///   - shouldKeepInstructions: Whether to preserve instruction entries at the beginning of the transcript.
    ///                             Defaults to `true`. When enabled, all instruction entries are kept regardless
    ///                             of the `turns` parameter, as instructions define the model's behavior.
    init(turns: Int, shouldKeepInstructions: Bool = true) {
        self.turns = turns
        self.shouldKeepInstructions = shouldKeepInstructions
    }

    /// Reduces the transcript by keeping only the most recent conversation turns.
    ///
    /// This method separates instruction entries from conversation entries, optionally preserves all instructions,
    /// and keeps only the most recent `turns` number of conversation entries (prompts, responses, tool calls, etc.).
    ///
    /// - Parameter transcript: The original transcript containing all entries.
    /// - Returns: A new transcript containing only the preserved entries (instructions if enabled, plus recent conversation turns).
    /// - Throws: This method doesn't currently throw, but the signature allows for future error handling.
    func reduce(_ transcript: Transcript) async throws -> Transcript {
        var newEntries = [Transcript.Entry]()
        
        let (instructionEntries, conversationEntries) = extractInstructionsAndConversations(from: transcript)
        
        if shouldKeepInstructions {
            newEntries.append(contentsOf: instructionEntries)
        }
        
        let recentEntries = conversationEntries.suffix(turns)
        newEntries.append(contentsOf: recentEntries)
        
        return Transcript(entries: newEntries)
    }
}
