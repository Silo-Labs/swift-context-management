import FoundationModels

/// Helper functions for working with Transcript entries, useful for logging and debugging.
public enum TranscriptHelpers {
    /// Extracts text content from a transcript entry.
    ///
    /// This function extracts all text segments from instructions, prompts, or responses
    /// and joins them into a single string. Useful for logging, debugging, and testing.
    ///
    /// - Parameter entry: The transcript entry to extract text from.
    /// - Returns: A string containing all text content from the entry, or `nil` if no text segments are found
    ///            or the entry type doesn't contain text (e.g., tool calls, tool outputs).
    public static func extractText(from entry: Transcript.Entry) -> String? {
        switch entry {
        case .instructions(let instructions):
            return instructions.segments.compactMap {
                if case .text(let textSegment) = $0 {
                    return textSegment.content
                }
                return nil
            }.joined()
        case .prompt(let prompt):
            return prompt.segments.compactMap {
                if case .text(let textSegment) = $0 {
                    return textSegment.content
                }
                return nil
            }.joined()
        case .response(let response):
            return response.segments.compactMap {
                if case .text(let textSegment) = $0 {
                    return textSegment.content
                }
                return nil
            }.joined()
        default:
            return nil
        }
    }

    /// Estimates the number of tokens in a text string.
    /// Uses a conservative estimate of 4 characters per token for English.
    ///
    /// - Parameter text: The text to estimate.
    /// - Returns: Estimated token count.
    static func estimateTokens(_ text: String) -> Int {
        return Swift.max(1, text.count / 4)
    }

    /// Estimates the number of tokens in a transcript entry.
    ///
    /// - Parameter entry: The entry to estimate.
    /// - Returns: Estimated token count.
    static func estimateTokens(for entry: Transcript.Entry) -> Int {
        guard let text = extractText(from: entry) else {
            return 0
        }
        return estimateTokens(text)
    }
}
