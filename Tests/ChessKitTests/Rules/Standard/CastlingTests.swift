import ChessKit
import Testing

@Test(
    "Castling requires rights and the correct king and rook on their starting squares",
    arguments: [
        // Missing rook.
        ("4k3/8/8/8/8/8/8/4K3 w KQ - 0 1", "e1g1"),
        ("4k3/8/8/8/8/8/8/4K3 w KQ - 0 1", "e1c1"),
        ("4k3/8/8/8/8/8/8/4K3 b kq - 0 1", "e8g8"),
        ("4k3/8/8/8/8/8/8/4K3 b kq - 0 1", "e8c8"),
        // A different friendly piece occupies the rook square.
        ("4k3/8/8/8/8/8/8/4K2N w K - 0 1", "e1g1"),
        ("4k3/8/8/8/8/8/8/N3K3 w Q - 0 1", "e1c1"),
        ("4k2n/8/8/8/8/8/8/4K3 b k - 0 1", "e8g8"),
        ("n3k3/8/8/8/8/8/8/4K3 b q - 0 1", "e8c8"),
        // The rook belongs to the opponent.
        ("4k3/8/8/8/8/8/8/4K2r w K - 0 1", "e1g1"),
        ("4k3/8/8/8/8/8/8/r3K3 w Q - 0 1", "e1c1"),
        ("4k2R/8/8/8/8/8/8/4K3 b k - 0 1", "e8g8"),
        ("R3k3/8/8/8/8/8/8/4K3 b q - 0 1", "e8c8"),
        // The rook is on a different rank.
        ("4k3/8/8/8/8/8/7R/4K3 w K - 0 1", "e1g1"),
        ("4k3/8/8/8/8/8/R7/4K3 w Q - 0 1", "e1c1"),
        ("4k3/7r/8/8/8/8/8/4K3 b k - 0 1", "e8g8"),
        ("4k3/r7/8/8/8/8/8/4K3 b q - 0 1", "e8c8"),
        // The king is on a different file or rank.
        ("4k3/8/8/8/8/8/8/3K3R w K - 0 1", "d1g1"),
        ("4k3/8/8/8/8/8/8/R4K2 w Q - 0 1", "f1c1"),
        ("3k3r/8/8/8/8/8/8/4K3 b k - 0 1", "d8g8"),
        ("r4k2/8/8/8/8/8/8/4K3 b q - 0 1", "f8c8"),
        ("4k3/8/8/8/8/8/4K3/7R w K - 0 1", "e2g1"),
        ("4k3/8/8/8/8/8/4K3/R7 w Q - 0 1", "e2c1"),
        ("7r/4k3/8/8/8/8/8/4K3 b k - 0 1", "e7g8"),
        ("r7/4k3/8/8/8/8/8/4K3 b q - 0 1", "e7c8"),
        // Correct pieces do not restore missing rights.
        ("4k3/8/8/8/8/8/8/R3K2R w - - 0 1", "e1g1"),
        ("4k3/8/8/8/8/8/8/R3K2R w - - 0 1", "e1c1"),
        ("r3k2r/8/8/8/8/8/8/4K3 b - - 0 1", "e8g8"),
        ("r3k2r/8/8/8/8/8/8/4K3 b - - 0 1", "e8c8"),
    ]
)
func castlingRequiresStartingPiecesAndRights(fen: String, coordinateMove: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)

    #expect(try !game.legalMoves.contains(Move(string: coordinateMove)))
    #expect(game.position == position)
}

@Test(
    "Every square between the king and rook must be empty",
    arguments: [
        ("4k3/8/8/8/8/8/8/4KB1R w K - 0 1", "e1g1"),
        ("4k3/8/8/8/8/8/8/4K1NR w K - 0 1", "e1g1"),
        ("4k3/8/8/8/8/8/8/RN2K3 w Q - 0 1", "e1c1"),
        ("4k3/8/8/8/8/8/8/R1B1K3 w Q - 0 1", "e1c1"),
        ("4k3/8/8/8/8/8/8/R2QK3 w Q - 0 1", "e1c1"),
        ("4kb1r/8/8/8/8/8/8/4K3 b k - 0 1", "e8g8"),
        ("4k1nr/8/8/8/8/8/8/4K3 b k - 0 1", "e8g8"),
        ("rn2k3/8/8/8/8/8/8/4K3 b q - 0 1", "e8c8"),
        ("r1b1k3/8/8/8/8/8/8/4K3 b q - 0 1", "e8c8"),
        ("r2qk3/8/8/8/8/8/8/4K3 b q - 0 1", "e8c8"),
    ]
)
func castlingRequiresClearPath(fen: String, coordinateMove: String) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))

    #expect(try !game.legalMoves.contains(Move(string: coordinateMove)))
}

@Test(
    "Castling checks the king's starting square, transit square, and destination",
    arguments: [
        // Rooks attack the starting square, each transit square, and each destination.
        ("1k2r3/8/8/8/8/8/8/R3K2R w KQ - 0 1", ""),
        ("1k3r2/8/8/8/8/8/8/R3K2R w KQ - 0 1", "e1c1"),
        ("1k4r1/8/8/8/8/8/8/R3K2R w KQ - 0 1", "e1c1"),
        ("1k1r4/8/8/8/8/8/8/R3K2R w KQ - 0 1", "e1g1"),
        ("1kr5/8/8/8/8/8/8/R3K2R w KQ - 0 1", "e1g1"),
        ("r3k2r/8/8/8/8/8/8/1K2R3 b kq - 0 1", ""),
        ("r3k2r/8/8/8/8/8/8/1K3R2 b kq - 0 1", "e8c8"),
        ("r3k2r/8/8/8/8/8/8/1K4R1 b kq - 0 1", "e8c8"),
        ("r3k2r/8/8/8/8/8/8/1K1R4 b kq - 0 1", "e8g8"),
        ("r3k2r/8/8/8/8/8/8/1KR5 b kq - 0 1", "e8g8"),
        // Pawns attack diagonally rather than along their advance.
        ("1k6/8/8/8/8/8/4p3/R3K2R w KQ - 0 1", ""),
        ("1k6/8/8/8/8/8/5p2/R3K2R w KQ - 0 1", ""),
        ("1k6/8/8/8/8/8/1p6/R3K2R w KQ - 0 1", "e1g1"),
        ("1k6/8/8/8/8/8/2p5/R3K2R w KQ - 0 1", "e1g1"),
        ("r3k2r/4P3/8/8/8/8/8/1K6 b kq - 0 1", ""),
        ("r3k2r/5P2/8/8/8/8/8/1K6 b kq - 0 1", ""),
        ("r3k2r/1P6/8/8/8/8/8/1K6 b kq - 0 1", "e8g8"),
        ("r3k2r/2P5/8/8/8/8/8/1K6 b kq - 0 1", "e8g8"),
        // A bishop pinned to its own king still attacks the transit square.
        ("2k5/8/8/8/2b5/8/8/2R1K2R w K - 0 1", ""),
        ("2r1k2r/8/8/2B5/8/8/8/2K5 b k - 0 1", ""),
        // In an imported position, an adjacent king must also prevent castling.
        ("8/8/8/8/8/8/4k3/R3K2R w KQ - 0 1", ""),
        ("r3k2r/4K3/8/8/8/8/8/8 b kq - 0 1", ""),
    ]
)
func castlingRespectsAttackedSquares(fen: String, expectedMoves: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let kingSquare = Square(file: 4, rank: position.state.turn == .white ? 0 : 7)
    let castlings = game.legalMoves.filter {
        $0.from == kingSquare && abs($0.to.file - $0.from.file) == 2
    }
    let expected = expectedMoves.split(separator: " ").map(String.init)

    #expect(castlings.map(\.description).sorted() == expected.sorted())
    #expect(game.position == position)
}

@Test(
    "An attacked rook or b-file square does not prevent castling",
    arguments: [
        ("4k2r/8/8/8/8/8/8/4K2R w K - 0 1", "e1g1"),
        ("r3k3/8/8/8/8/8/8/R3K3 w Q - 0 1", "e1c1"),
        ("1r2k3/8/8/8/8/8/8/R3K3 w Q - 0 1", "e1c1"),
        ("4k2r/8/8/8/8/8/8/4K2R b k - 0 1", "e8g8"),
        ("r3k3/8/8/8/8/8/8/R3K3 b q - 0 1", "e8c8"),
        ("r3k3/8/8/8/8/8/8/1R2K3 b q - 0 1", "e8c8"),
    ]
)
func castlingAllowsAttackedRookAndOutsideSquare(fen: String, coordinateMove: String) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))

    #expect(try game.legalMoves.contains(Move(string: coordinateMove)))
}

@Test(
    "Legal castling moves both pieces and removes only the moving side's rights",
    arguments: [
        (
            "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1", "e1g1", "O-O",
            "r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1"
        ),
        (
            "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1", "e1c1", "O-O-O",
            "r3k2r/8/8/8/8/8/8/2KR3R b kq - 1 1"
        ),
        (
            "r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1", "e8g8", "O-O",
            "r4rk1/8/8/8/8/8/8/R3K2R w KQ - 1 2"
        ),
        (
            "r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1", "e8c8", "O-O-O",
            "2kr3r/8/8/8/8/8/8/R3K2R w KQ - 1 2"
        ),
    ]
)
func castlingUpdatesPositionAndNotation(
    fen: String, coordinateMove: String, expectedSan: String, expectedFen: String
) throws {
    let fenSerializer = FenSerialization()
    let sanSerializer = SanSerialization()
    let position = try fenSerializer.deserialize(fen: fen)
    let game = Game(position: position)
    let move = try Move(string: coordinateMove)

    try #require(game.legalMoves.contains(move))
    #expect(try sanSerializer.san(for: move, in: game) == expectedSan)
    #expect(try sanSerializer.move(for: expectedSan, in: game) == move)
    #expect(game.position == position)

    try game.make(move: move)

    #expect(fenSerializer.serialize(position: game.position) == expectedFen)
    #expect(game.movesHistory == [move])
}
