import Cocoa

public struct EditorState {
    public let textView: EditorTextView
    public let scrollView: NSScrollView
    public let gutterView: LineNumberGutterView
    public let highlightCoordinator: SyntaxHighlightCoordinator

    public init(
        textView: EditorTextView,
        scrollView: NSScrollView,
        gutterView: LineNumberGutterView,
        highlightCoordinator: SyntaxHighlightCoordinator
    ) {
        self.textView = textView
        self.scrollView = scrollView
        self.gutterView = gutterView
        self.highlightCoordinator = highlightCoordinator
    }
}
