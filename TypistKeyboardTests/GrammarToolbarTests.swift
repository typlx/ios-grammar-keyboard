import XCTest
@testable import TypistKeyboard

final class GrammarToolbarTests: XCTestCase {

    private var toolbar: GrammarToolbar!

    override func setUp() {
        super.setUp()
        toolbar = GrammarToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(true)
        toolbar = nil
        super.tearDown()
    }

    // MARK: - Mirror helpers for private subviews

    private func fixButton() -> UIButton? {
        Mirror(reflecting: toolbar!).children
            .first(where: { $0.label == "fixButton" })?.value as? UIButton
    }

    private func previewLabel() -> UILabel? {
        Mirror(reflecting: toolbar!).children
            .first(where: { $0.label == "previewLabel" })?.value as? UILabel
    }

    private func activityIndicator() -> UIActivityIndicatorView? {
        Mirror(reflecting: toolbar!).children
            .first(where: { $0.label == "activityIndicator" })?.value as? UIActivityIndicatorView
    }

    // MARK: - showLoading

    func testShowLoadingDisablesFixButton() {
        toolbar.showLoading()
        XCTAssertFalse(fixButton()?.isEnabled ?? true, "Fix button should be disabled while loading")
    }

    func testShowLoadingStartsActivityIndicator() {
        toolbar.showLoading()
        XCTAssertTrue(activityIndicator()?.isAnimating ?? false, "Activity indicator should animate while loading")
    }

    func testShowLoadingClearsPreviewLabel() {
        toolbar.showPreview("old text")
        toolbar.showLoading()
        XCTAssertEqual(previewLabel()?.text ?? "non-empty", "", "Preview label should be empty while loading")
    }

    // MARK: - showPreview

    func testShowPreviewEnablesFixButton() {
        toolbar.showLoading()
        toolbar.showPreview("Hello, world!")
        XCTAssertTrue(fixButton()?.isEnabled ?? false, "Fix button should be re-enabled after preview")
    }

    func testShowPreviewStopsActivityIndicator() {
        toolbar.showLoading()
        toolbar.showPreview("Hello, world!")
        XCTAssertFalse(activityIndicator()?.isAnimating ?? true, "Activity indicator should stop after preview")
    }

    func testShowPreviewAddsArrowPrefix() {
        toolbar.showPreview("Hello, world!")
        XCTAssertEqual(previewLabel()?.text, "→ Hello, world!")
    }

    func testShowPreviewTruncatesTextOver40Chars() {
        let longText = String(repeating: "a", count: 50)
        toolbar.showPreview(longText)
        let labelText = previewLabel()?.text ?? ""
        XCTAssertTrue(labelText.hasSuffix("…"), "Preview should truncate long text with ellipsis")
        // "→ " (2) + 40 chars + "…" (1) = 43 displayed chars
        XCTAssertLessThanOrEqual(labelText.count, 46)
    }

    func testShowPreviewExactly40CharsNoEllipsis() {
        let exactText = String(repeating: "b", count: 40)
        toolbar.showPreview(exactText)
        let labelText = previewLabel()?.text ?? ""
        XCTAssertFalse(labelText.hasSuffix("…"), "40-char text should not be truncated")
        XCTAssertEqual(labelText, "→ \(exactText)")
    }

    func testShowPreviewSetsSecondaryLabelColor() {
        toolbar.showPreview("Corrected text")
        XCTAssertEqual(previewLabel()?.textColor, .secondaryLabel)
    }

    // MARK: - showError

    func testShowErrorEnablesFixButton() {
        toolbar.showLoading()
        toolbar.showError("Something failed")
        XCTAssertTrue(fixButton()?.isEnabled ?? false, "Fix button should be re-enabled after error")
    }

    func testShowErrorStopsActivityIndicator() {
        toolbar.showLoading()
        toolbar.showError("Something failed")
        XCTAssertFalse(activityIndicator()?.isAnimating ?? true, "Activity indicator should stop after error")
    }

    func testShowErrorSetsLabelText() {
        toolbar.showError("Network unavailable")
        XCTAssertEqual(previewLabel()?.text, "Network unavailable")
    }

    func testShowErrorSetsRedTextColor() {
        toolbar.showError("Error message")
        XCTAssertEqual(previewLabel()?.textColor, .systemRed)
    }

    // MARK: - reset

    func testResetEnablesFixButton() {
        toolbar.showLoading()
        toolbar.reset()
        XCTAssertTrue(fixButton()?.isEnabled ?? false, "Fix button should be enabled after reset")
    }

    func testResetStopsActivityIndicator() {
        toolbar.showLoading()
        toolbar.reset()
        XCTAssertFalse(activityIndicator()?.isAnimating ?? true, "Activity indicator should stop after reset")
    }

    func testResetClearsPreviewLabel() {
        toolbar.showPreview("Some correction")
        toolbar.reset()
        XCTAssertEqual(previewLabel()?.text ?? "non-empty", "", "Preview label should be empty after reset")
    }

    func testResetSetsSecondaryLabelColor() {
        toolbar.showError("Error")
        toolbar.reset()
        XCTAssertEqual(previewLabel()?.textColor, .secondaryLabel)
    }

    // MARK: - Delegate

    func testDelegateReceivesFixTap() {
        let delegate = MockGrammarToolbarDelegate()
        toolbar.delegate = delegate

        guard let button = fixButton() else {
            XCTFail("Could not find fix button via reflection")
            return
        }
        button.sendActions(for: .touchUpInside)

        XCTAssertTrue(delegate.didTapFixCalled, "Delegate should be notified when fix button is tapped")
    }

    func testDelegateIsWeaklyHeld() {
        var delegate: MockGrammarToolbarDelegate? = MockGrammarToolbarDelegate()
        toolbar.delegate = delegate
        XCTAssertNotNil(toolbar.delegate)
        delegate = nil
        XCTAssertNil(toolbar.delegate, "Delegate should be weakly held and nil after release")
    }
}

// MARK: - Helpers

private final class MockGrammarToolbarDelegate: GrammarToolbarDelegate {
    var didTapFixCalled = false
    func grammarToolbarDidTapFix(_ toolbar: GrammarToolbar) {
        didTapFixCalled = true
    }
}
