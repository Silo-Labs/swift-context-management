/// Represents different granularity levels for hierarchical summarization.
public enum SummaryGranularity: Sendable {
    /// Per-turn summarization: each conversation turn is summarized individually.
    case perTurn

    /// Per-topic summarization: entries are grouped by topic and summarized.
    case perTopic

    /// Global summarization: all entries are summarized together.
    case global

    /// A human-readable description of the granularity level.
    var description: String {
        switch self {
        case .perTurn:
            return "Per-Turn"
        case .perTopic:
            return "Per-Topic"
        case .global:
            return "Global"
        }
    }
}
