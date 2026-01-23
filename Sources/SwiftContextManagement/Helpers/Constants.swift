enum Constants {
    /// The maximum number of tokens that fit in the FoundationModels context window.
    static let contextWindowLimit: Int = 4096
    
    /// Safe content token limit with margin for prompt overhead and response.
    /// This is `contextWindowLimit` minus a 500 token safety margin.
    static let safeContentTokenLimit: Int = 3600
}
