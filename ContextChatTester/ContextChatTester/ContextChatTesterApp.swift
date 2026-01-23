//
//  ContextChatTesterApp.swift
//  ContextChatTester
//
//  Created by Hadi Dbouk on 20/01/2026.
//

import SwiftUI

#if os(macOS)
import AppKit

@main
struct ContextChatTesterApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
            #if os(macOS)
                .frame(minWidth: 1200, minHeight: 800)
                .background(WindowAccessor())
            #endif
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        #endif
    }
}

#if os(macOS)
// Helper to access and configure the window (macOS only)
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Get the screen's visible frame (excluding menu bar and dock)
                if let screen = window.screen {
                    let screenFrame = screen.visibleFrame
                    window.setFrame(screenFrame, display: true, animate: false)
                }
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
#endif
