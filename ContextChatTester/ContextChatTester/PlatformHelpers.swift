import SwiftUI

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

extension Color {
    /// Platform-agnostic control background color
    static var controlBackground: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .systemGray6)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }
    
    /// Platform-agnostic secondary background color for message bubbles
    static var messageBackground: Color {
        #if os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #elseif os(iOS)
        return Color(uiColor: .systemGray5)
        #else
        return Color.secondary.opacity(0.1)
        #endif
    }
}
