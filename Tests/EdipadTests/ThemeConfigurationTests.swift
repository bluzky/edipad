import XCTest
@testable import Edipad

final class ThemeConfigurationTests: XCTestCase {

    func testEditorThemeWithoutCSSPath() {
        let theme = EditorTheme(
            isDark: true,
            background: .black,
            foreground: .white
        )

        XCTAssertTrue(theme.isDark)
        XCTAssertEqual(theme.background, .black)
        XCTAssertEqual(theme.foreground, .white)
        XCTAssertNil(theme.cssPath)
    }

    func testEditorThemeWithCSSPath() {
        let cssPath = URL(fileURLWithPath: "/tmp/test-theme.css")
        let theme = EditorTheme(
            isDark: false,
            background: .white,
            foreground: .black,
            cssPath: cssPath
        )

        XCTAssertFalse(theme.isDark)
        XCTAssertEqual(theme.background, .white)
        XCTAssertEqual(theme.foreground, .black)
        XCTAssertEqual(theme.cssPath, cssPath)
    }

    func testThemeConfigurationInit() {
        let darkTheme = EditorTheme(
            isDark: true,
            background: .black,
            foreground: .white
        )

        let lightTheme = EditorTheme(
            isDark: false,
            background: .white,
            foreground: .black
        )

        let config = ThemeConfiguration(
            darkTheme: darkTheme,
            lightTheme: lightTheme
        )

        XCTAssertTrue(config.darkTheme.isDark)
        XCTAssertFalse(config.lightTheme.isDark)
    }

    func testDefaultEditorSettingsWithoutCustomTheme() {
        let settings = DefaultEditorSettings()
        XCTAssertNil(settings.customThemeConfig)
    }

    func testDefaultEditorSettingsWithCustomTheme() {
        let darkTheme = EditorTheme(
            isDark: true,
            background: .black,
            foreground: .white
        )

        let lightTheme = EditorTheme(
            isDark: false,
            background: .white,
            foreground: .black
        )

        let themeConfig = ThemeConfiguration(
            darkTheme: darkTheme,
            lightTheme: lightTheme
        )

        let settings = DefaultEditorSettings(customThemeConfig: themeConfig)

        XCTAssertNotNil(settings.customThemeConfig)
        XCTAssertTrue(settings.customThemeConfig?.darkTheme.isDark ?? false)
        XCTAssertFalse(settings.customThemeConfig?.lightTheme.isDark ?? true)
    }

    func testThemeConfigurationFromCSSWithInvalidPaths() {
        let darkCSS = URL(fileURLWithPath: "/nonexistent/dark.css")
        let lightCSS = URL(fileURLWithPath: "/nonexistent/light.css")

        let config = ThemeConfiguration.fromCSS(
            darkCSSPath: darkCSS,
            lightCSSPath: lightCSS
        )

        XCTAssertNil(config, "Should return nil for nonexistent CSS files")
    }

    func testEditorThemeDefaultColors() {
        let darkDefault = EditorTheme.dark
        let lightDefault = EditorTheme.light

        XCTAssertTrue(darkDefault.isDark)
        XCTAssertFalse(lightDefault.isDark)

        // Verify bullet/checkbox/link colors exist
        XCTAssertNotNil(darkDefault.bulletDashColor)
        XCTAssertNotNil(darkDefault.checkboxColor)
        XCTAssertNotNil(darkDefault.linkColor)

        XCTAssertNotNil(lightDefault.bulletDashColor)
        XCTAssertNotNil(lightDefault.checkboxColor)
        XCTAssertNotNil(lightDefault.linkColor)
    }

    func testInsertionPointColor() {
        let darkTheme = EditorTheme(
            isDark: true,
            background: .black,
            foreground: .white
        )

        let lightTheme = EditorTheme(
            isDark: false,
            background: .white,
            foreground: .black
        )

        XCTAssertEqual(darkTheme.insertionPointColor, .white)
        XCTAssertEqual(lightTheme.insertionPointColor, .black)
    }
}
