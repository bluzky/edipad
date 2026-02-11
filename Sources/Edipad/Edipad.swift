// Edipad - A reusable macOS code editor component
//
// Usage:
// ```swift
// import Edipad
//
// struct ContentView: View {
//     @State private var content = "Hello, World!"
//     @State private var language = "swift"
//
//     var body: some View {
//         EditorView(content: $content, language: $language)
//     }
// }
// ```

// Re-export public types
@_exported import struct Foundation.URL
@_exported import class AppKit.NSFont
