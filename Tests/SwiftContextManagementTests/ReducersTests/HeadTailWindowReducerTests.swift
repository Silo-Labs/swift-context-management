import Testing
import FoundationModels

@testable import SwiftContextManagement

@Suite("Head Tail Window Reducer Tests")
struct HeadTailWindowReducerTests {
    
    @Test("Preserves head instructions and tail turns, drops middle")
    func preservesHeadAndTailDropsMiddle() async throws {
        let systemInstructionsText = "System instructions - Should be kept (head)"
        let turn1PromptText = "Turn 1 prompt - Should be discarded (middle)"
        let turn1ResponseText = "Turn 1 response - Should be discarded (middle)"
        let turn2PromptText = "Turn 2 prompt - Should be discarded (middle)"
        let turn2ResponseText = "Turn 2 response - Should be discarded (middle)"
        let turn3PromptText = "Turn 3 prompt - Should be kept (tail)"
        let turn3ResponseText = "Turn 3 response - Should be kept (tail)"
        
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
        let reducer = HeadTailWindowReducer(tailTurns: 2)
        
        let reducedTranscript = try await reducer.reduce(originalTranscript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 3)
        
        guard case .instructions(let reducedInstructions) = reducedEntries.first else {
            Issue.record("First entry should be instructions (head)")
            return
        }
        TestHelpers.assertEntryContains(.instructions(reducedInstructions), expectedText: systemInstructionsText)
        
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        #expect(conversationEntries.count == 2)
        
        TestHelpers.assertEntriesContain(conversationEntries, expectedTexts: Set([turn3PromptText, turn3ResponseText]))
        TestHelpers.assertEntriesDoNotContain(conversationEntries, unexpectedTexts: Set([turn1PromptText, turn1ResponseText, turn2PromptText, turn2ResponseText]))
    }
    
    @Test("Always preserves instructions regardless of tail turns")
    func alwaysPreservesInstructions() async throws {
        let systemInstructionsText = "System instructions - Should always be kept"
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
        let reducer = HeadTailWindowReducer(tailTurns: 1)
        
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
        TestHelpers.assertEntriesDoNotContain(conversationEntries, unexpectedTexts: Set([olderPromptText]))
    }
    
    @Test("Keeps correct number of tail entries")
    func keepsCorrectNumberOfTailEntries() async throws {
        let systemInstructionsText = "System instructions"
        let turn1PromptText = "Turn 1 prompt - Should be discarded"
        let turn1ResponseText = "Turn 1 response - Should be discarded"
        let turn2PromptText = "Turn 2 prompt - Should be discarded"
        let turn2ResponseText = "Turn 2 response - Should be discarded"
        let turn3PromptText = "Turn 3 prompt - Should be kept (tail)"
        let turn3ResponseText = "Turn 3 response - Should be kept (tail)"
        let turn4PromptText = "Turn 4 prompt - Should be kept (tail)"
        let turn4ResponseText = "Turn 4 response - Should be kept (tail)"
        
        let instructions = TestHelpers.createInstructions(content: systemInstructionsText)
        let turn1Prompt = TestHelpers.createPrompt(content: turn1PromptText)
        let turn1Response = TestHelpers.createResponse(content: turn1ResponseText)
        let turn2Prompt = TestHelpers.createPrompt(content: turn2PromptText)
        let turn2Response = TestHelpers.createResponse(content: turn2ResponseText)
        let turn3Prompt = TestHelpers.createPrompt(content: turn3PromptText)
        let turn3Response = TestHelpers.createResponse(content: turn3ResponseText)
        let turn4Prompt = TestHelpers.createPrompt(content: turn4PromptText)
        let turn4Response = TestHelpers.createResponse(content: turn4ResponseText)
        
        let entries: [Transcript.Entry] = [
            .instructions(instructions),
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
        let reducer = HeadTailWindowReducer(tailTurns: 3)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 4) // 1 instruction + 3 tail entries
        
        guard case .instructions = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        #expect(conversationEntries.count == 3) // 3 tail entries
        
        // tailTurns: 3 means the last 3 conversation entries: turn3 response, turn4 prompt, turn4 response
        TestHelpers.assertEntriesContain(conversationEntries, expectedTexts: Set([
            turn3ResponseText,
            turn4PromptText,
            turn4ResponseText
        ]))
        TestHelpers.assertEntriesDoNotContain(conversationEntries, unexpectedTexts: Set([
            turn1PromptText, turn1ResponseText,
            turn2PromptText, turn2ResponseText,
            turn3PromptText
        ]))
    }
    
    @Test("Handles empty transcript")
    func handlesEmptyTranscript() async throws {
        let transcript = Transcript(entries: [])
        let reducer = HeadTailWindowReducer(tailTurns: 2)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.isEmpty)
    }
    
    @Test("Handles transcript with only instructions")
    func handlesTranscriptWithOnlyInstructions() async throws {
        let systemInstructionsText = "System instructions"
        let instructions = TestHelpers.createInstructions(content: systemInstructionsText)
        let transcript = Transcript(entries: [.instructions(instructions)])
        let reducer = HeadTailWindowReducer(tailTurns: 2)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 1)
        guard case .instructions(let reducedInstructions) = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        TestHelpers.assertEntryContains(.instructions(reducedInstructions), expectedText: systemInstructionsText)
    }
    
    @Test("Handles transcript with only conversation entries")
    func handlesTranscriptWithOnlyConversationEntries() async throws {
        let turn1PromptText = "Turn 1 prompt - Should be discarded"
        let turn1ResponseText = "Turn 1 response - Should be discarded"
        let turn2PromptText = "Turn 2 prompt - Should be kept"
        let turn2ResponseText = "Turn 2 response - Should be kept"
        
        let turn1Prompt = TestHelpers.createPrompt(content: turn1PromptText)
        let turn1Response = TestHelpers.createResponse(content: turn1ResponseText)
        let turn2Prompt = TestHelpers.createPrompt(content: turn2PromptText)
        let turn2Response = TestHelpers.createResponse(content: turn2ResponseText)
        
        let entries: [Transcript.Entry] = [
            .prompt(turn1Prompt),
            .response(turn1Response),
            .prompt(turn2Prompt),
            .response(turn2Response)
        ]
        
        let transcript = Transcript(entries: entries)
        let reducer = HeadTailWindowReducer(tailTurns: 2)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 2)
        
        TestHelpers.assertEntriesContain(reducedEntries, expectedTexts: Set([turn2PromptText, turn2ResponseText]))
        TestHelpers.assertEntriesDoNotContain(reducedEntries, unexpectedTexts: Set([turn1PromptText, turn1ResponseText]))
    }
    
    @Test("Uses default tail turns when not specified")
    func usesDefaultTailTurns() async throws {
        let systemInstructionsText = "System instructions"
        let turn1PromptText = "Turn 1 prompt - Should be discarded"
        let turn1ResponseText = "Turn 1 response - Should be discarded"
        let turn2PromptText = "Turn 2 prompt - Should be kept (default tail)"
        let turn2ResponseText = "Turn 2 response - Should be kept (default tail)"
        
        let instructions = TestHelpers.createInstructions(content: systemInstructionsText)
        let turn1Prompt = TestHelpers.createPrompt(content: turn1PromptText)
        let turn1Response = TestHelpers.createResponse(content: turn1ResponseText)
        let turn2Prompt = TestHelpers.createPrompt(content: turn2PromptText)
        let turn2Response = TestHelpers.createResponse(content: turn2ResponseText)
        
        let entries: [Transcript.Entry] = [
            .instructions(instructions),
            .prompt(turn1Prompt),
            .response(turn1Response),
            .prompt(turn2Prompt),
            .response(turn2Response)
        ]
        
        let transcript = Transcript(entries: entries)
        let reducer = HeadTailWindowReducer() // Uses default tailTurns: 2
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 3) // 1 instruction + 2 tail entries
        
        guard case .instructions = reducedEntries.first else {
            Issue.record("First entry should be instructions")
            return
        }
        
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        #expect(conversationEntries.count == 2)
        
        TestHelpers.assertEntriesContain(conversationEntries, expectedTexts: Set([turn2PromptText, turn2ResponseText]))
        TestHelpers.assertEntriesDoNotContain(conversationEntries, unexpectedTexts: Set([turn1PromptText, turn1ResponseText]))
    }
    
    @Test("Preserves multiple instruction entries in head")
    func preservesMultipleInstructionEntries() async throws {
        let instructions1Text = "First system instructions"
        let instructions2Text = "Second system instructions"
        let turn1PromptText = "Turn 1 prompt - Should be discarded"
        let turn1ResponseText = "Turn 1 response - Should be discarded"
        let turn2PromptText = "Turn 2 prompt - Should be kept"
        let turn2ResponseText = "Turn 2 response - Should be kept"
        
        let instructions1 = TestHelpers.createInstructions(content: instructions1Text)
        let instructions2 = TestHelpers.createInstructions(content: instructions2Text)
        let turn1Prompt = TestHelpers.createPrompt(content: turn1PromptText)
        let turn1Response = TestHelpers.createResponse(content: turn1ResponseText)
        let turn2Prompt = TestHelpers.createPrompt(content: turn2PromptText)
        let turn2Response = TestHelpers.createResponse(content: turn2ResponseText)
        
        let entries: [Transcript.Entry] = [
            .instructions(instructions1),
            .instructions(instructions2),
            .prompt(turn1Prompt),
            .response(turn1Response),
            .prompt(turn2Prompt),
            .response(turn2Response)
        ]
        
        let transcript = Transcript(entries: entries)
        let reducer = HeadTailWindowReducer(tailTurns: 2)
        
        let reducedTranscript = try await reducer.reduce(transcript)
        let reducedEntries = Array(reducedTranscript)
        
        #expect(reducedEntries.count == 4) // 2 instructions + 2 tail entries
        
        let instructionEntries = reducedEntries.filter {
            if case .instructions = $0 { return true }
            return false
        }
        #expect(instructionEntries.count == 2)
        
        let conversationEntries = TestHelpers.extractConversationEntries(from: reducedEntries)
        #expect(conversationEntries.count == 2)
        
        TestHelpers.assertEntriesContain(conversationEntries, expectedTexts: Set([turn2PromptText, turn2ResponseText]))
        TestHelpers.assertEntriesDoNotContain(conversationEntries, unexpectedTexts: Set([turn1PromptText, turn1ResponseText]))
    }
}
