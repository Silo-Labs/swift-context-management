import FoundationModels

public struct FoundationModelsStateExtractor: StateExtractor {
    public init() {}

    /// Extracts structured state from conversation entries.
    ///
    /// Uses a reactive approach: tries to extract state directly, and if the context window
    /// is exceeded, automatically splits the entries and retries recursively.
    ///
    /// - Parameter entries: The conversation entries to extract state from.
    /// - Returns: A structured state containing extracted information.
    /// - Throws: An error if state extraction fails.
    public func extractState(from entries: [Transcript.Entry]) async throws -> StructuredState {
        guard !entries.isEmpty else {
            return StructuredState(information: [])
        }
        
        return try await extractStateWithRetry(entries: entries)
    }
}

private extension FoundationModelsStateExtractor {
    /// Attempts to extract state, automatically splitting if context window is exceeded.
    ///
    /// - Parameter entries: The entries to extract state from.
    /// - Returns: A structured state.
    func extractStateWithRetry(entries: [Transcript.Entry]) async throws -> StructuredState {
        do {
            return try await extractStateDirectly(entries: entries)
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error {
                return try await extractStateInParts(entries: entries)
            }
            throw error
        }
    }
    
    /// Extracts state directly in a single LLM call.
    func extractStateDirectly(entries: [Transcript.Entry]) async throws -> StructuredState {
        let conversationText = entries.enumerated().map { index, entry in
            if let text = TranscriptHelpers.extractText(from: entry) {
                return "[Entry \(index)]: \(text)"
            }
            return "[Entry \(index)]: (non-text entry)"
        }.joined(separator: "\n\n")

        let extractionPrompt = """
        Analyze the following conversation and extract all important information as key-value pairs.
        
        Use descriptive keys that indicate the type of information:
        - For facts: use simple keys like "name", "date", "time", "preference", "quantity"
        - For constraints: prefix with "constraint_" (e.g., "constraint_quiet_table", "constraint_gluten_free")
        - For decisions: prefix with "decision_" (e.g., "decision_reservation_time", "decision_api_version")
        - For other important info: use descriptive keys
        
        Be concise but complete. Only include information that would be useful for future conversation turns.
        
        Conversation:
        \(conversationText)
        """

        let session = LanguageModelSession()
        let response = try await session.respond(
            to: extractionPrompt,
            generating: StructuredState.self
        )
        return response.content
    }
    
    /// Splits entries into parts, extracts state from each part, then combines the results.
    func extractStateInParts(entries: [Transcript.Entry]) async throws -> StructuredState {
        guard entries.count > 1 {
            return try await extractStateFromSingleEntry(entries[0])
        }
        
        let midpoint = entries.count / 2
        let firstHalf = Array(entries.prefix(midpoint))
        let secondHalf = Array(entries.suffix(from: midpoint))
        
        let firstState = try await extractStateWithRetry(entries: firstHalf)
        let secondState = try await extractStateWithRetry(entries: secondHalf)
        
        return combineStates([firstState, secondState])
    }
    
    /// Handles a single entry that is too large by extracting from its text.
    func extractStateFromSingleEntry(_ entry: Transcript.Entry) async throws -> StructuredState {
        guard let text = TranscriptHelpers.extractText(from: entry) else {
            return StructuredState(information: [])
        }
        
        let midpoint = text.count / 2
        let firstHalfText = String(text.prefix(midpoint))
        let secondHalfText = String(text.suffix(from: text.index(text.startIndex, offsetBy: midpoint)))
        
        let firstHalfEntry = Transcript.Entry.prompt(Transcript.Prompt(
            segments: [.text(Transcript.TextSegment(content: firstHalfText))]
        ))
        let secondHalfEntry = Transcript.Entry.prompt(Transcript.Prompt(
            segments: [.text(Transcript.TextSegment(content: secondHalfText))]
        ))
        
        let firstState = try await extractStateWithRetry(entries: [firstHalfEntry])
        let secondState = try await extractStateWithRetry(entries: [secondHalfEntry])
        
        return combineStates([firstState, secondState])
    }
    
    /// Combines multiple structured states into a single state.
    func combineStates(_ states: [StructuredState]) -> StructuredState {
        var combinedFacts: [ExtractedFact] = []
        var seenKeys: Set<String> = []
        
        for state in states {
            for fact in state.information {
                if !seenKeys.contains(fact.key) {
                    combinedFacts.append(fact)
                    seenKeys.insert(fact.key)
                } else {
                    if let existingIndex = combinedFacts.firstIndex(where: { $0.key == fact.key }) {
                        let existingFact = combinedFacts[existingIndex]
                        if existingFact.value != fact.value {
                            let combinedValue = "\(existingFact.value); \(fact.value)"
                            combinedFacts[existingIndex] = ExtractedFact(
                                key: fact.key,
                                value: combinedValue
                            )
                        }
                    }
                }
            }
        }
        
        return StructuredState(information: combinedFacts)
    }
}
