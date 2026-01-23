import Testing
import FoundationModels

@testable import SwiftContextManagement

@Suite("Structured State Reducer Tests")
struct StructuredStateReducerTests {
    
    @Test("Extracts state and keeps recent entries")
    func extractsStateAndKeepsRecentEntries() async throws {
        let mockState = StructuredState(information: [
            ExtractedFact(key: "name", value: "John"),
            ExtractedFact(key: "preference", value: "vegetarian")
        ])
        let mockExtractor = StateExtractionTestHelpers.createMockStateExtractor(returning: mockState)
        
        let config = StructuredStateConfiguration(
            recentTurnsToKeep: 2,
            stateExtractor: mockExtractor,
            shouldKeepInstructions: true
        )
        
        let instructions = TestHelpers.createInstructions(content: "System instructions")
        let turn1Prompt = TestHelpers.createPrompt(content: "Turn 1 - Should be extracted")
        let turn1Response = TestHelpers.createResponse(content: "Response 1")
        let turn2Prompt = TestHelpers.createPrompt(content: "Turn 2 - Should be extracted")
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
        let reducer = StructuredStateReducer(configuration: config)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have: instructions + state entry + 2 recent entries
        #expect(reducedEntries.count == 4)
        
        // Check instructions are preserved
        guard case .instructions = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        
        // Check structured state entry exists
        let stateEntries = StateExtractionTestHelpers.extractStructuredStateEntries(from: reducedEntries)
        #expect(stateEntries.count == 1)
        
        // Verify state content includes extracted facts
        if let stateText = TranscriptHelpers.extractText(from: stateEntries[0]) {
            #expect(stateText.contains("name"))
            #expect(stateText.contains("John"))
            #expect(stateText.contains("preference"))
            #expect(stateText.contains("vegetarian"))
        } else {
            Issue.record("State entry should have text content")
        }
        
        // Check recent entries are kept
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        let nonStateEntries = StateExtractionTestHelpers.extractNonStructuredStateEntries(from: conversationEntries)
        #expect(nonStateEntries.count == 2)
        
        TestHelpers.assertEntriesContain(
            nonStateEntries,
            expectedTexts: Set(["Turn 3 - Should be kept", "Response 3 - Should be kept"])
        )
        
        // Verify old entries are NOT in the result
        TestHelpers.assertEntriesDoNotContain(
            nonStateEntries,
            unexpectedTexts: Set(["Turn 1 - Should be extracted", "Response 1", "Turn 2 - Should be extracted", "Response 2"])
        )
    }
    
    @Test("Handles empty transcript")
    func handlesEmptyTranscript() async throws {
        let mockExtractor = StateExtractionTestHelpers.createEmptyStateExtractor()
        let config = StructuredStateConfiguration(stateExtractor: mockExtractor)
        let reducer = StructuredStateReducer(configuration: config)
        
        let transcript = Transcript(entries: [])
        let reducedTranscript = try await reducer.reduce(transcript)
        
        #expect(Array(reducedTranscript).isEmpty)
    }
    
    @Test("Handles transcript with only instructions")
    func handlesTranscriptWithOnlyInstructions() async throws {
        let mockExtractor = StateExtractionTestHelpers.createEmptyStateExtractor()
        let config = StructuredStateConfiguration(
            stateExtractor: mockExtractor,
            shouldKeepInstructions: true
        )
        let reducer = StructuredStateReducer(configuration: config)
        
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
    
    @Test("Does not create state entry when all entries are recent")
    func doesNotCreateStateEntryWhenAllEntriesAreRecent() async throws {
        let mockExtractor = StateExtractionTestHelpers.createMockStateExtractor(facts: [
            ExtractedFact(key: "test", value: "value")
        ])
        let config = StructuredStateConfiguration(
            recentTurnsToKeep: 10, // More than we have
            stateExtractor: mockExtractor
        )
        
        let prompt = TestHelpers.createPrompt(content: "Recent prompt")
        let response = TestHelpers.createResponse(content: "Recent response")
        
        let transcript = Transcript(entries: [
            .prompt(prompt),
            .response(response)
        ])
        
        let reducer = StructuredStateReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have no state entry, just the entries
        let stateEntries = StateExtractionTestHelpers.extractStructuredStateEntries(from: reducedEntries)
        #expect(stateEntries.isEmpty)
        #expect(reducedEntries.count == 2)
    }
    
    @Test("Respects shouldKeepInstructions setting")
    func respectsShouldKeepInstructionsSetting() async throws {
        let mockExtractor = StateExtractionTestHelpers.createMockStateExtractor(facts: [
            ExtractedFact(key: "fact", value: "value")
        ])
        
        let config = StructuredStateConfiguration(
            recentTurnsToKeep: 1,
            stateExtractor: mockExtractor,
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
        
        let reducer = StructuredStateReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should not have instructions
        let hasInstructions = reducedEntries.contains {
            if case .instructions = $0 { return true }
            return false
        }
        #expect(!hasInstructions)
    }
    
    @Test("Extracts state from all entries when recentTurnsToKeep is zero")
    func extractsStateFromAllEntriesWhenRecentTurnsToKeepIsZero() async throws {
        let mockExtractor = StateExtractionTestHelpers.createCountingStateExtractor()
        
        let config = StructuredStateConfiguration(
            recentTurnsToKeep: 0,
            stateExtractor: mockExtractor,
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
        
        let reducer = StructuredStateReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have: instructions + state entry (no recent entries)
        #expect(reducedEntries.count == 2)
        
        // First should be instructions
        guard case .instructions = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        
        // Second should be state entry
        let stateEntries = StateExtractionTestHelpers.extractStructuredStateEntries(from: reducedEntries)
        #expect(stateEntries.count == 1)
        
        // Verify the state entry contains count info (2 conversation entries were extracted)
        if let stateText = TranscriptHelpers.extractText(from: stateEntries[0]) {
            #expect(stateText.contains("entry_count"))
            #expect(stateText.contains("2"))
        }
        
        // No non-state conversation entries
        let nonStateEntries = StateExtractionTestHelpers.extractNonStructuredStateEntries(from: reducedEntries)
        let nonInstructionNonState = nonStateEntries.filter {
            if case .instructions = $0 { return false }
            return true
        }
        #expect(nonInstructionNonState.isEmpty)
    }
    
    @Test("Handles transcript with only conversation entries (no instructions)")
    func handlesTranscriptWithOnlyConversationEntries() async throws {
        let mockExtractor = StateExtractionTestHelpers.createMockStateExtractor(facts: [
            ExtractedFact(key: "extracted", value: "data")
        ])
        
        let config = StructuredStateConfiguration(
            recentTurnsToKeep: 1,
            stateExtractor: mockExtractor,
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
        
        let reducer = StructuredStateReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have: state entry + 1 recent entry
        #expect(reducedEntries.count == 2)
        
        // Check state entry exists
        let stateEntries = StateExtractionTestHelpers.extractStructuredStateEntries(from: reducedEntries)
        #expect(stateEntries.count == 1)
        
        // Check recent entry is kept
        let nonStateEntries = StateExtractionTestHelpers.extractNonStructuredStateEntries(from: reducedEntries)
        #expect(nonStateEntries.count == 1)
        TestHelpers.assertEntryContains(nonStateEntries[0], expectedText: "Recent prompt")
    }
    
    @Test("Handles empty extracted state gracefully")
    func handlesEmptyExtractedStateGracefully() async throws {
        let mockExtractor = StateExtractionTestHelpers.createEmptyStateExtractor()
        
        let config = StructuredStateConfiguration(
            recentTurnsToKeep: 1,
            stateExtractor: mockExtractor,
            shouldKeepInstructions: true
        )
        
        let prompt1 = TestHelpers.createPrompt(content: "Old prompt")
        let prompt2 = TestHelpers.createPrompt(content: "Recent prompt")
        
        let transcript = Transcript(entries: [
            .prompt(prompt1),
            .prompt(prompt2)
        ])
        
        let reducer = StructuredStateReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        // Should have: state entry (with "no information extracted") + 1 recent entry
        #expect(reducedEntries.count == 2)
        
        // State entry should indicate no information was extracted
        let stateEntries = StateExtractionTestHelpers.extractStructuredStateEntries(from: reducedEntries)
        #expect(stateEntries.count == 1)
        
        if let stateText = TranscriptHelpers.extractText(from: stateEntries[0]) {
            #expect(stateText.contains("no information extracted"))
        }
    }
    
    @Test("Formats extracted facts alphabetically by key")
    func formatsExtractedFactsAlphabeticallyByKey() async throws {
        let mockExtractor = StateExtractionTestHelpers.createMockStateExtractor(facts: [
            ExtractedFact(key: "zebra", value: "last"),
            ExtractedFact(key: "apple", value: "first"),
            ExtractedFact(key: "middle", value: "middle")
        ])
        
        let config = StructuredStateConfiguration(
            recentTurnsToKeep: 0,
            stateExtractor: mockExtractor,
            shouldKeepInstructions: false
        )
        
        let prompt = TestHelpers.createPrompt(content: "Test prompt")
        
        let transcript = Transcript(entries: [.prompt(prompt)])
        
        let reducer = StructuredStateReducer(configuration: config)
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        let stateEntries = StateExtractionTestHelpers.extractStructuredStateEntries(from: reducedEntries)
        #expect(stateEntries.count == 1)
        
        if let stateText = TranscriptHelpers.extractText(from: stateEntries[0]) {
            // Check that all facts are present
            #expect(stateText.contains("apple"))
            #expect(stateText.contains("middle"))
            #expect(stateText.contains("zebra"))
            
            // Check alphabetical order by finding positions
            if let applePos = stateText.range(of: "apple")?.lowerBound,
               let middlePos = stateText.range(of: "middle")?.lowerBound,
               let zebraPos = stateText.range(of: "zebra")?.lowerBound {
                #expect(applePos < middlePos)
                #expect(middlePos < zebraPos)
            }
        }
    }
}
