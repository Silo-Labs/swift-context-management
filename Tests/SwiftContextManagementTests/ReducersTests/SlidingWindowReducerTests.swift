import Testing
import FoundationModels

@testable import SwiftContextManagement

@Suite("Sliding Window Reducer Tests")
struct SlidingWindowReducerTests {
    
    @Test("Reduces transcript keeping only recent turns")
    func reducesTranscriptKeepingRecentTurns() async throws {
        let systemInstructionsText = "System instructions"
        let turn1PromptText = "Turn 1 - Should be discarded"
        let turn1ResponseText = "Turn 1 response - Should be discarded"
        let turn2PromptText = "Turn 2 - Should be discarded"
        let turn2ResponseText = "Turn 2 response - Should be discarded"
        let turn3PromptText = "Turn 3 - Should be kept"
        let turn3ResponseText = "Turn 3 response - Should be kept"
        
        let instructions = TestHelpers.createInstructions(content: systemInstructionsText)
        let turn1Prompt = TestHelpers.createPrompt(content: turn1PromptText)
        let turn1Response = TestHelpers.createResponse(content: turn1ResponseText)
        let turn2Prompt = TestHelpers.createPrompt(content: turn2PromptText)
        let turn2Response = TestHelpers.createResponse(content: turn2ResponseText)
        let turn3Prompt = TestHelpers.createPrompt(content: turn3PromptText)
        let turn3Response = TestHelpers.createResponse(content: turn3ResponseText)
        
        let originalEntries: [Transcript.Entry] = [
            .instructions(instructions),
            .prompt(turn1Prompt),
            .response(turn1Response),
            .prompt(turn2Prompt),
            .response(turn2Response),
            .prompt(turn3Prompt),
            .response(turn3Response)
        ]
        
        let originalTranscript = Transcript(entries: originalEntries)
        let reducer = SlidingWindowReducer(turns: 2, shouldKeepInstructions: true)
        
        let reducedTranscript = try await reducer.reduce(originalTranscript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 3)
        
        guard case .instructions(let reducedInstructions) = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        TestHelpers.assertEntryContains(.instructions(reducedInstructions), expectedText: systemInstructionsText)
        
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        #expect(conversationEntries.count == 2)
        
        TestHelpers.assertEntriesContain(conversationEntries, expectedTexts: [turn3PromptText, turn3ResponseText])
        TestHelpers.assertEntriesDoNotContain(conversationEntries, unexpectedTexts: [turn1PromptText, turn1ResponseText, turn2PromptText, turn2ResponseText])
    }
    
    @Test("Keeps instructions when shouldKeepInstructions is true")
    func keepsInstructionsWhenEnabled() async throws {
        let systemInstructionsText = "System instructions"
        let olderPromptText = "Older prompt - Should be discarded"
        let mostRecentResponseText = "Most recent response - Should be kept"
        
        let instructions = TestHelpers.createInstructions(content: systemInstructionsText)
        let olderPrompt = TestHelpers.createPrompt(content: olderPromptText)
        let mostRecentResponse = TestHelpers.createResponse(content: mostRecentResponseText)
        
        let entries: [Transcript.Entry] = [
            .instructions(instructions),
            .prompt(olderPrompt),
            .response(mostRecentResponse)
        ]
        
        let transcript = Transcript(entries: entries)
        let reducer = SlidingWindowReducer(turns: 1, shouldKeepInstructions: true)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 2)
        
        let instructionEntry = reducedEntries.first { 
            if case .instructions = $0 { return true }
            return false
        }
        #expect(instructionEntry != nil)
        if let instructionEntry = instructionEntry {
            TestHelpers.assertEntryContains(instructionEntry, expectedText: systemInstructionsText)
        }
        
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        #expect(conversationEntries.count == 1)
        TestHelpers.assertEntryContains(conversationEntries[0], expectedText: mostRecentResponseText)
        TestHelpers.assertEntriesDoNotContain(conversationEntries, unexpectedTexts: [olderPromptText])
    }
    
    @Test("Discards instructions when shouldKeepInstructions is false")
    func discardsInstructionsWhenDisabled() async throws {
        let systemInstructionsText = "System instructions - Should be discarded"
        let conversationPromptText = "Conversation prompt - Should be kept"
        let conversationResponseText = "Conversation response - Should be kept"
        
        let instructions = TestHelpers.createInstructions(content: systemInstructionsText)
        let prompt = TestHelpers.createPrompt(content: conversationPromptText)
        let response = TestHelpers.createResponse(content: conversationResponseText)
        
        let entries: [Transcript.Entry] = [
            .instructions(instructions),
            .prompt(prompt),
            .response(response)
        ]
        
        let transcript = Transcript(entries: entries)
        let reducer = SlidingWindowReducer(turns: 2, shouldKeepInstructions: false)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(!reducedEntries.contains {
            if case .instructions = $0 { return true }
            return false
        })
        
        #expect(reducedEntries.count == 2)
        TestHelpers.assertEntriesContain(reducedEntries, expectedTexts: [conversationPromptText, conversationResponseText])
        TestHelpers.assertEntriesDoNotContain(reducedEntries, unexpectedTexts: [systemInstructionsText])
    }
    
    @Test("Handles empty transcript")
    func handlesEmptyTranscript() async throws {
        let transcript = Transcript(entries: [])
        let reducer = SlidingWindowReducer(turns: 5, shouldKeepInstructions: true)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.isEmpty)
    }
    
    @Test("Handles transcript with only instructions")
    func handlesTranscriptWithOnlyInstructions() async throws {
        let systemInstructionsText = "System instructions"
        let instructions = TestHelpers.createInstructions(content: systemInstructionsText)
        let transcript = Transcript(entries: [.instructions(instructions)])
        let reducer = SlidingWindowReducer(turns: 5, shouldKeepInstructions: true)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 1)
        guard case .instructions(let reducedInstructions) = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        TestHelpers.assertEntryContains(.instructions(reducedInstructions), expectedText: systemInstructionsText)
    }
    
    @Test("Keeps correct number of recent turns")
    func keepsCorrectNumberOfRecentTurns() async throws {
        let turn1PromptText = "Turn 1 prompt - Should be discarded"
        let turn1ResponseText = "Turn 1 response - Should be discarded"
        let turn2PromptText = "Turn 2 prompt - Should be discarded"
        let turn2ResponseText = "Turn 2 response - Should be discarded"
        let turn3PromptText = "Turn 3 prompt - May be kept"
        let turn3ResponseText = "Turn 3 response - May be kept"
        let turn4PromptText = "Turn 4 prompt - Should be kept"
        let turn4ResponseText = "Turn 4 response - Should be kept"
        
        let turn1Prompt = TestHelpers.createPrompt(content: turn1PromptText)
        let turn1Response = TestHelpers.createResponse(content: turn1ResponseText)
        let turn2Prompt = TestHelpers.createPrompt(content: turn2PromptText)
        let turn2Response = TestHelpers.createResponse(content: turn2ResponseText)
        let turn3Prompt = TestHelpers.createPrompt(content: turn3PromptText)
        let turn3Response = TestHelpers.createResponse(content: turn3ResponseText)
        let turn4Prompt = TestHelpers.createPrompt(content: turn4PromptText)
        let turn4Response = TestHelpers.createResponse(content: turn4ResponseText)
        
        let entries: [Transcript.Entry] = [
            .prompt(turn1Prompt),
            .response(turn1Response),
            .prompt(turn2Prompt),
            .response(turn2Response),
            .prompt(turn3Prompt),
            .response(turn3Response),
            .prompt(turn4Prompt),
            .response(turn4Response)
        ]
        
        let transcript = Transcript(entries: entries)
        let reducer = SlidingWindowReducer(turns: 3, shouldKeepInstructions: false)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 3)
        
        let entryTexts = Set(reducedEntries.compactMap { TranscriptHelpers.extractText(from: $0) })
        #expect(entryTexts.contains(turn4PromptText))
        #expect(entryTexts.contains(turn4ResponseText))
        
        TestHelpers.assertEntriesDoNotContain(reducedEntries, unexpectedTexts: [turn1PromptText, turn1ResponseText, turn2PromptText, turn2ResponseText])
        
        if let lastEntry = reducedEntries.last {
            TestHelpers.assertEntryContains(lastEntry, expectedText: turn4ResponseText)
        }
    }
}
