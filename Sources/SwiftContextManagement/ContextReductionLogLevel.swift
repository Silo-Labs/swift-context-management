/// Logging level for context reduction operations.
///
/// Controls how much information is logged when context reduction occurs.
public enum ContextReductionLogLevel: Sendable {
    /// No logging is performed.
    case off
    
    /// Logs minimal information: reduction event, entry counts, and estimated token savings.
    case minimal
    
    /// Logs detailed information: full before/after comparison with all entries displayed.
    case verbose
}
