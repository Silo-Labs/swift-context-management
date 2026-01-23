import FoundationModels

public extension Transcript {
    /// Pretty prints the transcript with the given prefix count.
    ///
    /// - Parameter prefixCount: The number of characters to prefix the text with.
    /// - Returns: A pretty printed string of the transcript.
    func prettyPrinted(prefixCount: Int = 100) -> String {
        self.enumerated().map { index, entry in
            let role = switch entry {
            case .instructions: "[SYSTEM]"
            case .prompt: "[USER]"
            case .response: "[ASSISTANT]"
            default: "[OTHER]"
            }
            let text = TranscriptHelpers.extractText(from: entry) ?? "..."
            return "\(index). \(role) \(text.prefix(prefixCount))..."
        }.joined(separator: "\n")
    }
    
    /// Calculates the total character count of all text content in the transcript.
    ///
    /// - Returns: The total number of characters across all entries.
    func characterCount() -> Int {
        self.reduce(0) { count, entry in
            let text = TranscriptHelpers.extractText(from: entry) ?? ""
            return count + text.count
        }
    }
    
    /// Estimates the token count based on character count.
    ///
    /// Uses a conservative estimate of 4 characters per token, which is appropriate
    /// for languages like English, Spanish, and German. For languages like Japanese,
    /// Chinese, or Korean, this may overestimate (they use ~1 char per token).
    ///
    /// - Returns: An estimated token count.
    func estimatedTokenCount() -> Int {
        // Conservative estimate: ~4 characters per token for English/Spanish/German
        // Note: This is approximate and language-dependent
        return Swift.max(1, characterCount() / 4)
    }
}
