import Testing
import FoundationModels

@testable import SwiftContextManagement

@Suite("Hierarchical Summary Reducer Tests")
struct HierarchicalSummaryReducerTests {

    @Test("Creates global summary")
    func createsGlobalSummary() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Global summary")

        let config = HierarchicalSummaryConfiguration(
            recentTurnsToKeep: 1,
            summarizer: mockSummarizer,
            granularityLevels: [.global]
        )

        let prompt1 = TestHelpers.createPrompt(content: "Question 1")
        let response1 = TestHelpers.createResponse(content: "Answer 1")
        let prompt2 = TestHelpers.createPrompt(content: "Question 2")
        let response2 = TestHelpers.createResponse(content: "Answer 2")

        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .response(response1),
            .prompt(prompt2),
            .response(response2)
        ])

        let reducer = HierarchicalSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)

        // Should have: 1 global summary + 1 recent entry
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.count == 1)

        if let summaryText = SummarizationTestHelpers.extractSummaryText(from: summaryEntries[0]) {
            #expect(summaryText.contains("Global"))
        }
    }

    @Test("Creates per-turn summaries")
    func createsPerTurnSummaries() async throws {
        let mockSummarizer = SummarizationTestHelpers.createCountingSummarizer()

        let config = HierarchicalSummaryConfiguration(
            recentTurnsToKeep: 0,
            summarizer: mockSummarizer,
            granularityLevels: [.perTurn]
        )

        let prompt1 = TestHelpers.createPrompt(content: "Turn 1 prompt")
        let response1 = TestHelpers.createResponse(content: "Turn 1 response")
        let prompt2 = TestHelpers.createPrompt(content: "Turn 2 prompt")
        let response2 = TestHelpers.createResponse(content: "Turn 2 response")

        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .response(response1),
            .prompt(prompt2),
            .response(response2)
        ])

        let reducer = HierarchicalSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)

        // Should have summaries for each turn
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.count >= 1) // At least one summary
    }

    @Test("Creates multiple granularity summaries")
    func createsMultipleGranularitySummaries() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Summary")

        let config = HierarchicalSummaryConfiguration(
            recentTurnsToKeep: 1,
            summarizer: mockSummarizer,
            granularityLevels: [.global, .perTurn]
        )

        let prompt1 = TestHelpers.createPrompt(content: "Question 1")
        let response1 = TestHelpers.createResponse(content: "Answer 1")
        let prompt2 = TestHelpers.createPrompt(content: "Question 2")
        let response2 = TestHelpers.createResponse(content: "Answer 2")

        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .response(response1),
            .prompt(prompt2),
            .response(response2)
        ])

        let reducer = HierarchicalSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)

        // Should have multiple summaries (one per granularity level)
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.count >= 2) // At least global and per-turn
    }

    @Test("Preserves recent entries")
    func preservesRecentEntries() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Old conversation summary")
        
        let config = HierarchicalSummaryConfiguration(
            recentTurnsToKeep: 2,
            summarizer: mockSummarizer,
            granularityLevels: [.global]
        )

        let prompt1 = TestHelpers.createPrompt(content: "Old prompt")
        let response1 = TestHelpers.createResponse(content: "Old response")
        let prompt2 = TestHelpers.createPrompt(content: "Recent prompt")
        let response2 = TestHelpers.createResponse(content: "Recent response")

        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .response(response1),
            .prompt(prompt2),
            .response(response2)
        ])

        let reducer = HierarchicalSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)

        // Should have 1 summary + 2 recent entries = 3 entries
        #expect(reducedEntries.count == 3)

        // Check summary exists
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.count == 1)

        // Filter out summary entries to check only the recent conversation entries
        let nonSummaryEntries = SummarizationTestHelpers.extractNonSummaryEntries(from: reducedEntries)
        #expect(nonSummaryEntries.count == 2)

        TestHelpers.assertEntriesContain(
            nonSummaryEntries,
            expectedTexts: Set(["Recent prompt", "Recent response"])
        )
    }
    
    @Test("Handles empty transcript")
    func handlesEmptyTranscript() async throws {
        let config = HierarchicalSummaryConfiguration(granularityLevels: [.global])
        let reducer = HierarchicalSummaryReducer(configuration: config)
        
        let transcript = Transcript(entries: [])
        let reducedTranscript = try await reducer.reduce(transcript)
        
        #expect(Array(reducedTranscript).isEmpty)
    }
    
    @Test("Handles transcript with only instructions")
    func handlesTranscriptWithOnlyInstructions() async throws {
        let config = HierarchicalSummaryConfiguration(
            shouldKeepInstructions: true,
            granularityLevels: [.global]
        )
        let reducer = HierarchicalSummaryReducer(configuration: config)
        
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
    
    @Test("Respects shouldKeepInstructions setting")
    func respectsShouldKeepInstructionsSetting() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Summary")
        
        let config = HierarchicalSummaryConfiguration(
            recentTurnsToKeep: 1,
            summarizer: mockSummarizer,
            shouldKeepInstructions: false,
            granularityLevels: [.global]
        )
        
        let instructions = TestHelpers.createInstructions(content: "Instructions")
        let prompt1 = TestHelpers.createPrompt(content: "Old prompt")
        let prompt2 = TestHelpers.createPrompt(content: "Recent prompt")
        
        let transcript = Transcript(entries: [
            .instructions(instructions),
            .prompt(prompt1),
            .prompt(prompt2)
        ])
        
        let reducer = HierarchicalSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should not have instructions
        let hasInstructions = reducedEntries.contains {
            if case .instructions = $0 { return true }
            return false
        }
        #expect(!hasInstructions)
    }
    
    @Test("Does not create summary when all entries are recent")
    func doesNotCreateSummaryWhenAllEntriesAreRecent() async throws {
        let mockSummarizer = SummarizationTestHelpers.createMockSummarizer(returning: "Should not appear")
        
        let config = HierarchicalSummaryConfiguration(
            recentTurnsToKeep: 10, // More than we have
            summarizer: mockSummarizer,
            granularityLevels: [.global]
        )
        
        let prompt = TestHelpers.createPrompt(content: "Recent prompt")
        let response = TestHelpers.createResponse(content: "Recent response")
        
        let transcript = Transcript(entries: [
            .prompt(prompt),
            .response(response)
        ])
        
        let reducer = HierarchicalSummaryReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have no summary, just the entries
        let summaryEntries = SummarizationTestHelpers.extractSummaryEntries(from: reducedEntries)
        #expect(summaryEntries.isEmpty)
        #expect(reducedEntries.count == 2)
    }
}
