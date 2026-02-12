# Custom Themes in Edipad

Edipad supports custom themes through the `ThemeConfiguration` API. You can provide your own CSS files for syntax highlighting while maintaining a consistent editor appearance.

## Usage

### Option 1: From CSS File Paths

The simplest way to use custom themes is to provide paths to your CSS files:

```swift
import Edipad

// Load theme from CSS files
let darkCSS = URL(fileURLWithPath: "/path/to/my-dark-theme.css")
let lightCSS = URL(fileURLWithPath: "/path/to/my-light-theme.css")

if let themeConfig = ThemeConfiguration.fromCSS(
    darkCSSPath: darkCSS,
    lightCSSPath: lightCSS
) {
    let settings = DefaultEditorSettings(
        customThemeConfig: themeConfig
    )

    // Use with EditorView
    EditorView(
        content: $content,
        language: $language,
        settings: settings
    )
}
```

The `fromCSS()` method automatically extracts background and foreground colors from the `.hljs` selector in your CSS.

### Option 2: Manual Theme Configuration

For more control, create themes manually:

```swift
import Edipad

let darkTheme = EditorTheme(
    isDark: true,
    background: NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0),
    foreground: NSColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0),
    cssPath: URL(fileURLWithPath: "/path/to/dark-syntax.css")
)

let lightTheme = EditorTheme(
    isDark: false,
    background: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
    foreground: NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
    cssPath: URL(fileURLWithPath: "/path/to/light-syntax.css")
)

let themeConfig = ThemeConfiguration(
    darkTheme: darkTheme,
    lightTheme: lightTheme
)

let settings = DefaultEditorSettings(
    customThemeConfig: themeConfig
)
```

### Option 3: Use Default Themes

If you don't provide a `customThemeConfig`, Edipad uses the built-in Atom One themes:

```swift
let settings = DefaultEditorSettings()
// Uses default Atom One dark/light themes
```

## CSS Format

Your CSS files should follow the highlight.js theme format:

```css
.hljs {
  color: #d4d4d4;        /* Foreground color */
  background: #25252c;   /* Background color */
}

.hljs-keyword {
  color: #ff6188;
}

.hljs-string {
  color: #ffd866;
}

/* ... more token styles ... */
```

See the bundled `itsypad-dark.min.css` and `itsypad-light.min.css` for complete examples.

## Appearance Override

The `appearanceOverride` setting controls which theme variant is used:

```swift
settings.appearanceOverride = "dark"   // Always use dark theme
settings.appearanceOverride = "light"  // Always use light theme
settings.appearanceOverride = "system" // Follow system appearance (default)
```

When `customThemeConfig` is set, this controls whether to use `darkTheme` or `lightTheme` from your configuration.

## Dynamic Theme Changes

You can change themes at runtime by updating the settings:

```swift
// Switch to a different custom theme
settings.customThemeConfig = newThemeConfig

// Or revert to default themes
settings.customThemeConfig = nil
```

The editor will automatically reload with the new theme.
