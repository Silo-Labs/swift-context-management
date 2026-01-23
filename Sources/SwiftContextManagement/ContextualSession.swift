import FoundationModels

public protocol ContextReductionObserver: AnyObject, Sendable {
    func didReduceContext(from original: Transcript, to reduced: Transcript, using reducer: String)
}

public struct ReductionInfo: Sendable {
    public let originalTranscript: Transcript
    public let reducedTranscript: Transcript
    public let reducerName: String
}

public final class ContextualSession {
    private var session: LanguageModelSession
    private let logLevel: ContextReductionLogLevel
    private let reductionEngine: ContextReductionEngine
    public weak var reductionObserver: (any ContextReductionObserver)?
    
    /// Information about the last reduction that occurred, if any.
    public private(set) var lastReductionInfo: ReductionInfo?
    
    /// The current transcript of the session.
    public var transcript: Transcript {
        session.transcript
    }

    /// Creates a new contextual session.
    ///
    /// - Parameters:
    ///   - session: The underlying language model session.
    ///   - policy: The context reduction policy to use when the context window is exceeded. Defaults to `.slidingWindow(turns: 10)`.
    ///   - logLevel: The level of logging for context reduction operations. Defaults to `.off`.
    public init(
        session: LanguageModelSession,
        policy: ContextReductionPolicy = .slidingWindow(turns: 10),
        logLevel: ContextReductionLogLevel = .off
    ) {
        self.session = session
        self.logLevel = logLevel
        self.reductionEngine = ContextReductionEngine(policy: policy)
    }

    public func respond(to prompt: String) async throws -> LanguageModelSession.Response<String> {
        var attempts = 0
        let maxAttempts = 5
        
        while attempts < maxAttempts {
            do {
                return try await session.respond(to: prompt)
            } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
                attempts += 1
                let original = session.transcript
                
                // Progressively reduce more aggressively with each attempt
                let reduced: Transcript
                if attempts == 1 {
                    // First attempt: use the configured policy
                    reduced = try await reductionEngine.reduce(transcript: original)
                } else {
                    // Subsequent attempts: use progressively more aggressive sliding window
                    let turnsToKeep = max(1, 6 - attempts) // 5, 4, 3, 2, 1 turns
                    let fallbackEngine = ContextReductionEngine(policy: .slidingWindow(turns: turnsToKeep))
                    reduced = try await fallbackEngine.reduce(transcript: original)
                }
                
                // Ensure we actually reduced the size
                if reduced.count >= original.count && !original.isEmpty && attempts < maxAttempts {
                    // Reduction didn't help, force minimal transcript
                    let (_, conversationEntries) = extractInstructionsAndConversations(from: original)
                    let minimalEntries = Array(conversationEntries.suffix(max(1, 5 - attempts)))
                    session = LanguageModelSession(transcript: Transcript(entries: minimalEntries))
                } else {
                    session = LanguageModelSession(transcript: reduced)
                }
                
                let reducerName = attempts == 1 ? reductionEngine.policyName : "AggressiveReduction(attempt \(attempts))"
                
                // Store reduction info for synchronous access
                lastReductionInfo = ReductionInfo(
                    originalTranscript: original,
                    reducedTranscript: session.transcript,
                    reducerName: reducerName
                )
                
                // Notify observer
                reductionObserver?.didReduceContext(
                    from: original,
                    to: session.transcript,
                    using: reducerName
                )
                
                // Log the reduction if logging is enabled (minimal logging only)
                if logLevel == .minimal {
                    ContextReductionLogger.log(
                        original: original,
                        reduced: session.transcript,
                        reducer: reducerName,
                        logLevel: logLevel
                    )
                }
                
                // Retry with reduced transcript
            }
        }
        
        // Should never reach here, but if we do, try one last time with absolute minimum
        let (_, conversationEntries) = extractInstructionsAndConversations(from: session.transcript)
        session = LanguageModelSession(transcript: Transcript(entries: Array(conversationEntries.suffix(1))))
        return try await session.respond(to: prompt)
    }
    
    // Helper to extract instructions and conversations (same as in ContextReducer extension)
    private func extractInstructionsAndConversations(from transcript: Transcript) -> (instructions: [Transcript.Entry], conversations: [Transcript.Entry]) {
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
