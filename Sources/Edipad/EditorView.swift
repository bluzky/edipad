import SwiftUI
import Combine

/// A SwiftUI view that provides a full-featured code editor with syntax highlighting.
///
/// Example usage:
/// ```swift
/// struct ContentView: View {
///     @State private var content = "Hello, World!"
///     @State private var language = "swift"
///
///     var body: some View {
///         EditorView(content: $content, language: $language)
///     }
/// }
/// ```
public struct EditorView: View {
    @Binding var content: String
    @Binding var language: String

    private let settings: EditorSettings

    @State private var editorState: EditorState?
    @State private var settingsCancellable: AnyCancellable?

    /// Creates an editor view with the specified content, language, and settings.
    ///
    /// - Parameters:
    ///   - content: A binding to the text content of the editor.
    ///   - language: A binding to the programming language for syntax highlighting.
    ///               Use "plain" for no syntax highlighting.
    ///   - settings: The editor settings to use. Defaults to `DefaultEditorSettings()`.
    public init(
        content: Binding<String>,
        language: Binding<String>,
        settings: EditorSettings = DefaultEditorSettings()
    ) {
        self._content = content
        self._language = language
        self.settings = settings
    }

    public var body: some View {
        GeometryReader { _ in
            if let state = editorState {
                EditorContentView(editorState: state, settings: settings)
            } else {
                Color.clear
                    .onAppear {
                        createEditorState()
                    }
            }
        }
        .onChange(of: content) { _, newValue in
            updateContentIfNeeded(newValue)
        }
        .onChange(of: language) { _, newValue in
            updateLanguageIfNeeded(newValue)
        }
    }

    @MainActor
    private func createEditorState() {
        let state = EditorStateFactory.create(
            content: content,
            language: language,
            cursorPosition: 0,
            settings: settings
        )

        // Wire up content changes from the text view
        state.textView.onTextChange = { [self] newText in
            if self.content != newText {
                self.content = newText
            }
        }

        // Subscribe to settings changes - capture the text view weakly since it's a class
        let textView = state.textView
        let gutterView = state.gutterView
        let coordinator = state.highlightCoordinator
        settingsCancellable = settings.settingsChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak textView, weak gutterView, weak coordinator] in
                guard let textView, let gutterView, let coordinator else { return }
                let state = EditorState(textView: textView, scrollView: textView.enclosingScrollView ?? NSScrollView(), gutterView: gutterView, highlightCoordinator: coordinator)
                applySettingsChanges(to: state)
            }

        editorState = state
    }

    @MainActor
    private func updateContentIfNeeded(_ newValue: String) {
        guard let state = editorState else { return }
        if state.textView.string != newValue {
            let sel = state.textView.selectedRange()
            state.textView.string = newValue
            let safeLoc = min(sel.location, (newValue as NSString).length)
            state.textView.setSelectedRange(NSRange(location: safeLoc, length: 0))
            state.highlightCoordinator.scheduleHighlightIfNeeded(text: newValue)
        }
    }

    @MainActor
    private func updateLanguageIfNeeded(_ newValue: String) {
        guard let state = editorState else { return }
        if state.highlightCoordinator.language != newValue {
            state.highlightCoordinator.language = newValue
        }
    }

    @MainActor
    private func applySettingsChanges(to state: EditorState) {
        // Update font
        state.textView.font = settings.font
        state.highlightCoordinator.font = settings.font

        // Update word wrap
        state.textView.wrapsLines = settings.wordWrap

        // Update theme
        state.highlightCoordinator.updateTheme()

        // Update gutter
        let lineCount = state.textView.string.components(separatedBy: "\n").count
        state.gutterView.updateVisibility(settings.showLineNumbers, lineCount: lineCount)

        // Apply theme colors
        EditorStateFactory.applyTheme(
            textView: state.textView,
            gutter: state.gutterView,
            coordinator: state.highlightCoordinator,
            settings: settings
        )

        // Update text container inset
        state.textView.textContainerInset = NSSize(width: settings.showLineNumbers ? 4 : 12, height: 12)

        // Re-highlight
        state.highlightCoordinator.rehighlight()
    }
}
