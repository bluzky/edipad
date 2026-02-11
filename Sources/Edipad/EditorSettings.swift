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

    /// Publisher that emits when any setting changes
    var settingsChangedPublisher: AnyPublisher<Void, Never> { get }
}

public extension EditorSettings {
    var indentString: String {
        indentUsingSpaces ? String(repeating: " ", count: tabWidth) : "\t"
    }
}
