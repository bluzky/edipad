import AppKit
import Foundation

public struct EditorTheme {
    public let isDark: Bool
    public let background: NSColor
    public let foreground: NSColor
    public let cssPath: URL?

    public var insertionPointColor: NSColor { isDark ? .white : .black }

    public init(isDark: Bool, background: NSColor, foreground: NSColor, cssPath: URL? = nil) {
        self.isDark = isDark
        self.background = background
        self.foreground = foreground
        self.cssPath = cssPath
    }

    // MARK: - Resolve theme for current appearance setting

    public static func current(for appearance: String) -> EditorTheme {
        switch appearance {
        case "light": return light
        case "dark": return dark
        default: return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        }
    }

    // MARK: - Atom One Dark

    public static let dark = EditorTheme(
        isDark: true,
        background: hex(0x282c34),
        foreground: hex(0xabb2bf)
    )

    // MARK: - Atom One Light

    public static let light = EditorTheme(
        isDark: false,
        background: hex(0xfafafa),
        foreground: hex(0x383a42)
    )

    // Bullet-dash color (hue-5: red)
    public var bulletDashColor: NSColor { isDark ? Self.hex(0xe06c75) : Self.hex(0xe45649) }

    // Checkbox bracket color (hue-3: purple)
    public var checkboxColor: NSColor { isDark ? Self.hex(0xc678dd) : Self.hex(0xa626a4) }

    // Link color (hue-2: blue)
    public var linkColor: NSColor { isDark ? Self.hex(0x61aeee) : Self.hex(0x4078f2) }

    // MARK: - Hex color helper

    private static func hex(_ value: UInt32) -> NSColor {
        let r = CGFloat((value >> 16) & 0xFF) / 255.0
        let g = CGFloat((value >> 8) & 0xFF) / 255.0
        let b = CGFloat(value & 0xFF) / 255.0
        return NSColor(srgbRed: r, green: g, blue: b, alpha: 1.0)
    }
}
