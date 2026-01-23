import SwiftUI
import SwiftContextManagement
import FoundationModels

@MainActor
@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var currentInput: String = ""
    var isProcessing: Bool = false
    var reductionPolicy: ContextReductionPolicy = .slidingWindow(turns: 10) {
        didSet {
            if oldValue != reductionPolicy {
                needsRestart = true
            }
        }
    }
    // Always use verbose log level
    private let logLevel: ContextReductionLogLevel = .verbose
    var currentTranscript: Transcript?
    var originalEntryCount: Int = 0
    var needsRestart: Bool = false
    
    // Track reduction events for verbose display
    var lastReductionEvent: ReductionEvent?
    
    // Track any reduction errors
    var lastReductionError: String?
    
    struct ReductionEvent {
        let original: Transcript
        let reduced: Transcript
        let reducerName: String
        let timestamp: Date
    }
    
    private var contextualSession: ContextualSession?
    private let reductionObserver = ReductionObserver()
    
    private final class ReductionObserver: ContextReductionObserver, @unchecked Sendable {
        weak var viewModel: ChatViewModel?
        
        nonisolated func didReduceContext(from original: Transcript, to reduced: Transcript, using reducer: String) {
            Task { @MainActor in
                self.viewModel?.lastReductionEvent = ChatViewModel.ReductionEvent(
                    original: original,
                    reduced: reduced,
                    reducerName: reducer,
                    timestamp: Date()
                )
                // Force UI update
                self.viewModel?.updateTranscriptView()
            }
        }
    }
    
    init() {
        setupSession()
    }
    
    func setupSession() {
        let session = LanguageModelSession()
        let newSession = ContextualSession(
            session: session,
            policy: reductionPolicy,
            logLevel: logLevel
        )
        reductionObserver.viewModel = self
        newSession.reductionObserver = reductionObserver
        contextualSession = newSession
        updateTranscriptView()
        needsRestart = false
        lastReductionEvent = nil // Clear previous reduction events
        lastReductionError = nil // Clear previous errors
    }
    
    func restartSession() {
        messages.removeAll()
        setupSession()
    }
    
    func clearChat() {
        messages.removeAll()
        setupSession()
    }
    
    func loadPreset(_ preset: MockConversationPreset) async {
        // Clear any previous state first
        messages = preset.messages.map { ChatMessage(role: $0.role, content: $0.content) }
        contextualSession = nil // Explicitly clear previous session
        lastReductionEvent = nil
        lastReductionError = nil
        
        // Since the mock presets exceed the context window, proactively trigger reduction
        // This will apply the selected reducer policy immediately when loading the preset
        isProcessing = true
        
        do {
            // Create a reduction engine with the current policy
            let reductionEngine = ContextReductionEngine(policy: reductionPolicy)
            
            // Reduce the preset transcript directly
            let originalTranscript = preset.transcript
            let reducedTranscript = try await reductionEngine.reduce(transcript: originalTranscript)
            
            // Create a completely new session with the reduced transcript
            // This ensures we're not reusing any state from previous sessions
            let newLanguageModelSession = LanguageModelSession(transcript: reducedTranscript)
            let newContextualSession = ContextualSession(
                session: newLanguageModelSession,
                policy: reductionPolicy,
                logLevel: logLevel
            )
            
            // Set up observer for the new session
            reductionObserver.viewModel = self
            newContextualSession.reductionObserver = reductionObserver
            
            // Assign the new session (replacing any previous one)
            contextualSession = newContextualSession
            
            // Store reduction event for display
            lastReductionEvent = ReductionEvent(
                original: originalTranscript,
                reduced: reducedTranscript,
                reducerName: reductionEngine.policyName,
                timestamp: Date()
            )
            
            // Notify observer
            reductionObserver.didReduceContext(
                from: originalTranscript,
                to: reducedTranscript,
                using: reductionEngine.policyName
            )
            
            updateTranscriptView()
        } catch {
            // If reduction fails, fall back to original transcript
            lastReductionError = error.localizedDescription
            
            // Create a completely new session with the original transcript
            let newLanguageModelSession = LanguageModelSession(transcript: preset.transcript)
            let newContextualSession = ContextualSession(
                session: newLanguageModelSession,
                policy: reductionPolicy,
                logLevel: logLevel
            )
            
            // Set up observer for the new session
            reductionObserver.viewModel = self
            newContextualSession.reductionObserver = reductionObserver
            
            // Assign the new session (replacing any previous one)
            contextualSession = newContextualSession
            
            updateTranscriptView()
        }
        
        isProcessing = false
        needsRestart = false
    }
    
    
    func updateTranscriptView() {
        currentTranscript = contextualSession?.transcript
        originalEntryCount = contextualSession?.transcript.count ?? 0
    }
    
    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isProcessing else { return }
        
        let userMessage = currentInput
        currentInput = ""
        isProcessing = true
        
        // Add user message to UI
        messages.append(ChatMessage(role: .user, content: userMessage))
        
        do {
            guard let session = contextualSession else {
                throw NSError(domain: "ChatViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
            }
            
            // Get response (reduction may happen here if context window is exceeded)
            let response = try await session.respond(to: userMessage)
            
            // Add assistant response to UI
            messages.append(ChatMessage(role: .assistant, content: response.content))
            
            // Check if reduction occurred and update the event
            // This ensures the event is set even if the observer callback didn't fire
            if let reductionInfo = session.lastReductionInfo {
                lastReductionEvent = ReductionEvent(
                    original: reductionInfo.originalTranscript,
                    reduced: reductionInfo.reducedTranscript,
                    reducerName: reductionInfo.reducerName,
                    timestamp: Date()
                )
            }
            
            // Update transcript view
            updateTranscriptView()
            
        } catch {
            // Filter out context window errors - these should be handled automatically
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("context window") || 
               errorDescription.contains("exceeded") {
                // Context window errors should be handled by ContextualSession
                // If we're seeing this, it means reduction failed completely
                // Try one more time with a fresh minimal session
                do {
                    // Create a minimal session with just the current prompt
                    let minimalPrompt = Transcript.Prompt(
                        segments: [.text(Transcript.TextSegment(content: userMessage))]
                    )
                    let minimalSession = LanguageModelSession(
                        transcript: Transcript(entries: [.prompt(minimalPrompt)])
                    )
                    let minimalContextualSession = ContextualSession(
                        session: minimalSession,
                        policy: reductionPolicy,
                        logLevel: logLevel
                    )
                    
                    let response = try await minimalContextualSession.respond(to: userMessage)
                    contextualSession = minimalContextualSession
                    
                    messages.append(ChatMessage(role: .assistant, content: response.content))
                    updateTranscriptView()
                } catch {
                    // If even minimal session fails, show a user-friendly message
                    messages.append(ChatMessage(
                        role: .assistant,
                        content: "I'm having trouble processing your request. The conversation history is too long. Please try a shorter message or clear the chat."
                    ))
                }
            } else {
                // Show other errors normally
                messages.append(ChatMessage(
                    role: .assistant,
                    content: "Error: \(error.localizedDescription)"
                ))
            }
        }
        
        isProcessing = false
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}

enum MessageRole {
    case user
    case assistant
    case system
}
