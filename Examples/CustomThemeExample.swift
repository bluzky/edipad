import SwiftUI
import Edipad

// MARK: - Example 1: Using CSS file paths

struct CustomThemeFromFilesExample: View {
    @State private var content = "// Custom theme example\nlet hello = \"world\""
    @State private var language = "swift"

    var body: some View {
        EditorView(
            content: $content,
            language: $language,
            settings: settingsWithCustomTheme()
        )
    }

    private func settingsWithCustomTheme() -> EditorSettings {
        let darkCSS = URL(fileURLWithPath: "/path/to/atom-one-dark.css")
        let lightCSS = URL(fileURLWithPath: "/path/to/atom-one-light.css")

        if let themeConfig = ThemeConfiguration.fromCSS(
            darkCSSPath: darkCSS,
            lightCSSPath: lightCSS
        ) {
            return DefaultEditorSettings(customThemeConfig: themeConfig)
        }

        // Fallback to default theme if files not found
        return DefaultEditorSettings()
    }
}

// MARK: - Example 2: Manual theme configuration

struct CustomThemeManualExample: View {
    @State private var content = "# Markdown example\n- Item 1\n- Item 2\n"
    @State private var language = "markdown"

    var body: some View {
        EditorView(
            content: $content,
            language: $language,
            settings: settingsWithManualTheme()
        )
    }

    private func settingsWithManualTheme() -> EditorSettings {
        // Create a dark theme with custom colors
        let darkTheme = EditorTheme(
            isDark: true,
            background: NSColor(red: 0.14, green: 0.17, blue: 0.20, alpha: 1.0), // #282c34
            foreground: NSColor(red: 0.67, green: 0.70, blue: 0.75, alpha: 1.0), // #abb2bf
            cssPath: Bundle.main.url(forResource: "my-dark-theme", withExtension: "css")
        )

        // Create a light theme with custom colors
        let lightTheme = EditorTheme(
            isDark: false,
            background: NSColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0), // #fafafa
            foreground: NSColor(red: 0.22, green: 0.23, blue: 0.26, alpha: 1.0), // #383a42
            cssPath: Bundle.main.url(forResource: "my-light-theme", withExtension: "css")
        )

        let themeConfig = ThemeConfiguration(
            darkTheme: darkTheme,
            lightTheme: lightTheme
        )

        return DefaultEditorSettings(customThemeConfig: themeConfig)
    }
}

// MARK: - Example 3: Dynamic theme switching

struct DynamicThemeExample: View {
    @State private var content = "function example() {\n  return true;\n}"
    @State private var language = "javascript"
    @StateObject private var settings = DynamicThemeSettings()

    var body: some View {
        VStack {
            // Theme picker
            Picker("Theme", selection: $settings.selectedTheme) {
                Text("Default (Monokai Pro)").tag(ThemeOption.default)
                Text("Atom One").tag(ThemeOption.atomOne)
                Text("Custom").tag(ThemeOption.custom)
            }
            .pickerStyle(.segmented)
            .padding()

            // Editor
            EditorView(
                content: $content,
                language: $language,
                settings: settings
            )
        }
    }
}

enum ThemeOption {
    case `default`
    case atomOne
    case custom
}

class DynamicThemeSettings: DefaultEditorSettings {
    @Published var selectedTheme: ThemeOption = .default {
        didSet {
            updateTheme()
        }
    }

    private func updateTheme() {
        switch selectedTheme {
        case .default:
            customThemeConfig = nil // Use built-in Monokai Pro

        case .atomOne:
            // Load Atom One Dark/Light themes
            if let darkCSS = Bundle.main.url(forResource: "atom-one-dark", withExtension: "css"),
               let lightCSS = Bundle.main.url(forResource: "atom-one-light", withExtension: "css"),
               let config = ThemeConfiguration.fromCSS(darkCSSPath: darkCSS, lightCSSPath: lightCSS) {
                customThemeConfig = config
            }

        case .custom:
            // Create a custom theme programmatically
            let darkTheme = EditorTheme(
                isDark: true,
                background: .black,
                foreground: NSColor(white: 0.9, alpha: 1.0),
                cssPath: Bundle.main.url(forResource: "custom-dark", withExtension: "css")
            )

            let lightTheme = EditorTheme(
                isDark: false,
                background: .white,
                foreground: NSColor(white: 0.1, alpha: 1.0),
                cssPath: Bundle.main.url(forResource: "custom-light", withExtension: "css")
            )

            customThemeConfig = ThemeConfiguration(
                darkTheme: darkTheme,
                lightTheme: lightTheme
            )
        }
    }
}

// MARK: - Example 4: Using bundled resources

struct BundledThemeExample: View {
    @State private var content = "SELECT * FROM users WHERE active = true;"
    @State private var language = "sql"

    var body: some View {
        EditorView(
            content: $content,
            language: $language,
            settings: settingsWithBundledTheme()
        )
    }

    private func settingsWithBundledTheme() -> EditorSettings {
        // Load CSS files from app bundle
        guard let darkCSS = Bundle.main.url(forResource: "themes/nord-dark", withExtension: "css"),
              let lightCSS = Bundle.main.url(forResource: "themes/nord-light", withExtension: "css"),
              let themeConfig = ThemeConfiguration.fromCSS(
                  darkCSSPath: darkCSS,
                  lightCSSPath: lightCSS
              ) else {
            print("Failed to load bundled themes, using defaults")
            return DefaultEditorSettings()
        }

        return DefaultEditorSettings(customThemeConfig: themeConfig)
    }
}
