<div align="center">
  <img src="hero.png" alt="FueledUtils" width="800"/>
</div>

**Swift Context Management** is a Swift package designed to help developers manage language model context windows efficiently. As conversations grow longer, they often exceed the token limits of large language models (LLMs). This package provides a variety of context reduction policies to prune, summarize, or restructure conversation history, ensuring that the most relevant information is always preserved while staying within the model's constraints.

## Features

- **Progressive Context Reduction**: Automatically retries LLM requests with increasingly aggressive context reduction if a context window limit is hit.
- **Multiple Reduction Policies**: A wide range of strategies from simple sliding windows to advanced hierarchical summarization.
- **Structured State Extraction**: Automatically extract and maintain important facts, decisions, and constraints from conversations.
- **Seamless Integration**: Built to work with the `FoundationModels` framework.

## Context Reduction Policies

The package uses `ContextReductionPolicy` to define how conversation history should be managed.

### Implemented Policies

- **Sliding Window**: Keeps only the most recent N conversation turns (or tokens), discarding all earlier history.
- **Head-Tail Window**: Preserves the initial instructions (head) and the most recent turns (tail), dropping the middle part of the conversation.
- **Rolling Summary**: Replaces older conversation history with a single running summary while keeping recent turns verbatim.
- **Hierarchical Summary**: Maintains multiple summaries at different granularities (per turn, per topic, global) and selects the appropriate level when reducing context.
- **Structured State**: Extracts and stores important facts, constraints, or decisions in structured fields instead of natural language history.

### Planned Policies (to be implemented ..)

- **Salience Pruning**: Removes low-importance or low-salience messages, keeping only critical information.
- **Semantic Recall**: Retrieves only the most semantically relevant past messages using vector embeddings.
- **Topic Memory**: Segments conversation history by topic and injects only the memory related to the current topic.
- **Query Rewriting**: Rewrites multi-turn conversational prompts into single standalone queries.
- **Dynamic Injection**: Dynamically decides which parts of history, summaries, or memory to include based on available context budget.
- **dhRAG**: Minimizes unnecessary context usage by selectively using history only when it improves retrieval-augmented generation.
- **Reflective Memory**: Periodically rewrites and refines stored memory to prevent accumulation of outdated information.

## Usage

To use context management, initialize a `ContextualSession` with your desired policy:

```swift
import FoundationModels
import SwiftContextManagement

let session = LanguageModelSession()
let contextualSession = ContextualSession(
    session: session,
    policy: .rollingSummary()
)

// The session will automatically handle context window errors by applying the policy
let response = try await contextualSession.respond(to: "...")
```

## Contributing

We welcome contributions! Please feel free to submit pull requests or open issues for any of the planned policies or new ideas.
