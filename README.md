# Edipad

A reusable macOS code editor component with syntax highlighting, built with Swift and SwiftUI.

## Features

- **185+ languages** syntax highlighting via highlight.js
- **Line numbers** with smart width calculation
- **Word wrap** with hanging indent for lists
- **Markdown lists**: bullets, numbered lists, and checklists
- **Clickable links** with hover cursor
- **Theme support**: light, dark, and system appearance
- **Customizable settings** via protocol-based configuration

## Installation

### Swift Package Manager

Add Edipad to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bluzky/edipad.git", from: "1.0.0")
]
```

Or add it in Xcode: File → Add Package Dependencies → enter the repository URL.

## Usage

### Basic Example

```swift
import SwiftUI
import Edipad

struct ContentView: View {
    @State private var content = "Hello, World!"
    @State private var language = "swift"

    var body: some View {
        EditorView(
            content: $content,
            language: $language
        )
    }
}
```

### Custom Settings

```swift
import Edipad

// Create custom settings
let settings = DefaultEditorSettings()
settings.showLineNumbers = true
settings.wordWrap = true
settings.fontSize = 14
settings.tabWidth = 4
settings.highlightCurrentLine = false
settings.appearanceOverride = "dark" // "system", "light", or "dark"

// Use in editor
EditorView(
    content: $content,
    language: $language,
    settings: settings
)
```

### Supported Languages

Plain text, Swift, Python, JavaScript, TypeScript, HTML, CSS, C, C++, C#, JSON, Markdown, Bash, Zsh, Java, Kotlin, Go, Ruby, Rust, SQL, XML, YAML, TOML, Objective-C, PHP, PowerShell, and 160+ more.

Use `LanguageDetector.allLanguages` to get the full list.

## Requirements

- macOS 14.0+
- Swift 5.9+
- Xcode 16.0+

## License

MIT License - see LICENSE file for details.

## Credits

Extracted from [Itsypad](https://github.com/nickustinov/itsypad) - a native macOS scratchpad and clipboard manager.

Built with:
- [highlight.js](https://highlightjs.org/) for syntax highlighting
- SwiftUI and AppKit for the UI
