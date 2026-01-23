import Foundation
import FoundationModels

/// A state extractor implementation that uses a custom extraction function.
/// This allows users to provide their own state extraction logic.
public struct CustomStateExtractor: StateExtractor {
    private let extractFunction: @Sendable ([Transcript.Entry]) async throws -> StructuredState

    /// Creates a custom state extractor with a user-provided extraction function.
    ///
    /// - Parameter extractFunction: An async function that takes conversation entries and returns a `StructuredState`.
    public init(
        extractFunction: @escaping @Sendable ([Transcript.Entry]) async throws -> StructuredState
    ) {
        self.extractFunction = extractFunction
    }

    public func extractState(from entries: [Transcript.Entry]) async throws -> StructuredState {
        return try await extractFunction(entries)
    }
}
