import FoundationModels

public protocol StateExtractor: Sendable {
    /// Extracts a structured state from the given conversation entries.
    ///
    /// - Parameter entries: The conversation entries to analyze.
    /// - Returns: A `StructuredState` containing important facts, constraints, and decisions.
    func extractState(from entries: [Transcript.Entry]) async throws -> StructuredState
}
