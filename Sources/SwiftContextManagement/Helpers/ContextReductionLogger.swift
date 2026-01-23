import FoundationModels
import OSLog

/// Helper for logging context reduction operations.
enum ContextReductionLogger {
    private static let logger = Logger(subsystem: "SwiftContextManagement", category: "ContextReduction")
    
    /// Logs a context reduction event based on the specified log level.
    ///
    /// - Parameters:
    ///   - original: The original transcript before reduction.
    ///   - reduced: The transcript after reduction.
    ///   - reducer: The name of the reducer that performed the reduction.
    ///   - logLevel: The level of detail to log.
    static func log(
        original: Transcript,
        reduced: Transcript,
        reducer: String,
        logLevel: ContextReductionLogLevel
    ) {
        guard logLevel != .off else {
            return
        }

        let originalCount = original.count
        let reducedCount = reduced.count
        let originalChars = original.characterCount()
        let reducedChars = reduced.characterCount()
        let savedChars = originalChars - reducedChars
        let originalTokens = original.estimatedTokenCount()
        let reducedTokens = reduced.estimatedTokenCount()
        let savedTokens = originalTokens - reducedTokens
        
        switch logLevel {
        case .off:
            break
        case .minimal:
            let message = """
            🔄 Context Reduction (\(reducer)):
               Entries: \(originalCount) → \(reducedCount) (\(originalCount - reducedCount) removed)
               Characters: \(originalChars) → \(reducedChars) (~\(savedChars) saved)
               Estimated Tokens: ~\(originalTokens) → ~\(reducedTokens) (~\(savedTokens) saved)
            """
            logger.info("\(message)")
        case .verbose:
            // Verbose mode: Just log minimal info, detailed comparison shown in UI
            let message = """
            🔄 Context Reduction (\(reducer)):
               Entries: \(originalCount) → \(reducedCount) (\(originalCount - reducedCount) removed)
               Characters: \(originalChars) → \(reducedChars) (~\(savedChars) saved)
               Estimated Tokens: ~\(originalTokens) → ~\(reducedTokens) (~\(savedTokens) saved)
            """
            logger.info("\(message)")
        }
    }
}

private extension String {
    func repeating(count: Int) -> String {
        String(repeating: self, count: count)
    }
    
    func padding(toLength length: Int, withPad pad: String, startingAt index: Int) -> String {
        let currentLength = self.count
        if currentLength >= length {
            return String(self.prefix(length))
        }
        return self + String(repeating: pad, count: length - currentLength)
    }
}
