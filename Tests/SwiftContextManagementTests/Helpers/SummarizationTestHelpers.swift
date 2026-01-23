import Testing
import FoundationModels

@testable import SwiftContextManagement

enum SummarizationTestHelpers {
    static func createMockSummarizer(returning summary: String) -> any Summarizer {
        return CustomLLMSummarizer { _, _, _ in
            return summary
        }
    }

    static func createCountingSummarizer() -> any Summarizer {
        return CustomLLMSummarizer { entries, _, _ in
            return "Summary of \(entries.count) entries"
        }
    }
    
    static func createCapturingSummarizer(
        capturedEntries: inout [[Transcript.Entry]],
        capturedInstructions: inout [String?],
        returning summary: String
    ) -> any Summarizer {
        let capture = SummarizerCapture()
        return CustomLLMSummarizer { entries, instructions, _ in
            capture.entries.append(entries)
            capture.instructions.append(instructions)
            return summary
        }
    }

    static func extractSummaryText(from entry: Transcript.Entry) -> String? {
        let text = TranscriptHelpers.extractText(from: entry)
        // Check if it's a summary entry (contains "Summary")
        if let text = text, text.contains("Summary") {
            return text
        }
        return nil
    }

    static func extractSummaryEntries(from entries: [Transcript.Entry]) -> [Transcript.Entry] {
        return entries.filter { extractSummaryText(from: $0) != nil }
    }
    
    static func extractNonSummaryEntries(from entries: [Transcript.Entry]) -> [Transcript.Entry] {
        return entries.filter { entry in
            let text = TranscriptHelpers.extractText(from: entry) ?? ""
            return !text.contains("Summary")
        }
    }
}

final class SummarizerCapture: @unchecked Sendable {
    var entries: [[Transcript.Entry]] = []
    var instructions: [String?] = []
}
