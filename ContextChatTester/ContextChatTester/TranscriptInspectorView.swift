import SwiftUI
import FoundationModels
import SwiftContextManagement

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct TranscriptInspectorView: View {
    let transcript: Transcript?
    let originalCount: Int
    let reductionEvent: ChatViewModel.ReductionEvent?
    let reductionError: String?
    @State private var copyFeedback: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript Inspector")
                .font(.headline)
            
            // Show error banner if reduction failed
            if let error = reductionError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
            }
            
            if let reductionEvent = reductionEvent {
                // Show side-by-side comparison when reduction occurred
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Context Reduction: \(reductionEvent.reducerName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Copy Both button
                        Button {
                            copyBothTranscripts(reductionEvent: reductionEvent)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Both")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        if let feedback = copyFeedback {
                            Text(feedback)
                                .font(.caption)
                                .foregroundColor(.green)
                                .transition(.opacity)
                        }
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        // Left: Before reduction
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("BEFORE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                                
                                Button {
                                    copyTranscript(reductionEvent.original, label: "BEFORE")
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.caption2)
                                }
                                .buttonStyle(.borderless)
                                #if os(macOS)
                                .help("Copy BEFORE transcript to clipboard")
                                #endif
                            }
                            
                            // Metrics on left side
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Entries: \(reductionEvent.original.count)", systemImage: "list.number")
                                Label("Chars: \(reductionEvent.original.characterCount())", systemImage: "textformat")
                                Label("Tokens: ~\(reductionEvent.original.estimatedTokenCount())", systemImage: "number")
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            
                            EnhancedTranscriptView(transcript: reductionEvent.original)
                                .frame(maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(8)
                        .background(Color.controlBackground)
                        .cornerRadius(6)
                        
                        // Right: After reduction
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("AFTER")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                
                                Spacer()
                                
                                Button {
                                    copyTranscript(reductionEvent.reduced, label: "AFTER")
                                } label: {
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.caption2)
                                }
                                .buttonStyle(.borderless)
                                #if os(macOS)
                                .help("Copy AFTER transcript to clipboard")
                                #endif
                            }
                            
                            // Metrics on right side
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Entries: \(reductionEvent.reduced.count)", systemImage: "list.number")
                                Label("Chars: \(reductionEvent.reduced.characterCount())", systemImage: "textformat")
                                Label("Tokens: ~\(reductionEvent.reduced.estimatedTokenCount())", systemImage: "number")
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            
                            EnhancedTranscriptView(transcript: reductionEvent.reduced)
                                .frame(maxHeight: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(8)
                        .background(Color.controlBackground)
                        .cornerRadius(6)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
            } else if let transcript = transcript {
                // No reduction yet, show current transcript with metrics
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Entries: \(transcript.count)", systemImage: "list.number")
                        Spacer()
                        Label("Chars: \(transcript.characterCount())", systemImage: "textformat")
                        Spacer()
                        Label("Tokens: ~\(transcript.estimatedTokenCount())", systemImage: "number")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.controlBackground)
                    .cornerRadius(6)
                    
                    EnhancedTranscriptView(transcript: transcript)
                        .frame(maxHeight: .infinity)
                }
            } else {
                Text("No transcript available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func formatFullTranscript(_ transcript: Transcript) -> String {
        return transcript.enumerated().map { index, entry in
            let role = switch entry {
            case .instructions: "[SYSTEM]"
            case .prompt: "[USER]"
            case .response: "[ASSISTANT]"
            default: "[OTHER]"
            }
            let text = TranscriptHelpers.extractText(from: entry) ?? ""
            return "\(index). \(role) \(text)"
        }.joined(separator: "\n\n")
    }
    
    private func copyTranscript(_ transcript: Transcript, label: String) {
        let content = formatFullTranscript(transcript)
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = content
        #endif
        
        // Show feedback
        withAnimation {
            copyFeedback = "\(label) copied!"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copyFeedback = nil
            }
        }
    }
    
    private func copyBothTranscripts(reductionEvent: ChatViewModel.ReductionEvent) {
        let beforeContent = formatFullTranscript(reductionEvent.original)
        let afterContent = formatFullTranscript(reductionEvent.reduced)
        
        let comparisonText = """
        === CONTEXT REDUCTION COMPARISON ===
        Reducer: \(reductionEvent.reducerName)
        Date: \(reductionEvent.timestamp.formatted())
        
        === BEFORE REDUCTION ===
        Entries: \(reductionEvent.original.count)
        Characters: \(reductionEvent.original.characterCount())
        Estimated Tokens: ~\(reductionEvent.original.estimatedTokenCount())
        
        \(beforeContent)
        
        === AFTER REDUCTION ===
        Entries: \(reductionEvent.reduced.count)
        Characters: \(reductionEvent.reduced.characterCount())
        Estimated Tokens: ~\(reductionEvent.reduced.estimatedTokenCount())
        
        \(afterContent)
        
        === REDUCTION STATS ===
        Entries removed: \(reductionEvent.original.count - reductionEvent.reduced.count)
        Characters saved: \(reductionEvent.original.characterCount() - reductionEvent.reduced.characterCount())
        Tokens saved: ~\(reductionEvent.original.estimatedTokenCount() - reductionEvent.reduced.estimatedTokenCount())
        """
        
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(comparisonText, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = comparisonText
        #endif
        
        // Show feedback
        withAnimation {
            copyFeedback = "Both transcripts copied!"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copyFeedback = nil
            }
        }
    }
}

// MARK: - Enhanced Transcript View

struct EnhancedTranscriptView: View {
    let transcript: Transcript
    @State private var expandedEntries: Set<Int> = []
    
    var body: some View {
        List {
            ForEach(Array(transcript.enumerated()), id: \.offset) { index, entry in
                TranscriptEntryRow(
                    index: index,
                    entry: entry,
                    isExpanded: expandedEntries.contains(index),
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedEntries.contains(index) {
                                expandedEntries.remove(index)
                            } else {
                                expandedEntries.insert(index)
                            }
                        }
                    }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}

struct TranscriptEntryRow: View {
    let index: Int
    let entry: Transcript.Entry
    let isExpanded: Bool
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var entryType: EntryType {
        switch entry {
        case .instructions:
            return .system
        case .prompt:
            return .user
        case .response:
            return .assistant
        default:
            return .other
        }
    }
    
    private var entryText: String {
        TranscriptHelpers.extractText(from: entry) ?? ""
    }
    
    private var backgroundColor: Color {
        let isDark = colorScheme == .dark
        
        switch entryType {
        case .system:
            // Adaptive gray
            return isDark 
                ? Color(red: 0.2, green: 0.2, blue: 0.22)
                : Color(red: 0.95, green: 0.95, blue: 0.97)
        case .user:
            // Adaptive blue
            return isDark
                ? Color(red: 0.15, green: 0.25, blue: 0.4)
                : Color(red: 0.85, green: 0.92, blue: 1.0)
        case .assistant:
            // Adaptive green - much more saturated in light mode for visibility
            return isDark
                ? Color(red: 0.15, green: 0.35, blue: 0.2)
                : Color(red: 0.55, green: 0.8, blue: 0.55)
        case .other:
            return Color.controlBackground
        }
    }
    
    private var borderColor: Color {
        let isDark = colorScheme == .dark
        
        switch entryType {
        case .system:
            return isDark
                ? Color.gray.opacity(0.5)
                : Color.gray.opacity(0.3)
        case .user:
            return isDark
                ? Color.blue.opacity(0.6)
                : Color.blue.opacity(0.5)
        case .assistant:
            return isDark
                ? Color.green.opacity(0.6)
                : Color.green.opacity(0.6) // More visible border in light mode
        case .other:
            return isDark
                ? Color.gray.opacity(0.4)
                : Color.gray.opacity(0.2)
        }
    }
    
    private var headerText: String {
        switch entryType {
        case .system:
            return "SYSTEM"
        case .user:
            return "USER"
        case .assistant:
            return "ASSISTANT"
        case .other:
            return "OTHER"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                // Entry number and type
                HStack(spacing: 6) {
                    Text("#\(index)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text(headerText)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(entryType == .user ? .blue : entryType == .assistant ? .green : .secondary)
                }
                
                Spacer()
                
                // Expand/collapse button and character count (only for assistant responses)
                if entryType == .assistant {
                    HStack(spacing: 8) {
                        Text("\(entryText.count) chars")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Button(action: onToggle) {
                            Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        #if os(macOS)
                        .help(isExpanded ? "Collapse" : "Expand")
                        #endif
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(backgroundColor.opacity(colorScheme == .dark ? 0.5 : 0.7))
            
            // Content
            if entryType == .assistant {
                // Assistant response - expandable
                if isExpanded {
                    ScrollView {
                        Text(entryText)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .frame(maxHeight: 300)
                    .background(backgroundColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    // Collapsed: show preview
                    HStack(alignment: .top, spacing: 8) {
                        Text(entryText.prefix(150) + (entryText.count > 150 ? "..." : ""))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        
                        Spacer()
                        
                        Text("(tap to expand)")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(backgroundColor.opacity(colorScheme == .dark ? 0.4 : 0.6))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onToggle()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            } else {
                // User/system/other - always show full content
                ScrollView {
                    Text(entryText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 200)
                .background(backgroundColor)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor, lineWidth: 1)
        )
        .background(backgroundColor)
        .cornerRadius(6)
    }
    
    enum EntryType {
        case system
        case user
        case assistant
        case other
    }
}
