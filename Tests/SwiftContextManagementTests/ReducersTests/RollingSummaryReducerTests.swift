import Testing
import FoundationModels

@testable import SwiftContextManagement

@Suite("Rolling Summary Reducer Tests")
struct RollingSummaryReducerTests {
    
    @Test("Creates summary and keeps recent entries")
    func createsSummaryAndKeepsRecentEntries() async throws {
        let mockSummary = "Previous conversation about project planning"
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: mockSummary)
        
        let config = RollingSummaryConfiguration(
            recentTurnsToKeep: 2,
            summarizer: mockSummarizer,
            shouldKeepInstructions: true
        )
        
        let instructions = TestHelpers.createInstructions(content: "System instructions")
        let turn1Prompt = TestHelpers.createPrompt(content: "Turn 1 - Should be summarized")
        let turn1Response = TestHelpers.createResponse(content: "Response 1")
        let turn2Prompt = TestHelpers.createPrompt(content: "Turn 2 - Should be summarized")
        let turn2Response = TestHelpers.createResponse(content: "Response 2")
        let turn3Prompt = TestHelpers.createPrompt(content: "Turn 3 - Should be kept")
        let turn3Response = TestHelpers.createResponse(content: "Response 3 - Should be kept")
        
        let entries: [Transcript.Entry] = [
            .instructions(instructions),
            .prompt(turn1Prompt),
            .response(turn1Response),
            .prompt(turn2Prompt),
            .response(turn2Response),
            .prompt(turn3Prompt),
            .response(turn3Response)
        ]
        
        let transcript = Transcript(entries: entries)
        let reducer = RollingSummaryReducer(configuration: config)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have: instructions + summary + 2 recent entries
        #expect(reducedEntries.count == 4)
        
        // Check instructions are preserved
        guard case .instructions = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        
        // Check summary exists
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.count == 1)
        
        // Check recent entries are kept
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        #expect(conversationEntries.count == 3) // 1 summary + 2 recent entries
        
        // Filter out summary entries to check only the recent conversation entries
        let nonSummaryEntries = SummarizationTestHelpers.extractNonSummaryEntries(from: conversationEntries)
        #expect(nonSummaryEntries.count == 2)
        
        TestHelpers.assertEntriesContain(
            nonSummaryEntries,
            expectedTexts: Set(["Turn 3 - Should be kept", "Response 3 - Should be kept"])
        )
        
        // Verify old entries are NOT in the result
        TestHelpers.assertEntriesDoNotContain(
            nonSummaryEntries,
            unexpectedTexts: Set(["Turn 1 - Should be summarized", "Response 1", "Turn 2 - Should be summarized", "Response 2"])
        )
    }
    
    @Test("Handles empty transcript")
    func handlesEmptyTranscript() async throws {
        let config = RollingSummaryConfiguration()
        let reducer = RollingSummaryReducer(configuration: config)
        
        let transcript = Transcript(entries: [])
        let reducedTranscript = try await reducer.reduce(transcript)
        
        #expect(Array(reducedTranscript).isEmpty)
    }
    
    @Test("Handles transcript with only instructions")
    func handlesTranscriptWithOnlyInstructions() async throws {
        let config = RollingSummaryConfiguration(shouldKeepInstructions: true)
        let reducer = RollingSummaryReducer(configuration: config)
        
        let instructions = TestHelpers.createInstructions(content: "System instructions")
        let transcript = Transcript(entries: [.instructions(instructions)])
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 1)
        guard case .instructions = reducedEntries.first else {
            Issue.record("Should preserve instructions")
            return
        }
    }
    
    @Test("Does not create summary when all entries are recent")
    func doesNotCreateSummaryWhenAllEntriesAreRecent() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Summary")
        let config = RollingSummaryConfiguration(
            recentTurnsToKeep: 10, // More than we have
            summarizer: mockSummarizer
        )
        
        let prompt = TestHelpers.createPrompt(content: "Recent prompt")
        let response = TestHelpers.createResponse(content: "Recent response")
        
        let transcript = Transcript(entries: [
            .prompt(prompt),
            .response(response)
        ])
        
        let reducer = RollingSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have no summary, just the entries
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.isEmpty)
        #expect(reducedEntries.count == 2)
    }
    
    @Test("Respects shouldKeepInstructions setting")
    func respectsShouldKeepInstructionsSetting() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Summary")
        
        let config = RollingSummaryConfiguration(
            recentTurnsToKeep: 1,
            summarizer: mockSummarizer,
            shouldKeepInstructions: false
        )
        
        let instructions = TestHelpers.createInstructions(content: "Instructions")
        let prompt = TestHelpers.createPrompt(content: "Prompt")
        let response = TestHelpers.createResponse(content: "Response")
        
        let transcript = Transcript(entries: [
            .instructions(instructions),
            .prompt(prompt),
            .response(response)
        ])
        
        let reducer = RollingSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should not have instructions
        let hasInstructions = reducedEntries.contains {
            if case .instructions = $0 { return true }
            return false
        }
        #expect(!hasInstructions)
    }
    
    @Test("Summarizes all entries when recentTurnsToKeep is zero")
    func summarizesAllEntriesWhenRecentTurnsToKeepIsZero() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Complete summary")
        
        let config = RollingSummaryConfiguration(
            recentTurnsToKeep: 0,
            summarizer: mockSummarizer,
            shouldKeepInstructions: true
        )
        
        let instructions = TestHelpers.createInstructions(content: "System instructions")
        let prompt = TestHelpers.createPrompt(content: "Question")
        let response = TestHelpers.createResponse(content: "Answer")
        
        let transcript = Transcript(entries: [
            .instructions(instructions),
            .prompt(prompt),
            .response(response)
        ])
        
        let reducer = RollingSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have: instructions + summary (no recent entries)
        #expect(reducedEntries.count == 2)
        
        // First should be instructions
        guard case .instructions = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        
        // Second should be summary
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.count == 1)
        
        // No non-summary conversation entries
        let nonSummaryEntries = SummarizationTestHelpers.extractNonSummaryEntries(from: reducedEntries)
        let nonInstructionNonSummary = nonSummaryEntries.filter {
            if case .instructions = $0 { return false }
            return true
        }
        #expect(nonInstructionNonSummary.isEmpty)
    }
    
    @Test("Handles transcript with only conversation entries (no instructions)")
    func handlesTranscriptWithOnlyConversationEntries() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Conversation summary")
        
        let config = RollingSummaryConfiguration(
            recentTurnsToKeep: 1,
            summarizer: mockSummarizer,
            shouldKeepInstructions: true
        )
        
        let prompt1 = TestHelpers.createPrompt(content: "Old prompt")
        let response1 = TestHelpers.createResponse(content: "Old response")
        let prompt2 = TestHelpers.createPrompt(content: "Recent prompt")
        
        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .response(response1),
            .prompt(prompt2)
        ])
        
        let reducer = RollingSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have: summary + 1 recent entry
        #expect(reducedEntries.count == 2)
        
        // Check summary exists
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.count == 1)
        
        // Check recent entry is kept
        let nonSummaryEntries = SummarizationTestHelpers.extractNonSummaryEntries(from: reducedEntries)
        #expect(nonSummaryEntries.count == 1)
        TestHelpers.assertEntryContains(nonSummaryEntries[0], expectedText: "Recent prompt")
    }
}
