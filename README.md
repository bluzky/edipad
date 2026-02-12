# Edipad

A reusable macOS code editor component with syntax highlighting, built with Swift and SwiftUI.

## Features

- **185+ languages** syntax highlighting via highlight.js
- **Line numbers** with smart width calculation
- **Word wrap** with hanging indent for lists
- **Markdown lists**: bullets, numbered lists, and checklists
- **Clickable links** with hover cursor
- **Theme support**: light, dark, and system appearance
- **Custom themes**: bring your own highlight.js CSS themes
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

### Custom Themes

Edipad supports custom themes via CSS files. You can provide your own highlight.js themes:

```swift
// Option 1: Load from CSS file paths
let darkCSS = URL(fileURLWithPath: "/path/to/dark-theme.css")
let lightCSS = URL(fileURLWithPath: "/path/to/light-theme.css")

if let themeConfig = ThemeConfiguration.fromCSS(
    darkCSSPath: darkCSS,
    lightCSSPath: lightCSS
) {
    let settings = DefaultEditorSettings(
        customThemeConfig: themeConfig
    )

    EditorView(content: $content, language: $language, settings: settings)
}

// Option 2: Manual configuration
let darkTheme = EditorTheme(
    isDark: true,
    background: NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0),
    foreground: NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),
    cssPath: URL(fileURLWithPath: "/path/to/dark-syntax.css")
)

let lightTheme = EditorTheme(
    isDark: false,
    background: .white,
    foreground: .black,
    cssPath: URL(fileURLWithPath: "/path/to/light-syntax.css")
)

let themeConfig = ThemeConfiguration(darkTheme: darkTheme, lightTheme: lightTheme)
let settings = DefaultEditorSettings(customThemeConfig: themeConfig)
```

If no custom theme is provided, Edipad uses the built-in Atom One themes.

See [CUSTOM_THEMES.md](CUSTOM_THEMES.md) for detailed documentation and more examples.

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
