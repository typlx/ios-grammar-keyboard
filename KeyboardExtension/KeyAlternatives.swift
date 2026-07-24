import Foundation

struct KeyAlternatives {

    // MARK: - QWERTY layout alternatives

    static let qwerty: [String: [String]] = [
        "a": ["à", "á", "â", "ã", "ä", "å", "æ"],
        "c": ["ç", "ć", "č"],
        "d": ["ð"],
        "e": ["è", "é", "ê", "ë"],
        "i": ["ì", "í", "î", "ï"],
        "l": ["ł"],
        "n": ["ñ"],
        "o": ["ò", "ó", "ô", "õ", "ö", "ø"],
        "r": ["ř"],
        "s": ["ß", "ś", "š"],
        "t": ["þ"],
        "u": ["ù", "ú", "û", "ü"],
        "y": ["ý", "ÿ"],
        "z": ["ž", "ź", "ż"],
    ]

    static func alternatives(for key: String) -> [String] {
        qwerty[key.lowercased()] ?? []
    }
}
