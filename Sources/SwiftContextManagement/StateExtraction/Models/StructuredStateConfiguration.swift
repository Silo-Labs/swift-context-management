import Foundation

public struct StructuredStateConfiguration: Sendable {
    /// Number of most recent conversation entries to keep verbatim (not reduced into state).
    public let recentTurnsToKeep: Int

    /// The extractor used to build `StructuredState` from older conversation.
    public let stateExtractor: any StateExtractor

    /// Optional extra instructions to guide extraction (e.g. domain-specific hints).
    public let extractionInstructions: String?

    /// Locale, in case you want locale-specific behavior in prompts later.
    public let locale: Locale

    /// Whether to preserve instruction entries at the beginning of the transcript.
    public let shouldKeepInstructions: Bool

    public init(
        recentTurnsToKeep: Int = 2,
        stateExtractor: (any StateExtractor)? = nil,
        extractionInstructions: String? = nil,
        locale: Locale = .enUS,
        shouldKeepInstructions: Bool = true
    ) {
        self.recentTurnsToKeep = recentTurnsToKeep
        self.stateExtractor = stateExtractor ?? FoundationModelsStateExtractor()
        self.extractionInstructions = extractionInstructions
        self.locale = locale
        self.shouldKeepInstructions = shouldKeepInstructions
    }
}
