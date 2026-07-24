import Foundation

/// Offline prefix-completion and bigram next-word predictor.
///
/// Built-in dictionary: ~300 common English words ranked by frequency.
/// Learned words and bigrams are persisted in UserDefaults so the engine
/// improves as the user types.
final class WordPredictionEngine {

    // MARK: - Trie

    private final class TrieNode {
        var children: [Character: TrieNode] = [:]
        var isWord: Bool = false
        var score: Int = 0
    }

    private let trie = TrieNode()

    // MARK: - Persistence

    private let learnedKey = "WordPredictionEngine.learned"
    private let bigramKey  = "WordPredictionEngine.bigrams"

    private var learnedScores: [String: Int] = [:]
    private var bigramTable:   [String: [String: Int]] = [:]

    let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = AppGroupConfig.sharedDefaults) {
        self.defaults = defaults
        buildBuiltinTrie()
        loadLearned()
    }

    // MARK: - Public API

    /// Prefix completions for the word the user is currently typing.
    /// Returns up to 3 candidates ranked by frequency.
    func suggestions(for prefix: String) -> [String] {
        suggestions(for: prefix, context: nil)
    }

    /// Prefix completions with optional bigram boost from the previous committed word.
    /// Pass an empty prefix to get pure next-word predictions from the bigram table.
    func suggestions(for prefix: String, context: String?) -> [String] {
        // Validate: non-empty prefix must be all letters
        if !prefix.isEmpty && !prefix.allSatisfy({ $0.isLetter }) { return [] }

        if prefix.isEmpty {
            // Next-word prediction only
            guard let ctx = context, ctx.count >= 2 else { return [] }
            let ctxKey = ctx.lowercased()
            guard let nextWords = bigramTable[ctxKey], !nextWords.isEmpty else { return [] }
            return Array(nextWords.sorted { $0.value > $1.value }.prefix(3).map(\.key))
        }

        // Traverse trie to the prefix node
        let lower = prefix.lowercased()
        var node = trie
        for ch in lower {
            guard let next = node.children[ch] else { return [] }
            node = next
        }

        // Collect all completions
        var scored: [(word: String, score: Int)] = []
        collectWords(from: node, prefix: lower, into: &scored)

        // Bigram boost: context must be at least 2 characters
        if let ctx = context, ctx.count >= 2 {
            let ctxKey = ctx.lowercased()
            if let nextWords = bigramTable[ctxKey] {
                for idx in scored.indices {
                    if let boost = nextWords[scored[idx].word] {
                        scored[idx].score += boost * 1_000
                    }
                }
            }
        }

        return Array(scored.sorted { $0.score > $1.score }.prefix(3).map(\.word))
    }

    /// Record a committed word and optionally the word that preceded it.
    /// Words shorter than 2 characters or containing non-letter characters are ignored.
    /// Single-character previous words are ignored for bigram purposes.
    func learn(word: String, after prev: String?) {
        guard word.count >= 2, word.allSatisfy({ $0.isLetter }) else { return }
        let wordKey = word.lowercased()

        // Increment learned frequency and re-insert into trie with elevated score
        learnedScores[wordKey, default: 0] += 1
        let learnedScore = 10_000 + learnedScores[wordKey]! * 100
        insertIntoTrie(word: wordKey, score: learnedScore)

        // Store bigram
        if let prev = prev, prev.count >= 2, prev.allSatisfy({ $0.isLetter }) {
            let prevKey = prev.lowercased()
            bigramTable[prevKey, default: [:]][wordKey, default: 0] += 1
        }

        persist()
    }

    // MARK: - Trie helpers

    private func insertIntoTrie(word: String, score: Int) {
        var node = trie
        for ch in word {
            if node.children[ch] == nil {
                node.children[ch] = TrieNode()
            }
            node = node.children[ch]!
        }
        node.isWord = true
        if score > node.score { node.score = score }
    }

    private func collectWords(from node: TrieNode,
                              prefix: String,
                              into result: inout [(word: String, score: Int)]) {
        if node.isWord {
            result.append((prefix, node.score))
        }
        for (ch, child) in node.children {
            collectWords(from: child, prefix: prefix + String(ch), into: &result)
        }
    }

    // MARK: - Persistence

    private func loadLearned() {
        if let dict = defaults.object(forKey: learnedKey) as? [String: Int] {
            learnedScores = dict
            for (word, count) in dict {
                insertIntoTrie(word: word, score: 10_000 + count * 100)
            }
        }
        if let dict = defaults.object(forKey: bigramKey) as? [String: [String: Int]] {
            bigramTable = dict
        }
    }

    private func persist() {
        defaults.set(learnedScores, forKey: learnedKey)
        defaults.set(bigramTable,   forKey: bigramKey)
    }

    // MARK: - Built-in dictionary

    private func buildBuiltinTrie() {
        for (word, score) in WordPredictionEngine.builtinWords {
            insertIntoTrie(word: word, score: score)
        }
    }

    // ~300 most common English words ranked by frequency (score = rank × 10).
    // All words are lowercase, letters only, and at most 19 characters.
    private static let builtinWords: [(String, Int)] = [
        ("the", 9990), ("be", 9980), ("to", 9970), ("of", 9960), ("and", 9950),
        ("in", 9940), ("that", 9930), ("have", 9920), ("it", 9910), ("for", 9900),
        ("not", 9890), ("on", 9880), ("with", 9870), ("he", 9860), ("as", 9850),
        ("you", 9840), ("do", 9830), ("at", 9820), ("this", 9810), ("but", 9800),
        ("his", 9790), ("by", 9780), ("from", 9770), ("they", 9760), ("we", 9750),
        ("say", 9740), ("her", 9730), ("she", 9720), ("or", 9710), ("an", 9700),
        ("will", 9690), ("my", 9680), ("one", 9670), ("all", 9660), ("would", 9650),
        ("there", 9640), ("their", 9630), ("what", 9620), ("so", 9610), ("up", 9600),
        ("out", 9590), ("if", 9580), ("about", 9570), ("who", 9560), ("get", 9550),
        ("which", 9540), ("go", 9530), ("me", 9520), ("when", 9510), ("make", 9500),
        ("can", 9490), ("like", 9480), ("time", 9470), ("no", 9460), ("just", 9450),
        ("him", 9440), ("know", 9430), ("take", 9420), ("people", 9410), ("into", 9400),
        ("year", 9390), ("your", 9380), ("good", 9370), ("some", 9360), ("could", 9350),
        ("them", 9340), ("see", 9330), ("other", 9320), ("than", 9310), ("then", 9300),
        ("now", 9290), ("look", 9280), ("only", 9270), ("come", 9260), ("its", 9250),
        ("over", 9240), ("think", 9230), ("also", 9220), ("back", 9210), ("after", 9200),
        ("use", 9190), ("two", 9180), ("how", 9170), ("our", 9160), ("work", 9150),
        ("first", 9140), ("well", 9130), ("way", 9120), ("even", 9110), ("new", 9100),
        ("want", 9090), ("because", 9080), ("any", 9070), ("these", 9060), ("give", 9050),
        ("day", 9040), ("most", 9030), ("between", 9020), ("need", 9010), ("large", 9000),
        ("often", 8990), ("hand", 8980), ("high", 8970), ("place", 8960), ("hold", 8950),
        ("world", 8940), ("found", 8930), ("still", 8920), ("learn", 8910), ("should", 8900),
        ("each", 8890), ("both", 8880), ("those", 8870), ("been", 8860), ("very", 8850),
        ("same", 8840), ("left", 8830), ("life", 8820), ("few", 8810), ("open", 8800),
        ("seem", 8790), ("together", 8780), ("next", 8770), ("white", 8760), ("begin", 8750),
        ("got", 8740), ("walk", 8730), ("example", 8720), ("paper", 8710), ("group", 8700),
        ("always", 8690), ("book", 8680), ("letter", 8670), ("until", 8660), ("car", 8650),
        ("care", 8640), ("second", 8630), ("enough", 8620), ("girl", 8610), ("young", 8600),
        ("ready", 8590), ("above", 8580), ("ever", 8570), ("list", 8560), ("though", 8550),
        ("feel", 8540), ("talk", 8530), ("soon", 8520), ("measure", 8510), ("door", 8500),
        ("product", 8490), ("black", 8480), ("short", 8470), ("class", 8460), ("wind", 8450),
        ("question", 8440), ("happen", 8430), ("complete", 8420), ("area", 8410), ("half", 8400),
        ("rock", 8390), ("order", 8380), ("fire", 8370), ("since", 8360), ("top", 8350),
        ("whole", 8340), ("space", 8330), ("best", 8320), ("hour", 8310), ("better", 8300),
        ("true", 8290), ("during", 8280), ("five", 8270), ("remember", 8260), ("step", 8250),
        ("early", 8240), ("west", 8230), ("ground", 8220), ("interest", 8210), ("reach", 8200),
        ("fast", 8190), ("together", 8180), ("must", 8170), ("might", 8160), ("move", 8150),
        ("every", 8140), ("great", 8130), ("where", 8120), ("right", 8110), ("help", 8100),
        ("being", 8090), ("real", 8080), ("again", 8070), ("same", 8060), ("turn", 8050),
        ("much", 8040), ("going", 8030), ("long", 8020), ("before", 8010), ("little", 8000),
        ("don", 7990), ("put", 7980), ("let", 7970), ("set", 7960), ("here", 7950),
        ("keep", 7940), ("while", 7930), ("love", 7920), ("home", 7910), ("thank", 7900),
        ("call", 7890), ("came", 7880), ("came", 7870), ("case", 7860), ("catch", 7850),
        ("name", 7840), ("last", 7830), ("never", 7820), ("became", 7810), ("become", 7800),
        ("tell", 7790), ("ask", 7780), ("hand", 7770), ("play", 7760), ("small", 7750),
        ("number", 7740), ("away", 7730), ("word", 7720), ("water", 7710), ("long", 7700),
        ("down", 7690), ("side", 7680), ("been", 7670), ("know", 7660), ("place", 7650),
        ("show", 7640), ("head", 7630), ("end", 7620), ("his", 7610), ("city", 7600),
        ("night", 7590), ("live", 7580), ("point", 7570), ("sun", 7560), ("four", 7550),
        ("hard", 7540), ("start", 7530), ("might", 7520), ("story", 7510), ("saw", 7500),
        ("far", 7490), ("sea", 7480), ("drew", 7470), ("left", 7460), ("late", 7450),
        ("run", 7440), ("read", 7430), ("grow", 7420), ("idea", 7410), ("light", 7400),
        ("voice", 7390), ("power", 7380), ("town", 7370), ("fine", 7360), ("drive", 7350),
        ("break", 7340), ("north", 7330), ("south", 7320), ("near", 7310), ("build", 7300),
        ("problem", 7290), ("piece", 7280), ("told", 7270), ("knew", 7260), ("pass", 7250),
        ("hundred", 7240), ("hold", 7230), ("reach", 7220), ("carry", 7210), ("state", 7200),
        ("body", 7190), ("music", 7180), ("color", 7170), ("stand", 7160), ("family", 7150),
        ("food", 7140), ("month", 7130), ("money", 7120), ("face", 7110), ("country", 7100),
        ("school", 7090), ("father", 7080), ("mother", 7070), ("children", 7060), ("plant", 7050),
        ("cover", 7040), ("river", 7030), ("class", 7020), ("wind", 7010), ("stop", 7000),
        ("study", 6990), ("still", 6980), ("learn", 6970), ("should", 6960), ("watch", 6950),
        ("answer", 6940), ("found", 6930), ("follow", 6920), ("change", 6910), ("off", 6900),
        ("try", 6890), ("sentence", 6880), ("form", 6870), ("differ", 6860), ("feel", 6850),
        ("able", 6840), ("land", 6830), ("sure", 6820), ("kind", 6810), ("more", 6800),
        ("around", 6790), ("close", 6780), ("seem", 6770), ("open", 6760), ("begin", 6750),
        ("thought", 6740), ("high", 6730), ("below", 6720), ("always", 6710), ("map", 6700),
        ("music", 6690), ("those", 6680), ("both", 6670), ("mark", 6660), ("own", 6650),
        ("under", 6640), ("last", 6630), ("never", 6620), ("us", 6610), ("left", 6600),
        ("end", 6590), ("along", 6580), ("while", 6570), ("might", 6560), ("next", 6550),
        ("sound", 6540), ("below", 6530), ("saw", 6520), ("something", 6510), ("seem", 6500),
        ("really", 6490), ("without", 6480), ("such", 6470), ("through", 6460), ("between", 6450),
        ("things", 6440), ("upon", 6430), ("maybe", 6420), ("keep", 6410), ("together", 6400),
        ("many", 6390), ("people", 6380), ("own", 6370), ("does", 6360), ("done", 6350),
        ("way", 6340), ("come", 6330), ("make", 6320), ("give", 6310), ("well", 6300),
    ]
}
