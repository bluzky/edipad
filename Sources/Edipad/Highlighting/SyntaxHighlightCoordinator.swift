import AppKit

public class SyntaxHighlightCoordinator: NSObject, NSTextViewDelegate {
    public weak var textView: EditorTextView?
    public weak var settings: EditorSettings?

    public var language: String = "plain" {
        didSet {
            if language != oldValue { setLanguage(language) }
        }
    }
    public var font: NSFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)

    // Shared across all coordinators — JSContext created lazily on first highlight call.
    // All access serialized via highlightQueue.
    private static let highlightJS = HighlightJS.shared
    private static let highlightQueue = DispatchQueue(label: "Edipad.SyntaxHighlight", qos: .userInitiated)

    public private(set) var theme: EditorTheme = EditorTheme.current(for: "system")
    public private(set) var themeBackgroundColor: NSColor = EditorTheme.current(for: "system").background
    public private(set) var themeIsDark: Bool = EditorTheme.current(for: "system").isDark

    private var pendingHighlight: DispatchWorkItem?
    private var lastHighlightedText: String = ""
    private var lastLanguage: String?
    private var lastAppearance: String?
    private var previousHighlightedLineRange: NSRange?

    public override init() {
        super.init()
        applyTheme()
        setLanguage(language)
    }

    public func updateTheme() {
        let appearance = settings?.appearanceOverride ?? "system"
        theme = EditorTheme.current(for: appearance)
        applyTheme()
        lastAppearance = nil
        rehighlight()
    }

    private func applyTheme() {
        let isDark = theme.isDark
        let themeName = isDark ? "itsypad-dark.min" : "itsypad-light.min"
        let currentFont = font

        Self.highlightQueue.sync {
            _ = Self.highlightJS.loadTheme(named: themeName)
            Self.highlightJS.setCodeFont(currentFont)
        }

        themeBackgroundColor = Self.highlightJS.backgroundColor
        if let srgb = themeBackgroundColor.usingColorSpace(.sRGB) {
            let luminance = 0.2126 * srgb.redComponent + 0.7152 * srgb.greenComponent + 0.0722 * srgb.blueComponent
            themeIsDark = luminance < 0.5
        } else {
            themeIsDark = isDark
        }
    }

    private func setLanguage(_ lang: String) {
        scheduleHighlightIfNeeded()
    }

    public func scheduleHighlightIfNeeded(text: String? = nil) {
        guard let tv = textView else { return }
        let text = text ?? tv.string
        let lang = language
        let appearance = settings?.appearanceOverride ?? "system"

        if (text as NSString).length > 200_000 {
            lastHighlightedText = text
            lastLanguage = lang
            lastAppearance = appearance
            return
        }

        if text == lastHighlightedText && lastLanguage == lang
            && lastAppearance == appearance {
            return
        }

        rehighlight()
    }

    public func rehighlight() {
        guard let tv = textView else { return }
        let textSnapshot = tv.string
        let userFont = font
        let currentTheme = theme
        let hlLang = LanguageDetector.shared.highlightrLanguage(for: language)
        let currentSettings = settings

        pendingHighlight?.cancel()

        // No language — plain text with bullet dash highlighting only
        guard let hlLang else {
            applyPlainText(tv: tv, text: textSnapshot, font: userFont, theme: currentTheme, settings: currentSettings)
            return
        }

        let highlightJS = Self.highlightJS

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            highlightJS.setCodeFont(userFont)
            let highlighted = highlightJS.highlight(textSnapshot, as: hlLang)

            DispatchQueue.main.async { [weak self] in
                guard let self, let tv = self.textView else { return }
                guard tv.string == textSnapshot else { return }

                let ns = textSnapshot as NSString
                let fullRange = NSRange(location: 0, length: ns.length)
                let sel = tv.selectedRange()

                tv.textStorage?.beginEditing()

                if let highlighted {
                    tv.textStorage?.replaceCharacters(in: fullRange, with: highlighted)
                    // Override font uniformly
                    let newLength = (tv.textStorage?.length ?? ns.length)
                    tv.textStorage?.addAttribute(.font, value: userFont, range: NSRange(location: 0, length: newLength))
                } else {
                    tv.textStorage?.setAttributes([
                        .font: userFont,
                        .foregroundColor: currentTheme.foreground,
                    ], range: fullRange)
                }

                // Apply bullet dash highlighting on top
                self.applyListMarkers(tv: tv, text: textSnapshot, theme: currentTheme, settings: currentSettings)
                self.applyLinkHighlighting(tv: tv, text: textSnapshot, theme: currentTheme, settings: currentSettings)

                tv.textStorage?.endEditing()
                self.applyWrapIndent(to: tv, font: userFont, settings: currentSettings)

                let safeLocation = min(sel.location, ns.length)
                let safeLength = min(sel.length, ns.length - safeLocation)
                tv.setSelectedRange(NSRange(location: safeLocation, length: safeLength))

                self.previousHighlightedLineRange = nil
                self.lastHighlightedText = textSnapshot
                self.lastLanguage = self.language
                self.lastAppearance = currentSettings?.appearanceOverride ?? "system"
            }
        }

        pendingHighlight = work
        Self.highlightQueue.asyncAfter(deadline: .now() + 0.05, execute: work)
    }

    private func applyPlainText(tv: EditorTextView, text: String, font: NSFont, theme: EditorTheme, settings: EditorSettings?) {
        let ns = text as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        let sel = tv.selectedRange()

        tv.textStorage?.beginEditing()
        tv.textStorage?.setAttributes([
            .font: font,
            .foregroundColor: theme.foreground,
        ], range: fullRange)

        applyListMarkers(tv: tv, text: text, theme: theme, settings: settings)
        applyLinkHighlighting(tv: tv, text: text, theme: theme, settings: settings)

        tv.textStorage?.endEditing()
        applyWrapIndent(to: tv, font: font, settings: settings)

        let safeLocation = min(sel.location, ns.length)
        let safeLength = min(sel.length, ns.length - safeLocation)
        tv.setSelectedRange(NSRange(location: safeLocation, length: safeLength))

        previousHighlightedLineRange = nil
        lastHighlightedText = text
        lastLanguage = language
        lastAppearance = settings?.appearanceOverride ?? "system"
    }

    // Custom attribute key for clickable link URLs
    public static let linkURLKey = NSAttributedString.Key("EdipadLinkURL")

    // Pre-compiled regex for URL highlighting
    private static let urlRegex = try! NSRegularExpression(
        pattern: "https?://\\S+", options: []
    )

    // Pre-compiled regex for list marker highlighting
    private static let bulletMarkerRegex = try! NSRegularExpression(
        pattern: "^[ \\t]*[-*](?= )", options: .anchorsMatchLines
    )
    private static let orderedMarkerRegex = try! NSRegularExpression(
        pattern: "^[ \\t]*\\d+\\.(?= )", options: .anchorsMatchLines
    )
    private static let checkboxRegex = try! NSRegularExpression(
        pattern: "^([ \\t]*[-*] )(\\[[ x]\\])( )(.*)",
        options: .anchorsMatchLines
    )

    private func applyListMarkers(tv: EditorTextView, text: String, theme: EditorTheme, settings: EditorSettings?) {
        guard language == "plain" || language == "markdown" else { return }

        let ns = text as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        let dashColor = theme.bulletDashColor
        let checkboxColor = theme.checkboxColor

        // Bullet dashes and asterisks
        if settings?.bulletListsEnabled ?? true {
            for match in Self.bulletMarkerRegex.matches(in: text, range: fullRange) {
                let r = match.range
                let markerRange = NSRange(location: r.location + r.length - 1, length: 1)
                tv.textStorage?.addAttribute(.foregroundColor, value: dashColor, range: markerRange)
            }
        }

        // Ordered numbers
        if settings?.numberedListsEnabled ?? true {
            for match in Self.orderedMarkerRegex.matches(in: text, range: fullRange) {
                let r = match.range
                tv.textStorage?.addAttribute(.foregroundColor, value: dashColor, range: r)
            }
        }

        // Checkbox styling
        guard settings?.checklistsEnabled ?? true else { return }
        for match in Self.checkboxRegex.matches(in: text, range: fullRange) {
            let bracketRange = match.range(at: 2)
            tv.textStorage?.addAttribute(.foregroundColor, value: checkboxColor, range: bracketRange)

            let bracketText = ns.substring(with: bracketRange)
            if bracketText == "[x]" {
                // Dim the entire line (prefix + content) for checked items
                let lineRange = match.range
                tv.textStorage?.addAttribute(.foregroundColor, value: theme.foreground.withAlphaComponent(0.4), range: lineRange)
                // Re-apply checkbox color on brackets so they stay visible
                tv.textStorage?.addAttribute(.foregroundColor, value: checkboxColor.withAlphaComponent(0.4), range: bracketRange)
                // Strikethrough on content
                let contentRange = match.range(at: 4)
                if contentRange.length > 0 {
                    tv.textStorage?.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: contentRange)
                    tv.textStorage?.addAttribute(.strikethroughColor, value: theme.foreground.withAlphaComponent(0.4), range: contentRange)
                }
            }
        }
    }

    private func applyLinkHighlighting(tv: EditorTextView, text: String, theme: EditorTheme, settings: EditorSettings?) {
        guard settings?.clickableLinks ?? true else { return }
        guard language == "plain" || language == "markdown" else { return }

        let ns = text as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        let linkColor = theme.linkColor

        for match in Self.urlRegex.matches(in: text, range: fullRange) {
            let r = match.range
            tv.textStorage?.addAttribute(.foregroundColor, value: linkColor, range: r)
            tv.textStorage?.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: r)
            tv.textStorage?.addAttribute(.underlineColor, value: linkColor, range: r)
            let urlString = ns.substring(with: r)
            tv.textStorage?.addAttribute(Self.linkURLKey, value: urlString, range: r)
        }
    }

    public func applyWrapIndent(to textView: EditorTextView, font: NSFont, settings: EditorSettings?) {
        guard let storage = textView.textStorage else { return }
        let ns = storage.string as NSString
        let totalLength = ns.length
        guard totalLength > 0 else { return }

        let tabWidth = settings?.tabWidth ?? 4
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width
        let tabPixelWidth = spaceWidth * CGFloat(tabWidth)

        storage.beginEditing()
        var pos = 0
        while pos < totalLength {
            let lineRange = ns.lineRange(for: NSRange(location: pos, length: 0))
            let lineText = ns.substring(with: lineRange)

            var indent: CGFloat = 0
            var i = lineRange.location
            let lineEnd = lineRange.location + lineRange.length
            while i < lineEnd {
                let ch = ns.character(at: i)
                if ch == 0x20 { indent += spaceWidth }
                else if ch == 0x09 { indent += tabPixelWidth }
                else { break }
                i += 1
            }

            // For list lines, indent wrapped text to content start (past the prefix)
            var headIndent = indent
            let cleanLine = lineText.hasSuffix("\n") ? String(lineText.dropLast()) : lineText
            if let settings, (language == "plain" || language == "markdown"),
               let match = ListHelper.parseLine(cleanLine), ListHelper.isKindEnabled(match.kind, settings: settings) {
                headIndent = CGFloat(match.contentStart) * spaceWidth
            }

            let para = NSMutableParagraphStyle()
            para.headIndent = headIndent
            storage.addAttribute(.paragraphStyle, value: para, range: lineRange)

            pos = lineRange.location + lineRange.length
        }
        storage.endEditing()
    }

    // MARK: - NSTextViewDelegate

    public func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? EditorTextView else { return }
        let text = tv.string
        tv.onTextChange?(text)
        updateCaretStatusAndHighlight()
        scheduleHighlightIfNeeded(text: text)
    }

    public func textViewDidChangeSelection(_ notification: Notification) {
        updateCaretStatusAndHighlight()
    }

    private func updateCaretStatusAndHighlight() {
        guard let tv = textView else { return }
        let ns = tv.string as NSString

        tv.textStorage?.beginEditing()

        // Only clear the previously highlighted line, not the entire document
        if let prev = previousHighlightedLineRange, prev.location + prev.length <= ns.length {
            tv.textStorage?.removeAttribute(.backgroundColor, range: prev)
        }

        if settings?.highlightCurrentLine ?? false {
            let sel = tv.selectedRange()
            let location = min(sel.location, ns.length)
            let lineRange = ns.lineRange(for: NSRange(location: location, length: 0))
            tv.textStorage?.addAttribute(
                .backgroundColor,
                value: NSColor.selectedTextBackgroundColor.withAlphaComponent(0.12),
                range: lineRange
            )
            previousHighlightedLineRange = lineRange
        } else {
            previousHighlightedLineRange = nil
        }

        tv.textStorage?.endEditing()
    }
}
