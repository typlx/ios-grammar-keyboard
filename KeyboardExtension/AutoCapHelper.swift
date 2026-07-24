import Foundation

/// Determines auto-capitalization eligibility based on text context.
/// Ported from Android AutoCapHelper.kt with iOS-specific adaptations.
enum AutoCapHelper {

    /// Sentence-ending punctuation characters that trigger auto-cap on the next word.
    private static let sentenceEnders: Set<Character> = [".", "!", "?"]

    /// Returns true when the next typed character should be automatically capitalized.
    ///
    /// Rules (in priority order):
    /// 1. Empty document → capitalize (start of text).
    /// 2. Text ends with a sentence-ender followed by one or more spaces → capitalize.
    /// 3. Text ends with a newline (start of a new paragraph) → capitalize.
    static func shouldCapitalize(after textBeforeCursor: String) -> Bool {
        guard !textBeforeCursor.isEmpty else { return true }

        // Walk backwards past trailing spaces / newlines to find the last non-space char.
        var index = textBeforeCursor.endIndex
        while index > textBeforeCursor.startIndex {
            let prev = textBeforeCursor.index(before: index)
            let ch = textBeforeCursor[prev]
            if ch == "\n" {
                return true
            }
            if ch == " " {
                index = prev
                continue
            }
            // Found a non-space, non-newline character.
            return sentenceEnders.contains(ch)
        }

        return false
    }

}
