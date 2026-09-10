import ChessKit
import Testing

@Test("Results distinguish mate, stalemate, dead material, and automatic move-count draws", arguments: [
    ("7k/6Q1/5K2/8/8/8/8/8 b - - 150 80", GameStatus.checkmate(winner: .white)),
    ("8/8/8/8/8/5k2/6q1/7K w - - 150 80", .checkmate(winner: .black)),
    ("7k/5K2/6Q1/8/8/8/8/8 b - - 150 80", .draw(.stalemate)),
    ("7k/8/8/8/8/8/8/4K3 w - - 0 1", .draw(.deadPosition)),
    ("7k/8/8/8/8/8/8/2B1K3 w - - 0 1", .draw(.deadPosition)),
    ("7k/8/8/8/8/8/8/4K1N1 w - - 0 1", .draw(.deadPosition)),
    ("5b1k/8/8/8/8/4B3/8/2B1K3 w - - 0 1", .draw(.deadPosition)),
    ("7k/8/8/8/8/8/8/R3K3 w - - 150 80", .draw(.seventyFiveMoveRule)),
    ("7k/8/8/8/8/8/8/R3K3 w - - 99 80", .ongoing),
    ("7k/8/8/8/8/8/8/2NNK3 w - - 0 1", .ongoing),
    ("6bk/8/8/8/8/8/8/2B1K3 w - - 0 1", .ongoing),
])
func gameResults(fen: String, expected: GameStatus) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))
    #expect(game.status == expected)
}

@Test("Dead-position detection does not claim to solve arbitrary fortresses")
func deadPositionScope() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/R3K3 w - - 0 1")
    #expect(position.deadPositionAssessment == .notEstablished)
}

@Test("Fifty-move claims are separate from results and intended moves do not change state")
func fiftyMoveClaims() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/P7/R3K3 w - - 99 80")
    let game = Game(position: position)
    #expect(game.status == .ongoing)
    #expect(game.availableDrawClaims.isEmpty)
    #expect(try game.drawClaims(after: Move(string: "e1e2")) == [.fiftyMoveRule])
    #expect(try game.drawClaims(after: Move(string: "a2a3")).isEmpty)
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
    try game.make(move: "e1e2")
    #expect(game.status == .ongoing)
    #expect(game.availableDrawClaims == [.fiftyMoveRule])
}

@Test("Current and intended repetition claims differ from an automatic fivefold draw")
func repetitionDraws() throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)
    let cycle = ["g1f3", "g8f6", "f3g1", "f6g8"]
    for move in cycle + cycle.prefix(3) {
        try game.make(move: move)
    }
    #expect(game.availableDrawClaims.isEmpty)
    #expect(try game.drawClaims(after: Move(string: "f6g8")) == [.threefoldRepetition])
    #expect(game.movesHistory.count == 7)
    try game.make(move: "f6g8")
    #expect(game.repetitionCount == 3)
    #expect(game.status == .ongoing)
    #expect(game.availableDrawClaims == [.threefoldRepetition])
    for move in cycle + cycle {
        try game.make(move: move)
    }
    #expect(game.repetitionCount == 5)
    #expect(game.status == .draw(.fivefoldRepetition))
    #expect(game.availableDrawClaims.isEmpty)
    // A study can still inspect a legal continuation after an automatic draw.
    try game.make(move: "e2e4")
    #expect(game.position.board["e4"] == Piece(kind: .pawn, color: .white))
}

@Test("A mating move takes precedence over an intended fifty-move claim")
func matePrecedesDrawClaim() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/5KQ1/8/8/8/8/8 w - - 99 80")
    let game = Game(position: position)
    #expect(try game.drawClaims(after: Move(string: "g6g7")).isEmpty)
    #expect(throws: GameMoveError.illegalMove) {
        _ = try game.drawClaims(after: Move(string: "g6g5q"))
    }
    #expect(game.position == position)
}

@Test("A draw claim is unavailable after an automatic result")
func terminalClaimBoundaries() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/R3K3 w - - 150 80")
    let game = Game(position: position)
    #expect(try game.drawClaims(after: Move(string: "e1e2")).isEmpty)
    #expect(game.position == position)
}

@Test("A real mating move overrides the seventy-five-move threshold")
func playedMatePrecedence() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/5KQ1/8/8/8/8/8 w - - 149 80")
    let game = Game(position: position)
    try game.make(move: "g6g7")
    #expect(game.position.counter.halfMoves == 150)
    #expect(game.status == .checkmate(winner: .white))
}

@Test("Two knights can give mate and must not trigger a material draw")
func twoKnightsCanMate() throws {
    let position = try FenSerialization().deserialize(fen: "7k/4NN2/7K/8/8/8/8/8 b - - 0 1")
    #expect(position.deadPositionAssessment == .notEstablished)
    #expect(Game(position: position).status == .checkmate(winner: .white))
}

@Test("Independent draw claims can be available at the same time")
func simultaneousClaims() throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 92 80"
    )
    let game = Game(position: position)
    for move in ["g1f3", "g8f6", "f3g1", "f6g8", "g1f3", "g8f6", "f3g1", "f6g8"] {
        try game.make(move: move)
    }
    #expect(game.availableDrawClaims == [.fiftyMoveRule, .threefoldRepetition])
}

@Test("A supplied historical move list cannot invent repetition evidence")
func historyRequiresRecordedPositions() throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let history = try ["g1f3", "g8f6", "f3g1", "f6g8"].map { try Move(string: $0) }
    let game = Game(position: position, moves: history + history)
    #expect(game.movesHistory.count == 8)
    #expect(game.repetitionCount == 1)
    #expect(game.availableDrawClaims.isEmpty)
}
