import AppKit
import Combine

/// Protocol defining editor configuration options.
/// Implement this protocol to provide custom settings to the editor.
public protocol EditorSettings: AnyObject {
    var font: NSFont { get }
    var showLineNumbers: Bool { get }
    var wordWrap: Bool { get }
    var highlightCurrentLine: Bool { get }
    var indentUsingSpaces: Bool { get }
    var tabWidth: Int { get }
    var bulletListsEnabled: Bool { get }
    var numberedListsEnabled: Bool { get }
    var checklistsEnabled: Bool { get }
    var clickableLinks: Bool { get }
    var appearanceOverride: String { get }  // "system", "light", "dark"

    /// Optional custom theme configuration.
    /// If nil, uses default Monokai Pro themes.
    var customThemeConfig: ThemeConfiguration? { get }

    /// Publisher that emits when any setting changes
    var settingsChangedPublisher: AnyPublisher<Void, Never> { get }
}

/// Configuration for custom editor themes.
public struct ThemeConfiguration {
    public let darkTheme: EditorTheme
    public let lightTheme: EditorTheme

    /// Creates a theme configuration with separate dark and light themes.
    /// - Parameters:
    ///   - darkTheme: Theme to use in dark mode
    ///   - lightTheme: Theme to use in light mode
    public init(darkTheme: EditorTheme, lightTheme: EditorTheme) {
        self.darkTheme = darkTheme
        self.lightTheme = lightTheme
    }

    /// Creates a theme configuration from CSS file paths.
    /// - Parameters:
    ///   - darkCSSPath: Path to CSS file for dark theme
    ///   - lightCSSPath: Path to CSS file for light theme
    /// - Returns: Theme configuration with colors extracted from CSS, or nil if CSS files cannot be read
    public static func fromCSS(darkCSSPath: URL, lightCSSPath: URL) -> ThemeConfiguration? {
        guard let darkCSS = try? String(contentsOf: darkCSSPath),
              let lightCSS = try? String(contentsOf: lightCSSPath) else {
            return nil
        }

        let darkColors = extractColorsFromCSS(darkCSS)
        let lightColors = extractColorsFromCSS(lightCSS)

        let darkTheme = EditorTheme(
            isDark: true,
            background: darkColors.background,
            foreground: darkColors.foreground,
            cssPath: darkCSSPath
        )

        let lightTheme = EditorTheme(
            isDark: false,
            background: lightColors.background,
            foreground: lightColors.foreground,
            cssPath: lightCSSPath
        )

        return ThemeConfiguration(darkTheme: darkTheme, lightTheme: lightTheme)
    }

    private static func extractColorsFromCSS(_ css: String) -> (background: NSColor, foreground: NSColor) {
        var background: NSColor = .black
        var foreground: NSColor = .white

        // Parse .hljs{...} block - more flexible regex for minified CSS
        let pattern = #"\.hljs\s*\{[^}]*\}"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: css, range: NSRange(css.startIndex..., in: css)),
           let range = Range(match.range, in: css) {

            let hljsBlock = String(css[range])

            // Extract color: value
            if let colorMatch = hljsBlock.range(of: #"color:\s*([#\w]+)"#, options: .regularExpression),
               let colorValue = hljsBlock[colorMatch].split(separator: ":").last {
                foreground = colorFromCSS(String(colorValue))
            }

            // Extract background: value
            if let bgMatch = hljsBlock.range(of: #"background:\s*([#\w]+)"#, options: .regularExpression),
               let bgValue = hljsBlock[bgMatch].split(separator: ":").last {
                background = colorFromCSS(String(bgValue))
            }
        }

        return (background, foreground)
    }

    private static func colorFromCSS(_ value: String) -> NSColor {
        let s = value.trimmingCharacters(in: .whitespaces)
        guard s.hasPrefix("#") else {
            switch s {
            case "white": return .white
            case "black": return .black
            default: return .gray
            }
        }

        let hex = String(s.dropFirst())
        var r: UInt64 = 0, g: UInt64 = 0, b: UInt64 = 0
        let divisor: CGFloat

        if hex.count == 6 {
            Scanner(string: String(hex.prefix(2))).scanHexInt64(&r)
            Scanner(string: String(hex.dropFirst(2).prefix(2))).scanHexInt64(&g)
            Scanner(string: String(hex.dropFirst(4).prefix(2))).scanHexInt64(&b)
            divisor = 255
        } else if hex.count == 3 {
            Scanner(string: String(hex.prefix(1))).scanHexInt64(&r)
            Scanner(string: String(hex.dropFirst(1).prefix(1))).scanHexInt64(&g)
            Scanner(string: String(hex.dropFirst(2).prefix(1))).scanHexInt64(&b)
            r = r * 17; g = g * 17; b = b * 17
            divisor = 255
        } else {
            return .gray
        }

        return NSColor(red: CGFloat(r) / divisor, green: CGFloat(g) / divisor,
                       blue: CGFloat(b) / divisor, alpha: 1)
    }
}

public extension EditorSettings {
    var indentString: String {
        indentUsingSpaces ? String(repeating: " ", count: tabWidth) : "\t"
    }
}
