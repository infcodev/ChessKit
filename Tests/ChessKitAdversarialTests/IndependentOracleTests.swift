import ChessKit
import Foundation
import Testing

private struct Corpus: Decodable {
    let reference: String
    let cases: [Scenario]
}

private struct Scenario: Decodable {
    let id: String
    let category: String
    let fen: String
    let moves: [String]
    let expected: Observation
}

private struct Observation: Decodable {
    let fen: String
    let check: Bool
    let status: String
    let repetition: Int
    let enPassant: String?
    let claims: [String]
    let candidates: [Candidate]
}

private struct Candidate: Decodable {
    let move: String
    let san: String
    let fen: String
    let claims: [String]
}

struct AdversarialIndependentOracleTests {
    @Test(arguments: [
        "en-passant", "promotion", "castling-rights", "castling-attacks",
        "disambiguation", "terminal", "check", "sparse", "history", "line",
    ])
    func matchesFrozenIndependentResults(category: String) throws {
        let url = try #require(Bundle.module.url(
            forResource: "independent", withExtension: "json", subdirectory: "Fixtures"
        ))
        let corpus = try JSONDecoder().decode(Corpus.self, from: Data(contentsOf: url))
        #expect(corpus.reference == "chess==1.11.2")
        let scenarios = corpus.cases.filter { $0.category == category }
        #expect(!scenarios.isEmpty, "Every declared category must contain cases")

        let fen = FenSerialization()
        let san = SanSerialization()

        for scenario in scenarios {
            let game = Game(position: try fen.deserialize(fen: scenario.fen))
            for move in scenario.moves {
                try game.make(move: move)
            }
            let expected = scenario.expected
            let context = Comment(rawValue: "\(scenario.id): \(scenario.fen); \(scenario.moves)")
            let before = PublicSnapshot(game)

            #expect(game.position.validationIssues.isEmpty, context)
            #expect(fen.serialize(position: game.position) == expected.fen, context)
            #expect(game.isCheck == expected.check, context)
            #expect(statusName(game.status) == expected.status, context)
            #expect(game.repetitionCount == expected.repetition, context)
            #expect(PositionKey(position: game.position).enPassant?.coordinate == expected.enPassant, context)
            #expect(claimNames(game.availableDrawClaims) == expected.claims, context)
            #expect(game.legalMoves.map(\.description).sorted() == expected.candidates.map(\.move), context)

            for candidate in expected.candidates {
                let move = try Move(string: candidate.move)
                let candidateContext = Comment(rawValue: "\(scenario.id), \(candidate.move)")
                #expect(try san.san(for: move, in: game) == candidate.san, candidateContext)
                #expect(try san.move(for: candidate.san, in: game) == move, candidateContext)
                try checkNotationMutations(candidate, move: move, game: game, serializer: san)
                #expect(claimNames(try game.drawClaims(after: move)) == candidate.claims, candidateContext)

                let branch = game.deepCopy()
                try branch.make(move: move)
                #expect(fen.serialize(position: branch.position) == candidate.fen, candidateContext)
                #expect(branch.movesHistory.count == before.history.count + 1, candidateContext)
                #expect(PublicSnapshot(game) == before, "Queries and branches must not change their source")
            }
        }
    }
}

struct AdversarialRejectedMoveTests {
    @Test(arguments: ["castling-attacks", "castling-rights", "en-passant", "promotion", "check", "sparse", "line", "history"])
    func everyCoordinatePairAndPromotionMustMatchTheIndependentLegalSet(category: String) throws {
        let url = try #require(Bundle.module.url(
            forResource: "independent", withExtension: "json", subdirectory: "Fixtures"
        ))
        let corpus = try JSONDecoder().decode(Corpus.self, from: Data(contentsOf: url))
        let scenario = try #require(corpus.cases.first { $0.category == category && !$0.expected.candidates.isEmpty })
        let game = Game(position: try FenSerialization().deserialize(fen: scenario.fen))
        for move in scenario.moves {
            try game.make(move: move)
        }
        let before = PublicSnapshot(game)
        let legal = Dictionary(uniqueKeysWithValues: scenario.expected.candidates.map { ($0.move, $0.fen) })
        let promotions: [(PieceKind?, String)] = [(nil, ""), (.queen, "q"), (.rook, "r"), (.bishop, "b"), (.knight, "n")]

        for source in 0..<64 {
            for target in 0..<64 {
                for (promotion, suffix) in promotions {
                    let from = Square(index: source)
                    let to = Square(index: target)
                    let uci = from.coordinate + to.coordinate + suffix
                    let move = Move(from: from, to: to, promotion: promotion)
                    let branch = game.deepCopy()
                    if let expectedFEN = legal[uci] {
                        try branch.make(move: move)
                        #expect(FenSerialization().serialize(position: branch.position) == expectedFEN)
                    } else {
                        #expect(throws: GameMoveError.illegalMove, Comment(rawValue: "\(scenario.id): \(uci)")) {
                            try branch.make(move: move)
                        }
                        #expect(PublicSnapshot(branch) == before)
                    }
                }
            }
        }
        #expect(PublicSnapshot(game) == before)
    }
}

private func checkNotationMutations(
    _ candidate: Candidate, move: Move, game: Game, serializer: SanSerialization
) throws {
    let notation = candidate.san
    let noSuffix = String(notation.prefix { $0 != "+" && $0 != "#" })
    #expect(try serializer.move(for: " \t" + noSuffix + "\n", in: game) == move)

    let wrongSuffixes = notation.hasSuffix("#") ? ["+"] : notation.hasSuffix("+") ? ["#"] : ["+", "#"]
    for suffix in wrongSuffixes {
        #expect(throws: SanSerializationError.invalidCheckSuffix) {
            try serializer.move(for: noSuffix + suffix, in: game)
        }
    }
    if notation.contains("x") {
        #expect(throws: SanSerializationError.self) {
            try serializer.move(for: notation.replacingOccurrences(of: "x", with: ""), in: game)
        }
    }
    if notation.contains("=") {
        let missingPromotion = String(noSuffix.prefix { $0 != "=" })
        #expect(throws: SanSerializationError.self) {
            try serializer.move(for: missingPromotion, in: game)
        }
    }
    if notation.hasPrefix("O-O") {
        #expect(try serializer.move(for: notation.replacingOccurrences(of: "O", with: "0"), in: game) == move)
    }
}

private func claimNames(_ claims: Set<DrawClaim>) -> [String] {
    claims.map { $0 == .fiftyMoveRule ? "fifty" : "threefold" }.sorted()
}

private func statusName(_ status: GameStatus) -> String {
    switch status {
    case .ongoing:
        return "ongoing"
    case .invalidPosition:
        return "invalid"
    case .checkmate(let winner):
        return winner == .white ? "white-mate" : "black-mate"
    case .draw(.stalemate):
        return "stalemate"
    case .draw(.deadPosition):
        return "dead"
    case .draw(.fivefoldRepetition):
        return "fivefold"
    case .draw(.seventyFiveMoveRule):
        return "seventyfive"
    }
}

// We capture only observable public state, including all recorded occurrences.
struct PublicSnapshot: Equatable {
    let fen: String
    let history: [String]
    let occurrences: [PositionKey: Int]

    init(_ game: Game) {
        fen = FenSerialization().serialize(position: game.position)
        history = game.movesHistory.map(\.description)
        occurrences = game.positionsCounter
    }
}
