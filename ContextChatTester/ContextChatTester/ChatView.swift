import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            // Header (macOS only - iOS uses NavigationStack)
            VStack(spacing: 0) {
                HStack {
                    Text("Context Chat Tester")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        viewModel.clearChat()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                
                // Preset buttons
                HStack(spacing: 8) {
                    ForEach(MockConversationPresets.all, id: \.name) { preset in
                        Button(preset.name) {
                            Task {
                                viewModel.clearChat()
                                await viewModel.loadPreset(preset)
                            }
                        }
                        .buttonStyle(.bordered)
                        .help(preset.description)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color.controlBackground)
            
            Divider()
            #else
            // Preset buttons (iOS - scrollable)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MockConversationPresets.all, id: \.name) { preset in
                        Button(preset.name) {
                            Task {
                                viewModel.clearChat()
                                await viewModel.loadPreset(preset)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            Divider()
            #endif
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Loading indicator
                        if viewModel.isProcessing {
                            LoadingBubble()
                                .id("loading")
                                .onAppear {
                                    withAnimation {
                                        proxy.scrollTo("loading", anchor: .bottom)
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: viewModel.messages.count) {
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isProcessing) {
                    if viewModel.isProcessing {
                        withAnimation {
                            proxy.scrollTo("loading", anchor: .bottom)
                        }
                    }
                }
            }
            
            #if os(macOS)
            Divider()
            #endif
            
            // Input area
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Type your message...", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)
                    .onSubmit {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }
                
                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isProcessing || viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    viewModel.clearChat()
                }
            }
        }
        #endif
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.role == .user
                            ? Color.accentColor
                            : Color.messageBackground
                    )
                    .foregroundColor(
                        message.role == .user
                            ? .white
                            : .primary
                    )
                    .cornerRadius(12)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

struct LoadingBubble: View {
    @State private var animationTrigger = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .opacity(animationTrigger ? (index == 0 ? 0.3 : index == 1 ? 0.6 : 1.0) : (index == 2 ? 0.3 : index == 1 ? 0.6 : 1.0))
                            .scaleEffect(animationTrigger ? (index == 0 ? 0.8 : index == 1 ? 0.9 : 1.0) : (index == 2 ? 0.8 : index == 1 ? 0.9 : 1.0))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.messageBackground)
                .cornerRadius(12)
            }
            
            Spacer(minLength: 60)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                animationTrigger = true
            }
        }
    }
}
