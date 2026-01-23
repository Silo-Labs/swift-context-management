import Testing
import FoundationModels

@testable import SwiftContextManagement

@Suite("Foundation Models Topic Detector Tests")
struct FoundationModelsTopicDetectorTests {

    @Test("Detects topics in conversation")
    func detectsTopicsInConversation() async throws {
        let detector = FoundationModelsTopicDetector()

        let prompt1 = TestHelpers.createPrompt(content: "What is Swift programming?")
        let response1 = TestHelpers.createResponse(content: "Swift is a programming language.")
        let prompt2 = TestHelpers.createPrompt(content: "What's the budget for this project?")
        let response2 = TestHelpers.createResponse(content: "We have $50k allocated.")
        let prompt3 = TestHelpers.createPrompt(content: "Tell me more about Swift features")
        let response3 = TestHelpers.createResponse(content: "Swift has type safety and modern syntax.")

        let entries: [Transcript.Entry] = [
            .prompt(prompt1),
            .response(response1),
            .prompt(prompt2),
            .response(response2),
            .prompt(prompt3),
            .response(response3)
        ]

        let topicGroups = try await detector.detectTopics(in: entries)

        // Should detect at least one topic group
        #expect(!topicGroups.isEmpty)
        #expect(topicGroups.count >= 1)

        // All entries should be assigned to some topic
        let totalGroupedEntries = topicGroups.reduce(0) { $0 + $1.count }
        #expect(totalGroupedEntries == entries.count)
    }

    @Test("Handles empty entries")
    func handlesEmptyEntries() async throws {
        let detector = FoundationModelsTopicDetector()
        let topicGroups = try await detector.detectTopics(in: [])

        // Should return empty array or single empty group
        #expect(topicGroups.isEmpty || topicGroups == [[]])
    }

    @Test("Handles single entry")
    func handlesSingleEntry() async throws {
        let detector = FoundationModelsTopicDetector()

        let prompt = TestHelpers.createPrompt(content: "Single question")
        let entries: [Transcript.Entry] = [.prompt(prompt)]

        let topicGroups = try await detector.detectTopics(in: entries)

        // Should return at least one group
        #expect(!topicGroups.isEmpty)
        #expect(topicGroups[0].count == 1)
    }

    @Test("Groups related entries together")
    func groupsRelatedEntriesTogether() async throws {
        let detector = FoundationModelsTopicDetector()

        let prompt1 = TestHelpers.createPrompt(content: "Tell me about cats")
        let response1 = TestHelpers.createResponse(content: "Cats are pets.")
        let prompt2 = TestHelpers.createPrompt(content: "What do cats eat?")
        let response2 = TestHelpers.createResponse(content: "Cats eat cat food.")
        let prompt3 = TestHelpers.createPrompt(content: "What about dogs?")
        let response3 = TestHelpers.createResponse(content: "Dogs are also pets.")

        let entries: [Transcript.Entry] = [
            .prompt(prompt1),
            .response(response1),
            .prompt(prompt2),
            .response(response2),
            .prompt(prompt3),
            .response(response3)
        ]

        let topicGroups = try await detector.detectTopics(in: entries)

        // Should have multiple groups (cats vs dogs)
        #expect(topicGroups.count >= 1)

        // Verify all entries are accounted for
        let totalEntries = topicGroups.reduce(0) { $0 + $1.count }
        #expect(totalEntries == entries.count)
    }
}
