import XCTest
@testable import TypistKeyboard

final class SystemPromptsTests: XCTestCase {

    // MARK: - Context types

    func testGeneralPromptMentionsGrammar() {
        let prompt = SystemPrompts.prompt(for: .general)
        XCTAssertTrue(prompt.lowercased().contains("grammar"), "General prompt should mention grammar")
    }

    func testGeneralPromptInstructsReturnOnlyCorrectedText() {
        let prompt = SystemPrompts.prompt(for: .general)
        XCTAssertTrue(prompt.contains("Return only the corrected text"))
    }

    func testEmailPromptMentionsEmail() {
        let prompt = SystemPrompts.prompt(for: .email)
        XCTAssertTrue(prompt.lowercased().contains("email"), "Email prompt should be email-specific")
    }

    func testEmailPromptMentionsProfessionalTone() {
        let prompt = SystemPrompts.prompt(for: .email)
        XCTAssertTrue(prompt.lowercased().contains("professional"), "Email prompt should reference professional tone")
    }

    func testChatPromptMentionsCasual() {
        let prompt = SystemPrompts.prompt(for: .chat)
        XCTAssertTrue(prompt.lowercased().contains("casual"), "Chat prompt should preserve casual tone")
    }

    func testEssayPromptMentionsAcademic() {
        let prompt = SystemPrompts.prompt(for: .essay)
        XCTAssertTrue(prompt.lowercased().contains("academic"), "Essay prompt should reference academic writing")
    }

    func testCodeCommentPromptMentionsCode() {
        let prompt = SystemPrompts.prompt(for: .codeComment)
        let lower = prompt.lowercased()
        XCTAssertTrue(lower.contains("code") || lower.contains("documentation"), "Code comment prompt should reference code/documentation")
    }

    func testCodeCommentPromptPreservesTechnicalTerminology() {
        let prompt = SystemPrompts.prompt(for: .codeComment)
        XCTAssertTrue(prompt.lowercased().contains("technical terminology") || prompt.contains("variable names"),
                      "Code comment prompt should warn to preserve technical terms")
    }

    func testAllContextTypesReturnNonEmptyPrompts() {
        for context in ContextType.allCases {
            let prompt = SystemPrompts.prompt(for: context)
            XCTAssertFalse(prompt.isEmpty, "Prompt for \(context.rawValue) should not be empty")
        }
    }

    func testAllContextTypesAreDistinct() {
        let prompts = ContextType.allCases.map { SystemPrompts.prompt(for: $0) }
        let unique = Set(prompts)
        XCTAssertEqual(unique.count, prompts.count, "Each context type should produce a distinct prompt")
    }

    // MARK: - Language instruction

    func testEnglishPromptHasNoLanguageAddition() {
        let prompt = SystemPrompts.prompt(for: .general, language: .english)
        XCTAssertFalse(prompt.contains("Always respond in"), "English should not add a language instruction")
    }

    func testSpanishPromptAddsLanguageInstruction() {
        let prompt = SystemPrompts.prompt(for: .general, language: .spanish)
        XCTAssertTrue(prompt.contains("Spanish"), "Spanish prompt should reference Spanish")
        XCTAssertTrue(prompt.contains("Always respond in"), "Non-English prompts should add language instruction")
    }

    func testFrenchPromptAddsLanguageInstruction() {
        let prompt = SystemPrompts.prompt(for: .general, language: .french)
        XCTAssertTrue(prompt.contains("French"), "French prompt should reference French")
    }

    func testGermanPromptAddsLanguageInstruction() {
        let prompt = SystemPrompts.prompt(for: .general, language: .german)
        XCTAssertTrue(prompt.contains("German"), "German prompt should reference German")
    }

    func testPortuguesePromptAddsLanguageInstruction() {
        let prompt = SystemPrompts.prompt(for: .general, language: .portuguese)
        XCTAssertTrue(prompt.contains("Portuguese"), "Portuguese prompt should reference Portuguese")
    }

    func testItalianPromptAddsLanguageInstruction() {
        let prompt = SystemPrompts.prompt(for: .general, language: .italian)
        XCTAssertTrue(prompt.contains("Italian"), "Italian prompt should reference Italian")
    }

    func testLanguageInstructionAppearsAcrossAllContexts() {
        for context in ContextType.allCases {
            let prompt = SystemPrompts.prompt(for: context, language: .spanish)
            XCTAssertTrue(prompt.contains("Spanish"),
                          "Language instruction should be added for \(context.rawValue) context")
        }
    }

    func testDefaultLanguageIsEnglish() {
        let withDefault = SystemPrompts.prompt(for: .general)
        let withEnglish = SystemPrompts.prompt(for: .general, language: .english)
        XCTAssertEqual(withDefault, withEnglish, "Default language parameter should be English")
    }

    // MARK: - CorrectionLanguage display names

    func testLanguageDisplayNames() {
        XCTAssertEqual(CorrectionLanguage.english.displayName, "English")
        XCTAssertEqual(CorrectionLanguage.spanish.displayName, "Spanish")
        XCTAssertEqual(CorrectionLanguage.french.displayName, "French")
        XCTAssertEqual(CorrectionLanguage.german.displayName, "German")
        XCTAssertEqual(CorrectionLanguage.portuguese.displayName, "Portuguese")
        XCTAssertEqual(CorrectionLanguage.italian.displayName, "Italian")
    }

    func testLanguageRawValues() {
        XCTAssertEqual(CorrectionLanguage.english.rawValue, "en")
        XCTAssertEqual(CorrectionLanguage.spanish.rawValue, "es")
        XCTAssertEqual(CorrectionLanguage.french.rawValue, "fr")
        XCTAssertEqual(CorrectionLanguage.german.rawValue, "de")
        XCTAssertEqual(CorrectionLanguage.portuguese.rawValue, "pt")
        XCTAssertEqual(CorrectionLanguage.italian.rawValue, "it")
    }

    // MARK: - ContextType raw values

    func testContextTypeRawValues() {
        XCTAssertEqual(ContextType.general.rawValue, "general")
        XCTAssertEqual(ContextType.email.rawValue, "email")
        XCTAssertEqual(ContextType.chat.rawValue, "chat")
        XCTAssertEqual(ContextType.essay.rawValue, "essay")
        XCTAssertEqual(ContextType.codeComment.rawValue, "code_comment")
    }
}
