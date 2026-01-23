import SwiftUI
import SwiftContextManagement

struct PolicySelectorView: View {
    @Bindable var viewModel: ChatViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)
            
            // Reduction Policy
            VStack(alignment: .leading, spacing: 8) {
                Text("Reduction Policy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Policy", selection: $viewModel.reductionPolicy) {
                    // Only show implemented policies
                    Text("Sliding Window (10)").tag(ContextReductionPolicy.slidingWindow(turns: 10))
                    Text("Sliding Window (5)").tag(ContextReductionPolicy.slidingWindow(turns: 5))
                    Text("Head-Tail Window").tag(ContextReductionPolicy.headTailWindow)
                    Text("Rolling Summary").tag(ContextReductionPolicy.rollingSummary(configuration: nil))
                    Text("Hierarchical Summary").tag(ContextReductionPolicy.hierarchicalSummary(configuration: nil))
                    Text("Structured State").tag(ContextReductionPolicy.structuredState(configuration: nil))
                }
                .pickerStyle(.menu)
                
                // Restart prompt
                if viewModel.needsRestart {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Policy changed. Restart session to apply.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Restart") {
                            viewModel.restartSession()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.controlBackground)
        .cornerRadius(8)
    }
}
