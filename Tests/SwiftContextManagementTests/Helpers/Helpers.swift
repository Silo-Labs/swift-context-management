import Testing
import FoundationModels

@testable import SwiftContextManagement

enum TestHelpers {
    static func createInstructions(content: String) -> Transcript.Instructions {
        Transcript.Instructions(
            segments: [.text(Transcript.TextSegment(content: content))],
            toolDefinitions: []
        )
    }
    
    static func createPrompt(content: String) -> Transcript.Prompt {
        Transcript.Prompt(segments: [.text(Transcript.TextSegment(content: content))])
    }
    
    static func createResponse(content: String) -> Transcript.Response {
        Transcript.Response(assetIDs: [], segments: [.text(Transcript.TextSegment(content: content))])
    }

    static func extractConversationEntries(from entries: [Transcript.Entry]) -> [Transcript.Entry] {
        entries.filter {
            if case .instructions = $0 { return false }
            return true
        }
    }

    static func assertEntryContains(_ entry: Transcript.Entry, expectedText: String, file: StaticString = #file, line: UInt = #line) {
        let extractedText = TranscriptHelpers.extractText(from: entry)
        #expect(extractedText == expectedText, "Expected entry to contain '\(expectedText)', but got '\(extractedText ?? "nil")'")
    }
    
    static func assertEntriesContain(_ entries: [Transcript.Entry], expectedTexts: Set<String>, file: StaticString = #file, line: UInt = #line) {
        let extractedTexts = Set(entries.compactMap { TranscriptHelpers.extractText(from: $0) })
        #expect(extractedTexts == expectedTexts, "Expected entries to contain \(expectedTexts), but got \(extractedTexts)")
    }
    
    static func assertEntriesDoNotContain(_ entries: [Transcript.Entry], unexpectedTexts: Set<String>, file: StaticString = #file, line: UInt = #line) {
        let extractedTexts = Set(entries.compactMap { TranscriptHelpers.extractText(from: $0) })
        let foundUnexpected = extractedTexts.intersection(unexpectedTexts)
        #expect(foundUnexpected.isEmpty, "Found unexpected texts in entries: \(foundUnexpected)")
    }

    static func assertEntriesContainSubset(_ entries: [Transcript.Entry], expectedTexts: Set<String>, file: StaticString = #file, line: UInt = #line) {
        let extractedTexts = Set(entries.compactMap { TranscriptHelpers.extractText(from: $0) })
        let missingTexts = expectedTexts.subtracting(extractedTexts)
        #expect(missingTexts.isEmpty, "Expected entries to contain \(expectedTexts), but missing: \(missingTexts). Found: \(extractedTexts)")
    }
}
