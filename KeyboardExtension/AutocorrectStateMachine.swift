import Foundation

enum AutocorrectIndicatorState: Equatable {
    case idle
    case showing(original: String, corrected: String)
}

protocol AutocorrectStateMachineDelegate: AnyObject {
    func autocorrectStateMachine(_ machine: AutocorrectStateMachine, didShow original: String, corrected: String)
    func autocorrectStateMachineDidDismiss(_ machine: AutocorrectStateMachine)
    func autocorrectStateMachine(_ machine: AutocorrectStateMachine, didUndo original: String, corrected: String)
}

final class AutocorrectStateMachine {
    private(set) var state: AutocorrectIndicatorState = .idle
    weak var delegate: AutocorrectStateMachineDelegate?

    let dismissDelay: TimeInterval
    private var dismissTimer: Timer?

    init(dismissDelay: TimeInterval = 3.0) {
        self.dismissDelay = dismissDelay
    }

    func show(original: String, corrected: String) {
        cancelTimer()
        state = .showing(original: original, corrected: corrected)
        delegate?.autocorrectStateMachine(self, didShow: original, corrected: corrected)
        scheduleDismiss()
    }

    func undo() {
        guard case .showing(let original, let corrected) = state else { return }
        cancelTimer()
        state = .idle
        delegate?.autocorrectStateMachine(self, didUndo: original, corrected: corrected)
        delegate?.autocorrectStateMachineDidDismiss(self)
    }

    func dismiss() {
        guard case .showing = state else { return }
        cancelTimer()
        state = .idle
        delegate?.autocorrectStateMachineDidDismiss(self)
    }

    private func scheduleDismiss() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: dismissDelay, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }

    private func cancelTimer() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}

// MARK: - Common typo corrections applied on space

enum AutocorrectDictionary {
    static let corrections: [String: String] = [
        "teh": "the",
        "hte": "the",
        "taht": "that",
        "thier": "their",
        "wiht": "with",
        "adn": "and",
        "nad": "and",
        "fo": "of",
        "ot": "to",
        "siad": "said",
        "recieve": "receive",
        "beleive": "believe",
        "seperate": "separate",
        "occured": "occurred",
        "untill": "until",
        "begining": "beginning",
        "definately": "definitely",
        "freind": "friend",
        "enviroment": "environment",
        "existance": "existence"
    ]

    static func correction(for word: String) -> String? {
        corrections[word]
    }
}
