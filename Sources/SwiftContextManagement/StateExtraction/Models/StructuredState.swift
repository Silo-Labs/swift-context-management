import FoundationModels

@Generable
public struct ExtractedFact: Sendable {
    @Guide(description: "The key or name of this piece of information (e.g., 'name', 'date', 'constraint_quiet_table')")
    public let key: String

    @Guide(description: "The value of this piece of information")
    public let value: String
}

@Generable
public struct StructuredState: Sendable {
    @Guide(description: "Extract all important information as key-value pairs. Use descriptive keys that indicate the type of information.")
    public let information: [ExtractedFact]
}
