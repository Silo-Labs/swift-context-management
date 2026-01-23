import Testing
import FoundationModels

@testable import SwiftContextManagement

enum StateExtractionTestHelpers {
    /// Creates a mock state extractor that returns the specified structured state.
    static func createMockStateExtractor(returning state: StructuredState) -> any StateExtractor {
        return CustomStateExtractor { _ in
            return state
        }
    }
    
    /// Creates a mock state extractor that returns a state with the specified facts.
    static func createMockStateExtractor(facts: [ExtractedFact]) -> any StateExtractor {
        return CustomStateExtractor { _ in
            return StructuredState(information: facts)
        }
    }
    
    /// Creates a mock state extractor that counts entries and returns that info.
    static func createCountingStateExtractor() -> any StateExtractor {
        return CustomStateExtractor { entries in
            return StructuredState(information: [
                ExtractedFact(key: "entry_count", value: "\(entries.count)")
            ])
        }
    }
    
    /// Creates a mock state extractor that returns an empty state.
    static func createEmptyStateExtractor() -> any StateExtractor {
        return CustomStateExtractor { _ in
            return StructuredState(information: [])
        }
    }
    
    /// Extracts structured state entries from the transcript (entries containing "Structured state").
    static func extractStructuredStateEntries(from entries: [Transcript.Entry]) -> [Transcript.Entry] {
        return entries.filter { entry in
            guard let text = TranscriptHelpers.extractText(from: entry) else { return false }
            return text.contains("Structured state")
        }
    }
    
    /// Extracts non-structured-state entries from the transcript.
    static func extractNonStructuredStateEntries(from entries: [Transcript.Entry]) -> [Transcript.Entry] {
        return entries.filter { entry in
            guard let text = TranscriptHelpers.extractText(from: entry) else { return true }
            return !text.contains("Structured state")
        }
    }
}
