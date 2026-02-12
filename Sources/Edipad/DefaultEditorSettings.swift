import AppKit
import Combine

/// Default implementation of EditorSettings with sensible defaults.
/// Use this as a starting point or create your own implementation.
public final class DefaultEditorSettings: EditorSettings, ObservableObject {

    @Published public var font: NSFont
    @Published public var showLineNumbers: Bool
    @Published public var wordWrap: Bool
    @Published public var highlightCurrentLine: Bool
    @Published public var indentUsingSpaces: Bool
    @Published public var tabWidth: Int
    @Published public var bulletListsEnabled: Bool
    @Published public var numberedListsEnabled: Bool
    @Published public var checklistsEnabled: Bool
    @Published public var clickableLinks: Bool
    @Published public var appearanceOverride: String
    @Published public var customThemeConfig: ThemeConfiguration?

    private var cancellables = Set<AnyCancellable>()
    private let settingsChangedSubject = PassthroughSubject<Void, Never>()

    public var settingsChangedPublisher: AnyPublisher<Void, Never> {
        settingsChangedSubject.eraseToAnyPublisher()
    }

    public init(
        font: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular),
        showLineNumbers: Bool = true,
        wordWrap: Bool = true,
        highlightCurrentLine: Bool = false,
        indentUsingSpaces: Bool = true,
        tabWidth: Int = 4,
        bulletListsEnabled: Bool = true,
        numberedListsEnabled: Bool = true,
        checklistsEnabled: Bool = true,
        clickableLinks: Bool = true,
        appearanceOverride: String = "system",
        customThemeConfig: ThemeConfiguration? = nil
    ) {
        self.font = font
        self.showLineNumbers = showLineNumbers
        self.wordWrap = wordWrap
        self.highlightCurrentLine = highlightCurrentLine
        self.indentUsingSpaces = indentUsingSpaces
        self.tabWidth = tabWidth
        self.bulletListsEnabled = bulletListsEnabled
        self.numberedListsEnabled = numberedListsEnabled
        self.checklistsEnabled = checklistsEnabled
        self.clickableLinks = clickableLinks
        self.appearanceOverride = appearanceOverride
        self.customThemeConfig = customThemeConfig

        setupObservers()
    }

    private func setupObservers() {
        objectWillChange
            .sink { [weak self] _ in
                self?.settingsChangedSubject.send()
            }
            .store(in: &cancellables)
    }
}
