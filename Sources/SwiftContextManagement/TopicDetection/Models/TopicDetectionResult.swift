import FoundationModels

@Generable
public struct TopicDetectionResult {
    @Guide(description: "The topic of the entries")
    public let topic: String

    @Guide(description: "The indices of the entries that are related to the topic")
    public let entryIndices: [Int]
}
