import SwiftUI
import SwiftContextManagement
import FoundationModels

struct ContentView: View {
    @State private var chatViewModel = ChatViewModel()
    #if os(iOS)
    @State private var showingSettings = false
    #endif
    
    var body: some View {
        #if os(macOS)
        HSplitView {
            // Left: Chat interface
            ChatView(viewModel: chatViewModel)
                .frame(minWidth: 400)
            
            // Right: Settings and transcript inspector
            VStack(alignment: .leading, spacing: 16) {
                PolicySelectorView(viewModel: chatViewModel)
                
                Divider()
                
                TranscriptInspectorView(
                    transcript: chatViewModel.currentTranscript,
                    originalCount: chatViewModel.originalEntryCount,
                    reductionEvent: chatViewModel.lastReductionEvent,
                    reductionError: chatViewModel.lastReductionError
                )
            }
            .frame(minWidth: 400)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        NavigationStack {
            ZStack {
                // Main chat view
                ChatView(viewModel: chatViewModel)
                
                // Settings button overlay
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle("Context Chat")
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: chatViewModel)
            }
        }
        #endif
    }
}

#if os(iOS)
struct SettingsView: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PolicySelectorView(viewModel: viewModel)
                    
                    Divider()
                    
                    TranscriptInspectorView(
                        transcript: viewModel.currentTranscript,
                        originalCount: viewModel.originalEntryCount,
                        reductionEvent: viewModel.lastReductionEvent,
                        reductionError: viewModel.lastReductionError
                    )
                }
                .padding()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
#endif
