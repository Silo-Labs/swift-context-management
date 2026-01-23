import FoundationModels

/// Engine that performs context reduction based on a specified policy.
public struct ContextReductionEngine: Sendable {
    private let policy: ContextReductionPolicy
    
    /// Creates a context reduction engine with the specified policy.
    ///
    /// - Parameter policy: The reduction policy to use when reducing context.
    public init(policy: ContextReductionPolicy) {
        self.policy = policy
    }
    
    /// Reduces the transcript according to the configured policy.
    ///
    /// - Parameters:
    ///   - transcript: The transcript to reduce.
    /// - Returns: A reduced transcript that fits within the context window.
    /// - Throws: An error if reduction fails (e.g., summarization errors).
    public func reduce(
        transcript: Transcript,
    ) async throws -> Transcript {
        let reducer = createReducer(for: policy)
        return try await reducer.reduce(transcript)
    }
    
    /// Gets the name of the policy being used.
    ///
    /// - Returns: A string describing the policy name.
    public var policyName: String {
        policy.name
    }
    
    /// Checks if the policy is implemented.
    ///
    /// - Returns: `true` if the policy has a proper implementation, `false` otherwise.
    public var isPolicyImplemented: Bool {
        policy.isImplemented
    }
}

// MARK: - Private Helpers

private extension ContextReductionEngine {
    /// Creates the appropriate reducer for the given policy.
    ///
    /// - Parameter policy: The reduction policy.
    /// - Returns: A reducer that implements the policy.
    func createReducer(for policy: ContextReductionPolicy) -> ContextReducer {
        switch policy {
        case .slidingWindow(let turns):
            return SlidingWindowReducer(turns: turns)
            
        case .headTailWindow:
            return HeadTailWindowReducer()
            
        case .rollingSummary(let configuration):
            if let config = configuration {
                return RollingSummaryReducer(configuration: config)
            } else {
                return RollingSummaryReducer()
            }
            
        case .hierarchicalSummary(let configuration):
            if let config = configuration {
                return HierarchicalSummaryReducer(configuration: config)
            } else {
                return HierarchicalSummaryReducer()
            }
            
        case .structuredState(let configuration):
            if let config = configuration {
                return StructuredStateReducer(configuration: config)
            } else {
                return StructuredStateReducer()
            }
            
        case .saliencePruning, .semanticRecall, .topicMemory, .queryRewriting, .dynamicInjection, .dhRAG, .reflectiveMemory:
            // Return a no-op reducer for unimplemented policies
            // TODO: Implement these policies
            return NoOpReducer()
        }
    }
}
