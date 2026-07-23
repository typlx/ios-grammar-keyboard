import XCTest
@testable import TypistKeyboard

final class AutocorrectIndicatorTests: XCTestCase {

    private var machine: AutocorrectStateMachine!
    private var delegate: MockAutocorrectDelegate!

    override func setUp() {
        super.setUp()
        machine = AutocorrectStateMachine(dismissDelay: 0.05)
        delegate = MockAutocorrectDelegate()
        machine.delegate = delegate
    }

    override func tearDown() {
        machine = nil
        delegate = nil
        super.tearDown()
    }

    // MARK: - 1. Initial state

    func testInitialStateIsIdle() {
        XCTAssertEqual(machine.state, .idle)
    }

    // MARK: - 2. show() transitions

    func testShowTransitionsToShowingState() {
        machine.show(original: "teh", corrected: "the")
        XCTAssertEqual(machine.state, .showing(original: "teh", corrected: "the"))
    }

    func testShowCallsDelegateDidShowWithCorrectOriginal() {
        machine.show(original: "teh", corrected: "the")
        XCTAssertEqual(delegate.didShowOriginal, "teh")
    }

    func testShowCallsDelegateDidShowWithCorrectCorrected() {
        machine.show(original: "teh", corrected: "the")
        XCTAssertEqual(delegate.didShowCorrected, "the")
    }

    func testShowWhileAlreadyShowingReplacesState() {
        machine.show(original: "teh", corrected: "the")
        machine.show(original: "taht", corrected: "that")
        XCTAssertEqual(machine.state, .showing(original: "taht", corrected: "that"))
    }

    // MARK: - 3. undo() transitions

    func testUndoFromShowingResetsStateToIdle() {
        machine.show(original: "teh", corrected: "the")
        machine.undo()
        XCTAssertEqual(machine.state, .idle)
    }

    func testUndoCallsDelegateWithCorrectOriginalWord() {
        machine.show(original: "teh", corrected: "the")
        machine.undo()
        XCTAssertEqual(delegate.didUndoOriginal, "teh")
    }

    func testUndoCallsDelegateWithCorrectCorrectedWord() {
        machine.show(original: "teh", corrected: "the")
        machine.undo()
        XCTAssertEqual(delegate.didUndoCorrected, "the")
    }

    func testUndoCallsDelegateDismiss() {
        machine.show(original: "teh", corrected: "the")
        machine.undo()
        XCTAssertTrue(delegate.didDismiss)
    }

    func testUndoFromIdleIsNoOp() {
        machine.undo()
        XCTAssertNil(delegate.didUndoOriginal, "undo() while idle must not call delegate")
        XCTAssertFalse(delegate.didDismiss)
    }

    // MARK: - 4. dismiss() transitions

    func testDismissFromShowingResetsStateToIdle() {
        machine.show(original: "teh", corrected: "the")
        machine.dismiss()
        XCTAssertEqual(machine.state, .idle)
    }

    func testDismissFromShowingCallsDelegateDismiss() {
        machine.show(original: "teh", corrected: "the")
        machine.dismiss()
        XCTAssertTrue(delegate.didDismiss)
    }

    func testDismissFromIdleIsNoOp() {
        machine.dismiss()
        XCTAssertFalse(delegate.didDismiss, "dismiss() while idle must not call delegate")
    }

    // MARK: - 5. Timer auto-dismiss

    func testTimerAutoDismissesState() {
        let exp = expectation(description: "auto-dismiss")
        machine.show(original: "teh", corrected: "the")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.machine.state, .idle)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testTimerAutoDismissCallsDelegate() {
        let exp = expectation(description: "delegate dismiss called")
        machine.show(original: "teh", corrected: "the")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertTrue(self.delegate.didDismiss)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - 6. Timer cancellation

    func testUndoBeforeTimerFiresDoesNotTriggerLaterDismiss() {
        let exp = expectation(description: "no extra dismiss after undo")
        machine.show(original: "teh", corrected: "the")
        machine.undo()
        delegate.didDismiss = false // reset after undo's dismiss call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertFalse(self.delegate.didDismiss,
                           "timer must not fire a second dismiss after undo")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func testSecondShowCancelsFirstTimerAndStartsNew() {
        let exp = expectation(description: "only one dismiss after second show")
        machine.show(original: "teh", corrected: "the")
        machine.show(original: "taht", corrected: "that")
        delegate.dismissCount = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.delegate.dismissCount, 1,
                           "exactly one auto-dismiss must fire for the second show")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - 7. Multi-cycle correctness

    func testMultipleShowDismissCyclesWorkCorrectly() {
        machine.show(original: "teh", corrected: "the")
        machine.dismiss()
        machine.show(original: "taht", corrected: "that")
        XCTAssertEqual(machine.state, .showing(original: "taht", corrected: "that"))
    }

    func testShowAfterUndoWorksCorrectly() {
        machine.show(original: "teh", corrected: "the")
        machine.undo()
        machine.show(original: "freind", corrected: "friend")
        XCTAssertEqual(machine.state, .showing(original: "freind", corrected: "friend"))
    }

    // MARK: - 8. Delegate retention

    func testDelegateIsWeaklyHeld() {
        var local: MockAutocorrectDelegate? = MockAutocorrectDelegate()
        machine.delegate = local
        XCTAssertNotNil(machine.delegate)
        local = nil
        XCTAssertNil(machine.delegate, "delegate must be weakly held")
    }

    // MARK: - 9. AutocorrectDictionary

    func testKnownTypoReturnsCorrection() {
        XCTAssertEqual(AutocorrectDictionary.correction(for: "teh"), "the")
    }

    func testUnknownWordReturnsNil() {
        XCTAssertNil(AutocorrectDictionary.correction(for: "hello"))
    }
}

// MARK: - Mock

private final class MockAutocorrectDelegate: AutocorrectStateMachineDelegate {
    var didShowOriginal: String?
    var didShowCorrected: String?
    var didDismiss = false
    var dismissCount = 0
    var didUndoOriginal: String?
    var didUndoCorrected: String?

    func autocorrectStateMachine(_ machine: AutocorrectStateMachine, didShow original: String, corrected: String) {
        didShowOriginal = original
        didShowCorrected = corrected
    }

    func autocorrectStateMachineDidDismiss(_ machine: AutocorrectStateMachine) {
        didDismiss = true
        dismissCount += 1
    }

    func autocorrectStateMachine(_ machine: AutocorrectStateMachine, didUndo original: String, corrected: String) {
        didUndoOriginal = original
        didUndoCorrected = corrected
    }
}
