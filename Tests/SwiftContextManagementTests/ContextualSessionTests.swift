import Testing
import FoundationModels

@testable import SwiftContextManagement

@Suite("Contextual Session Tests")
struct ContextualSessionTests {
    @Test("Successful Response")
    func successfulResponse() async throws {
        let session = LanguageModelSession()
        let contextualSession = ContextualSession(session: session)
        
        let prompt = "What is Swift?"
        let response = try await contextualSession.respond(to: prompt)
        
        #expect(!response.content.isEmpty)
    }
}
