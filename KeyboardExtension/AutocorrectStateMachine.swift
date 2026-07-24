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
        let timer = Timer(timeInterval: dismissDelay, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
        RunLoop.main.add(timer, forMode: .common)
        dismissTimer = timer
    }

    private func cancelTimer() {
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}

// MARK: - Common typo corrections applied on space

enum AutocorrectDictionary {
    static let corrections: [String: String] = [
        // Original 18
        "teh": "the",
        "hte": "the",
        "taht": "that",
        "thier": "their",
        "wiht": "with",
        "adn": "and",
        "nad": "and",
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
        "existance": "existence",
        // Common transpositions / dropped letters
        "thna": "than",
        "wnat": "want",
        "waht": "what",
        "wehn": "when",
        "whre": "where",
        "whih": "which",
        "hwo": "how",
        "nwo": "now",
        "owuld": "would",
        "coudl": "could",
        "shoudl": "should",
        "woudl": "would",
        "mkae": "make",
        "maek": "make",
        "jsut": "just",
        "jstu": "just",
        "fomr": "from",
        "thme": "them",
        "ther": "there",
        "thre": "there",
        "hree": "here",
        "hwere": "where",
        "mroe": "more",
        "moer": "more",
        "ovre": "over",
        "tahn": "than",
        "ot": "to",
        "fo": "of",
        "od": "do",
        "si": "is",
        "ti": "it",
        "ro": "or",
        "nto": "not",
        "ont": "not",
        "acn": "can",
        "cna": "can",
        "hav": "have",
        "hava": "have",
        "abotu": "about",
        "aobut": "about",
        "beofre": "before",
        "befroe": "before",
        "berfoe": "before",
        "afetr": "after",
        "aftre": "after",
        "becuase": "because",
        "becasue": "because",
        "beacuse": "because",
        "becouse": "because",
        "whcih": "which",
        "thign": "thing",
        "htink": "think",
        "thnk": "think",
        "knwo": "know",
        "konw": "know",
        "konws": "knows",
        "sayd": "said",
        "nda": "and",
        "dna": "and",
        "yuo": "you",
        "oyu": "you",
        "youre": "you're",
        "theyre": "they're",
        "dont": "don't",
        "doesnt": "doesn't",
        "didnt": "didn't",
        "wont": "won't",
        "cant": "can't",
        "isnt": "isn't",
        "arent": "aren't",
        "wasnt": "wasn't",
        "werent": "weren't",
        "hadnt": "hadn't",
        "hasnt": "hasn't",
        "havent": "haven't",
        "shouldnt": "shouldn't",
        "wouldnt": "wouldn't",
        "couldnt": "couldn't",
        "mightnt": "mightn't",
        "mustnt": "mustn't",
        "ive": "I've",
        "im": "I'm",
        "ill": "I'll",
        "id": "I'd",
        // Double letters / spelling errors
        "accomodate": "accommodate",
        "acommodate": "accommodate",
        "achive": "achieve",
        "acheive": "achieve",
        "accross": "across",
        "agressive": "aggressive",
        "agresive": "aggressive",
        "apparant": "apparent",
        "apparrent": "apparent",
        "apperance": "appearance",
        "arguement": "argument",
        "assasinate": "assassinate",
        "basicaly": "basically",
        "basiclly": "basically",
        "calander": "calendar",
        "calandar": "calendar",
        "catagory": "category",
        "catigory": "category",
        "cemetary": "cemetery",
        "charachter": "character",
        "charcter": "character",
        "collegue": "colleague",
        "colege": "college",
        "comming": "coming",
        "commitee": "committee",
        "committe": "committee",
        "completly": "completely",
        "concious": "conscious",
        "consciense": "conscience",
        "convinience": "convenience",
        "convienience": "convenience",
        "convienient": "convenient",
        "currantly": "currently",
        "dependant": "dependent",
        "desparate": "desperate",
        "dissapear": "disappear",
        "dissapoint": "disappoint",
        "embarass": "embarrass",
        "enviroment": "environment",
        "excede": "exceed",
        "excelent": "excellent",
        "existance": "existence",
        "experiance": "experience",
        "experince": "experience",
        "explaination": "explanation",
        "facinating": "fascinating",
        "firey": "fiery",
        "foriegn": "foreign",
        "fourty": "forty",
        "futher": "further",
        "goverment": "government",
        "govermant": "government",
        "grammer": "grammar",
        "gaurd": "guard",
        "happend": "happened",
        "harrass": "harass",
        "hieght": "height",
        "humerous": "humorous",
        "immedietly": "immediately",
        "incidently": "incidentally",
        "independance": "independence",
        "infered": "inferred",
        "innoculate": "inoculate",
        "intellegence": "intelligence",
        "intresting": "interesting",
        "knowlege": "knowledge",
        "knowlegde": "knowledge",
        "labratory": "laboratory",
        "layed": "laid",
        "liason": "liaison",
        "lible": "libel",
        "liscense": "license",
        "lightening": "lightning",
        "managment": "management",
        "millenium": "millennium",
        "mispell": "misspell",
        "neccessary": "necessary",
        "neigbour": "neighbour",
        "nieghbor": "neighbor",
        "noticeable": "noticeable",
        "ocasion": "occasion",
        "ocassion": "occasion",
        "occassion": "occasion",
        "occurence": "occurrence",
        "occurrance": "occurrence",
        "ofcourse": "of course",
        "oppurtunity": "opportunity",
        "oportunity": "opportunity",
        "peice": "piece",
        "persistance": "persistence",
        "pharase": "phrase",
        "posession": "possession",
        "potatos": "potatoes",
        "preferance": "preference",
        "previos": "previous",
        "priviledge": "privilege",
        "privilige": "privilege",
        "proably": "probably",
        "probaly": "probably",
        "propbably": "probably",
        "publically": "publicly",
        "questionaire": "questionnaire",
        "readible": "readable",
        "recomend": "recommend",
        "reccomend": "recommend",
        "refering": "referring",
        "relevent": "relevant",
        "relevent": "relevant",
        "religous": "religious",
        "remeber": "remember",
        "rember": "remember",
        "repitition": "repetition",
        "resistence": "resistance",
        "rythm": "rhythm",
        "rythem": "rhythm",
        "sacrafice": "sacrifice",
        "seige": "siege",
        "sence": "sense",
        "sentance": "sentence",
        "similer": "similar",
        "sincerly": "sincerely",
        "speach": "speech",
        "succesful": "successful",
        "sucessful": "successful",
        "supose": "suppose",
        "suprise": "surprise",
        "surprize": "surprise",
        "temperament": "temperament",
        "tendancy": "tendency",
        "therefor": "therefore",
        "tomarrow": "tomorrow",
        "tommorrow": "tomorrow",
        "tommorow": "tomorrow",
        "tomorow": "tomorrow",
        "tounge": "tongue",
        "truely": "truly",
        "twelth": "twelfth",
        "tyrany": "tyranny",
        "underate": "underrate",
        "unfortuante": "unfortunate",
        "unfortunatly": "unfortunately",
        "uniuqe": "unique",
        "untill": "until",
        "usefull": "useful",
        "usally": "usually",
        "usualy": "usually",
        "vaccum": "vacuum",
        "visious": "vicious",
        "visable": "visible",
        "wheather": "whether",
        "wich": "which",
        "writting": "writing",
        "yesturday": "yesterday",
        "yuo": "you",
        "zeal": "zeal",
    ]

    /// Returns the lowercased correction, preserving the case pattern of the original word.
    static func correction(for word: String) -> String? {
        guard let corrected = corrections[word.lowercased()] else { return nil }
        return preserveCase(of: word, applyingTo: corrected)
    }

    /// Mirrors the case pattern of `original` onto `target`.
    /// ALL_CAPS → ALL_CAPS, Capitalized → Capitalized, lowercase → lowercase.
    static func preserveCase(of original: String, applyingTo target: String) -> String {
        if original == original.uppercased() && original.count > 1 {
            return target.uppercased()
        }
        if let first = original.first, first.isUppercase {
            return target.prefix(1).uppercased() + target.dropFirst()
        }
        return target
    }
}
