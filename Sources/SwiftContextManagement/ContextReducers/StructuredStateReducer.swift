import FoundationModels

struct StructuredStateReducer: ContextReducer {
    private let configuration: StructuredStateConfiguration

    init(configuration: StructuredStateConfiguration = StructuredStateConfiguration()) {
        self.configuration = configuration
    }

    func reduce(_ transcript: Transcript) async throws -> Transcript {
        var newEntries: [Transcript.Entry] = []

        let (instructionEntries, conversationEntries) = extractInstructionsAndConversations(from: transcript)

        if configuration.shouldKeepInstructions {
            newEntries.append(contentsOf: instructionEntries)
        }

        let entriesToExtract = conversationEntries.dropLast(configuration.recentTurnsToKeep)
        let recentEntries = Array(conversationEntries.suffix(configuration.recentTurnsToKeep))

        if !entriesToExtract.isEmpty {
            let structuredState = try await configuration.stateExtractor.extractState(
                from: Array(entriesToExtract)
            )

            let stateText = formatStructuredState(structuredState)

            let statePrompt = Transcript.Prompt(
                segments: [
                    .text(
                        Transcript.TextSegment(
                            content: """
                            Structured state extracted from previous conversation:
                            
                            \(stateText)
                            """
                        )
                    )
                ]
            )

            newEntries.append(.prompt(statePrompt))
        }

        newEntries.append(contentsOf: recentEntries)

        return Transcript(entries: newEntries)
    }
}

private extension StructuredStateReducer {
    func formatStructuredState(_ state: StructuredState) -> String {
        guard !state.information.isEmpty else {
            return "(no information extracted)"
        }

        return state.information
            .sorted(by: { $0.key < $1.key })
            .map { "  - \($0.key): \($0.value)" }
            .joined(separator: "\n")
    }
}
