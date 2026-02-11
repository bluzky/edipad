import Cocoa

public enum EditorStateFactory {

    @MainActor
    public static func create(
        content: String,
        language: String,
        cursorPosition: Int = 0,
        settings: EditorSettings
    ) -> EditorState {
        let scrollView = createScrollView()
        let textView = createTextView(settings: settings)

        if !settings.wordWrap {
            textView.isHorizontallyResizable = true
            scrollView.hasHorizontalScroller = true
            textView.textContainer?.widthTracksTextView = false
            textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        }

        scrollView.documentView = textView

        let gutter = createGutter()
        let highlighter = createHighlighter(for: textView, settings: settings)
        setupContent(textView: textView, highlighter: highlighter, content: content, language: language, cursorPosition: cursorPosition)

        applyTheme(textView: textView, gutter: gutter, coordinator: highlighter, settings: settings)
        highlighter.applyWrapIndent(to: textView, font: settings.font, settings: settings)
        highlighter.scheduleHighlightIfNeeded()

        return EditorState(
            textView: textView,
            scrollView: scrollView,
            gutterView: gutter,
            highlightCoordinator: highlighter
        )
    }

    @MainActor
    private static func createScrollView() -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalScroller = true
        scrollView.contentView.postsBoundsChangedNotifications = true
        return scrollView
    }

    @MainActor
    private static func createTextView(settings: EditorSettings) -> EditorTextView {
        let textView = EditorTextView(frame: .zero)
        textView.settings = settings
        textView.isEditable = true
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.font = settings.font
        textView.drawsBackground = true
        textView.textContainerInset = NSSize(width: settings.showLineNumbers ? 4 : 12, height: 12)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor

        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.smartInsertDeleteEnabled = false

        textView.autoresizingMask = [.width, .height]
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        return textView
    }

    private static func createGutter() -> LineNumberGutterView {
        let gutter = LineNumberGutterView()
        gutter.translatesAutoresizingMaskIntoConstraints = false
        gutter.wantsLayer = true
        gutter.layer?.masksToBounds = true
        return gutter
    }

    @MainActor
    private static func createHighlighter(for textView: EditorTextView, settings: EditorSettings) -> SyntaxHighlightCoordinator {
        let highlighter = SyntaxHighlightCoordinator()
        highlighter.textView = textView
        highlighter.settings = settings
        highlighter.font = settings.font
        textView.delegate = highlighter
        return highlighter
    }

    @MainActor
    private static func setupContent(textView: EditorTextView, highlighter: SyntaxHighlightCoordinator, content: String, language: String, cursorPosition: Int) {
        textView.string = content
        highlighter.language = language

        let pos = min(cursorPosition, (textView.string as NSString).length)
        textView.setSelectedRange(NSRange(location: pos, length: 0))
        textView.scrollRangeToVisible(NSRange(location: pos, length: 0))
    }

    public static func applyTheme(textView: EditorTextView, gutter: LineNumberGutterView, coordinator: SyntaxHighlightCoordinator, settings: EditorSettings) {
        let bg = coordinator.themeBackgroundColor
        let isDark = coordinator.themeIsDark

        textView.backgroundColor = bg
        textView.drawsBackground = true
        textView.insertionPointColor = isDark ? .white : .black

        gutter.bgColor = bg
        gutter.lineColor = isDark
            ? NSColor.white.withAlphaComponent(0.3)
            : NSColor.black.withAlphaComponent(0.3)
        gutter.lineFont = NSFont.monospacedSystemFont(
            ofSize: settings.font.pointSize * 0.85,
            weight: .regular
        )
        gutter.needsDisplay = true
    }
}
