import FoundationModels

/// A reducer that does nothing - returns the transcript unchanged.
/// Used for unimplemented policies.
struct NoOpReducer: ContextReducer {
    func reduce(_ transcript: Transcript) async throws -> Transcript {
        // Return the transcript unchanged
        return transcript
    }
}
