import ChessKit
import Testing

struct AdversarialStateContractTests {
    @Test
    func branchCopiesAndRejectedMovesPreserveRepetitionEvidence() throws {
        let game = try makeGame("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        let cycle = ["g1f3", "g8f6", "f3g1", "f6g8"]
        for _ in 0..<2 {
            for move in cycle {
                try game.make(move: move)
            }
        }
        #expect(game.repetitionCount == 3)
        #expect(game.availableDrawClaims == [.threefoldRepetition])
        let original = PublicSnapshot(game)
        let left = game.deepCopy()
        let right = game.deepCopy()
        try left.make(move: "e2e4")
        try right.make(move: "d2d4")
        #expect(PublicSnapshot(game) == original)
        #expect(left.repetitionCount == 1)
        #expect(right.repetitionCount == 1)
        #expect(PublicSnapshot(left) != PublicSnapshot(right))

        let storedPosition = left.position
        left.position = storedPosition
        #expect(left.movesHistory.isEmpty)
        #expect(left.repetitionCount == 1)
        #expect(left.positionsCounter.count == 1)
        #expect(PublicSnapshot(game) == original)
        #expect(right.movesHistory.count == 9)
    }

    @Test(arguments: [false, true])
    func overflowFailsAtomicallyButResettingMovesRemainPlayable(black: Bool) throws {
        let turn = black ? "b" : "w"
        let game = try makeGame("7k/p7/8/8/8/8/P7/K7 \(turn) - - \(Int.max) 1")
        let before = PublicSnapshot(game)
        let quiet = try Move(string: black ? "h8h7" : "a1b1")
        let pawn = try Move(string: black ? "a7a6" : "a2a3")
        let san = SanSerialization()
        #expect(try san.san(for: quiet, in: game) == (black ? "Kh7" : "Kb1"))
        #expect(throws: GameMoveError.counterOverflow(.halfMoves)) { try game.make(move: quiet) }
        // A terminal position has no claim. The documented terminal priority applies
        // before an intended move; the mutating make operation still must reject overflow.
        #expect(try game.drawClaims(after: quiet).isEmpty)
        #expect(PublicSnapshot(game) == before)
        try game.make(move: pawn)
        #expect(game.position.counter.halfMoves == 0)
        #expect(game.position.counter.fullMoves == (black ? 2 : 1))
    }

    @Test
    func fullmoveOverflowAlsoRejectsCaptureAndPromotionWithoutPartialUpdates() throws {
        for (fen, uci) in [
            ("7k/8/8/8/8/8/1p6/R6K b - - 99 \(Int.max)", "b2a1q"),
            ("7k/8/8/8/8/8/p7/7K b - - 99 \(Int.max)", "a2a1n"),
            ("7k/8/8/8/8/8/p7/7K b - - 99 \(Int.max)", "h8g8"),
        ] {
            let game = try makeGame(fen)
            let before = PublicSnapshot(game)
            let move = try Move(string: uci)
            #expect(throws: GameMoveError.counterOverflow(.fullMoves)) { try game.make(move: move) }
            #expect(throws: GameMoveError.counterOverflow(.fullMoves)) { try game.drawClaims(after: move) }
            #expect(PublicSnapshot(game) == before)
        }
    }

    @Test
    func intendedThirdOccurrenceDoesNotBecomeCurrentUntilMoveIsPlayed() throws {
        let game = try makeGame("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        for move in ["g1f3", "g8f6", "f3g1", "f6g8", "g1f3", "g8f6", "f3g1"] {
            try game.make(move: move)
        }
        let before = PublicSnapshot(game)
        let move = try Move(string: "f6g8")
        #expect(game.availableDrawClaims.isEmpty)
        #expect(try game.drawClaims(after: move) == [.threefoldRepetition])
        #expect(PublicSnapshot(game) == before)
        try game.make(move: move)
        #expect(game.availableDrawClaims == [.threefoldRepetition])
    }
}

private func makeGame(_ fen: String) throws -> Game {
    Game(position: try FenSerialization().deserialize(fen: fen))
}
