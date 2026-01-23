import FoundationModels

protocol ContextReducer: Sendable {
    func reduce(_ transcript: Transcript) async throws -> Transcript
}

extension ContextReducer {
    func extractInstructionsAndConversations(from transcript: Transcript) -> (instructions: [Transcript.Entry], conversations: [Transcript.Entry]) {
        var instructions: [Transcript.Entry] = []
        var conversations: [Transcript.Entry] = []
        
        for index in transcript.indices {
            let entry = transcript[index]
            if case .instructions = entry {
                instructions.append(entry)
            } else {
                conversations.append(entry)
            }
        }
        
        return (instructions, conversations)
    }
}