import ChessKit
import Testing

struct AdversarialEditedDiagramTests {
    @Test(arguments: [
        "8/8/8/8/8/8/8/8 w - - 0 1",
        "7k/8/8/8/8/8/K7/K7 w - - 0 1",
        "7k/7k/8/8/8/8/8/K7 w - - 0 1",
        "8/8/8/8/8/8/1k6/K7 w - - 0 1",
        "7k/8/8/8/8/8/8/K6P w - - 0 1",
        "p6k/8/8/8/8/8/8/K7 w - - 0 1",
        "7k/8/8/8/8/P7/PPPPPPPP/K7 w - - 0 1",
        "7k/8/8/8/8/NNNNNNNN/NNNNNNNN/K7 w - - 0 1",
        "7k/8/8/8/8/8/8/4K3 w KQ - 0 1",
        "7k/8/8/8/8/8/8/R2K3R w KQ - 0 1",
        "7k/8/8/8/8/8/8/K7 w - d6 0 1",
        "7k/8/8/3P4/8/8/8/K7 w - d6 0 1",
        "7k/3p4/8/3p4/8/8/8/K7 w - d6 0 1",
        "7k/8/8/8/8/8/7R/K7 w - - 0 1",
    ])
    func syntaxAcceptanceDoesNotEstablishPlayablePosition(fen: String) throws {
        let serializer = FenSerialization()
        let position = try serializer.deserialize(fen: fen)
        #expect(serializer.serialize(position: position) == fen)
        #expect(!position.validationIssues.isEmpty)
        #expect(throws: PositionValidationError.self) { try position.validate() }

        let game = Game(position: position)
        let before = PublicSnapshot(game)
        if case .invalidPosition(let issues) = game.status {
            #expect(!issues.isEmpty)
        } else {
            Issue.record("An invalid diagram must not be reported as an ordinary game: \(fen)")
        }
        #expect(PublicSnapshot(game) == before)
    }

    @Test(arguments: [Int.min, -1])
    func invalidEditedCountersRemainRecoverable(value: Int) throws {
        let serializer = FenSerialization()
        let start = try serializer.deserialize(fen: "7k/8/8/8/8/8/P7/K7 w - - 0 1")
        let game = Game(position: start)
        game.position.counter.halfMoves = value
        let before = PublicSnapshot(game)
        #expect(throws: GameMoveError.invalidPositionCounters) { try game.make(move: "a2a3") }
        #expect(PublicSnapshot(game) == before)
        game.position = start
        try game.make(move: "a2a3")
        #expect(game.position.counter.halfMoves == 0)
        #expect(game.movesHistory.count == 1)
    }

    @Test(arguments: [
        ("7k/8/8/8/8/8/8/Rr5K w - -", "a1b1"),
        ("r6k/1P6/8/8/8/8/8/7K w - -", "b7a8n"),
        ("7k/8/8/3pP3/8/8/8/4K3 w - d6", "e5d6"),
    ])
    func capturesAndPromotionsAtMaximumHalfmoveClockRemainAtomic(input: (String, String)) throws {
        let game = Game(position: try FenSerialization().deserialize(fen: "\(input.0) \(Int.max) 1"))
        let move = try Move(string: input.1)
        let before = PublicSnapshot(game)
        _ = try SanSerialization().san(for: move, in: game)
        #expect(PublicSnapshot(game) == before)
        try game.make(move: move)
        #expect(game.position.counter.halfMoves == 0)
        #expect(game.position.counter.fullMoves == 1)
        #expect(game.movesHistory.count == 1)
    }
}
