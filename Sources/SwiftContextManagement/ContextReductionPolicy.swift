public enum ContextReductionPolicy: Sendable, Hashable {
    /// Keeps only the most recent N conversation turns (or tokens), discarding all earlier history to stay within the context window.
    case slidingWindow(turns: Int)

    /// Preserves the initial instructions (head) and the most recent turns (tail), dropping the middle part of the conversation.
    case headTailWindow

    /// Replaces older conversation history with a single running summary while keeping recent turns verbatim.
    /// - Parameter configuration: Optional configuration for the rolling summary. If `nil`, uses default configuration.
    case rollingSummary(configuration: RollingSummaryConfiguration? = nil)

    /// Maintains multiple summaries at different granularities (per turn, per topic, global) and selects the appropriate level when reducing context.
    /// - Parameter configuration: Optional configuration for the hierarchical summary. If `nil`, uses default configuration.
    case hierarchicalSummary(configuration: HierarchicalSummaryConfiguration? = nil)

    /// Extracts and stores important facts or constraints in structured fields (slots/ledgers) instead of natural language conversation.
    /// - Parameter configuration: Optional configuration for the structured state extraction. If `nil`, uses default configuration.
    case structuredState(configuration: StructuredStateConfiguration? = nil)

    /// Removes low-importance or low-salience messages, keeping only messages deemed critical to the task.
    case saliencePruning

    /// Retrieves only the most semantically relevant past messages using vector embeddings instead of passing full history.
    case semanticRecall

    /// Segments conversation history by topic and injects only the memory related to the current topic.
    case topicMemory

    /// Rewrites a multi-turn conversational prompt into a single standalone query before processing or retrieval.
    case queryRewriting

    /// Dynamically decides at each turn which parts of history, summaries, or memory to include based on available context budget.
    case dynamicInjection

    /// Uses conversation history selectively and only when it improves retrieval-augmented generation, minimizing unnecessary context usage.
    case dhRAG

    /// Periodically rewrites and refines stored memory itself to prevent accumulation of outdated or redundant information.
    case reflectiveMemory
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .slidingWindow(let turns):
            hasher.combine("slidingWindow")
            hasher.combine(turns)
        case .headTailWindow:
            hasher.combine("headTailWindow")
        case .rollingSummary:
            hasher.combine("rollingSummary")
            // Ignore configuration for hashing
        case .hierarchicalSummary:
            hasher.combine("hierarchicalSummary")
            // Ignore configuration for hashing
        case .structuredState:
            hasher.combine("structuredState")
            // Ignore configuration for hashing
        case .saliencePruning:
            hasher.combine("saliencePruning")
        case .semanticRecall:
            hasher.combine("semanticRecall")
        case .topicMemory:
            hasher.combine("topicMemory")
        case .queryRewriting:
            hasher.combine("queryRewriting")
        case .dynamicInjection:
            hasher.combine("dynamicInjection")
        case .dhRAG:
            hasher.combine("dhRAG")
        case .reflectiveMemory:
            hasher.combine("reflectiveMemory")
        }
    }
    
    public static func == (lhs: ContextReductionPolicy, rhs: ContextReductionPolicy) -> Bool {
        switch (lhs, rhs) {
        case (.slidingWindow(let lhsTurns), .slidingWindow(let rhsTurns)):
            return lhsTurns == rhsTurns
        case (.headTailWindow, .headTailWindow):
            return true
        case (.rollingSummary, .rollingSummary):
            return true // Ignore configuration for equality
        case (.hierarchicalSummary, .hierarchicalSummary):
            return true // Ignore configuration for equality
        case (.structuredState, .structuredState):
            return true // Ignore configuration for equality
        case (.saliencePruning, .saliencePruning):
            return true
        case (.semanticRecall, .semanticRecall):
            return true
        case (.topicMemory, .topicMemory):
            return true
        case (.queryRewriting, .queryRewriting):
            return true
        case (.dynamicInjection, .dynamicInjection):
            return true
        case (.dhRAG, .dhRAG):
            return true
        case (.reflectiveMemory, .reflectiveMemory):
            return true
        default:
            return false
        }
    }
}

public extension ContextReductionPolicy {
    /// Gets a readable name for the policy.
    var name: String {
        switch self {
        case .slidingWindow(let turns):
            return "SlidingWindow(\(turns))"
        case .headTailWindow:
            return "HeadTailWindow"
        case .rollingSummary:
            return "RollingSummary"
        case .hierarchicalSummary:
            return "HierarchicalSummary"
        case .structuredState:
            return "StructuredState"
        case .saliencePruning:
            return "SaliencePruning"
        case .semanticRecall:
            return "SemanticRecall"
        case .topicMemory:
            return "TopicMemory"
        case .queryRewriting:
            return "QueryRewriting"
        case .dynamicInjection:
            return "DynamicInjection"
        case .dhRAG:
            return "dhRAG"
        case .reflectiveMemory:
            return "ReflectiveMemory"
        }
    }
    
    /// Checks if the policy is implemented.
    ///
    /// - Returns: `true` if the policy has a proper implementation, `false` otherwise.
    var isImplemented: Bool {
        switch self {
        case .slidingWindow, .headTailWindow, .rollingSummary, .hierarchicalSummary, .structuredState:
            return true
        case .saliencePruning, .semanticRecall, .topicMemory, .queryRewriting, .dynamicInjection, .dhRAG, .reflectiveMemory:
            return false
        }
    }
}
