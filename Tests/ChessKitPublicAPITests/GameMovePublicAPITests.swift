import ChessKit
import Testing

@Test("An illegal move leaves the game unchanged")
func gameRejectsIllegalMove() throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)
    let occurrences = game.positionsCounter

    #expect(throws: GameMoveError.illegalMove) {
        try game.make(move: "e2e5")
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
    #expect(game.positionsCounter == occurrences)
}

@Test("A fullmove overflow leaves the game unchanged")
func gameRejectsFullmoveOverflow() throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 \(Int.max)"
    )
    let game = Game(position: position)
    let occurrences = game.positionsCounter

    #expect(throws: GameMoveError.counterOverflow(.fullMoves)) {
        try game.make(move: "g8f6")
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
    #expect(game.positionsCounter == occurrences)
}

@Test(
    "Game rejects illegal geometry, wrong turns, blocked paths, and spurious promotions",
    arguments: ["e7e5", "f3f4", "c1h6", "g1e2", "e1g1", "e2e5", "g1f3q", "e2e4q"]
)
func gameRejectsIllegalCoordinates(text: String) throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)
    let history = game.movesHistory
    let occurrences = game.positionsCounter
    let move = try Move(string: text)

    #expect(throws: GameMoveError.illegalMove) {
        try game.make(move: move)
    }
    #expect(game.position == position)
    #expect(game.movesHistory == history)
    #expect(game.positionsCounter == occurrences)
}

@Test(
    "Game rejects unsafe structured moves before using their squares",
    arguments: Array(0..<6)
)
func gameRejectsInvalidStructuredMove(index: Int) throws {
    let moves = [
        Move(from: Square(index: -1), to: Square(coordinate: "e4")),
        Move(from: Square(coordinate: "e2"), to: Square(index: 64)),
        Move(from: Square(file: -1, rank: 8), to: Square(coordinate: "e4")),
        Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e2")),
        Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e4"), promotion: .king),
        Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e4"), promotion: .pawn),
    ]
    let move = moves[index]
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)

    #expect(throws: GameMoveError.illegalMove) {
        try game.make(move: move)
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}

@Test("A parse failure preserves an existing game history")
func gamePreservesHistoryOnParseError() throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)
    try game.make(move: "e2e4")
    let previous = game.position
    let history = game.movesHistory
    let occurrences = game.positionsCounter

    #expect(throws: MoveParsingError.invalidLength) {
        try game.make(move: "e7")
    }
    #expect(game.position == previous)
    #expect(game.movesHistory == history)
    #expect(game.positionsCounter == occurrences)
}

@Test(
    "Game rejects moves that leave the king attacked or omit a promotion",
    arguments: [
        ("4r2k/8/8/8/8/8/4R3/4K3 w - - 0 1", "e2d2"),
        ("4r2k/8/8/8/8/8/8/4K3 w - - 0 1", "e1e2"),
        ("7k/8/8/3pP3/8/8/8/4K3 w - - 0 1", "e5d6"),
        ("7k/P7/8/8/8/8/8/4K3 w - - 0 1", "a7a8"),
    ]
)
func gameRejectsPositionDependentMove(fen: String, move: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)

    #expect(throws: GameMoveError.illegalMove) {
        try game.make(move: move)
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}

@Test(
    "Counter overflow preserves every part of the game",
    arguments: [
        ("4k3/8/8/8/8/8/8/R3K2R w KQ - \(Int.max) 1", "e1g1", GameMoveError.Counter.halfMoves),
        ("r3k2r/8/8/8/8/8/8/4K3 b kq - \(Int.max) 1", "e8c8", .halfMoves),
        ("r3k2r/8/8/8/8/8/8/4K3 b kq - 3 \(Int.max)", "e8c8", .fullMoves),
        ("7k/4p3/8/8/8/8/8/4K3 b - - \(Int.max) \(Int.max)", "e7e5", .fullMoves),
        ("r3k3/P7/8/8/8/8/8/7K b - - 5 \(Int.max)", "a8a7", .fullMoves),
    ]
)
func gameCounterOverflowIsAtomic(fen: String, move: String, counter: GameMoveError.Counter) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let occurrences = game.positionsCounter

    #expect(throws: GameMoveError.counterOverflow(counter)) {
        try game.make(move: move)
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
    #expect(game.positionsCounter == occurrences)
}

@Test(
    "Pawn moves and captures reset an extreme halfmove clock without overflow",
    arguments: [
        ("7k/8/8/8/8/8/4P3/4K3 w - - \(Int.max) 1", "e2e4"),
        ("7k/4p3/8/8/8/8/8/4K3 b - - \(Int.max) 1", "e7e5"),
        ("7k/8/8/8/8/8/p7/R3K3 w - - \(Int.max) 1", "a1a2"),
        ("7k/8/8/3pP3/8/8/8/4K3 w - d6 \(Int.max) 1", "e5d6"),
        ("7k/P7/8/8/8/8/8/4K3 w - - \(Int.max) 1", "a7a8q"),
    ]
)
func gameResetsExtremeHalfmoveClock(fen: String, coordinate: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let move = try Move(string: coordinate)

    try game.make(move: move)

    #expect(game.position.counter.halfMoves == 0)
    #expect(game.position.counter.fullMoves == (position.state.turn == .white ? 1 : 2))
    #expect(game.movesHistory == [move])
    #expect(game.positionsCounter[PositionKey(position: game.position)] == 1)
}

@Test("The largest representable counters remain exact on a successful move")
func gamePreservesCounterBoundary() throws {
    let position = try FenSerialization().deserialize(
        fen: "7k/8/8/8/8/8/8/4K1N1 w - - \(Int.max - 1) \(Int.max)"
    )
    let game = Game(position: position)

    try game.make(move: "g1f3")

    #expect(game.position.counter.halfMoves == Int.max)
    #expect(game.position.counter.fullMoves == Int.max)
    #expect(game.movesHistory.count == 1)
}

@Test(
    "Game rejects invalid counters from direct position edits",
    arguments: [(-1, 1), (0, 0), (0, -1)]
)
func gameRejectsEditedInvalidCounters(halfMoves: Int, fullMoves: Int) throws {
    var position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/4K1N1 w - - 0 1")
    position.counter.halfMoves = halfMoves
    position.counter.fullMoves = fullMoves
    let game = Game(position: position)

    #expect(throws: GameMoveError.invalidPositionCounters) {
        try game.make(move: "g1f3")
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}
