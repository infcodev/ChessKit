import ChessKit
import Testing

@Test(
    "A knight cannot use the en passant square to escape a pawn check",
    arguments: [
        ("7k/8/8/3p1N2/4K3/8/8/8 w - d6 0 2", "f5d6"),
        ("8/8/8/4k3/3P1n2/8/8/7K b - d3 0 2", "f4d3"),
    ]
)
func nonPawnCannotCaptureEnPassant(fen: String, coordinateMove: String) throws {
    let serializer = FenSerialization()
    let position = try serializer.deserialize(fen: fen)
    let game = Game(position: position)
    let move = try Move(string: coordinateMove)

    #expect(game.isCheck)
    #expect(!game.legalMoves.contains(move))
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}

@Test(
    "A knight can move to the en passant square while a pawn blocks a rook",
    arguments: [
        (
            "7k/8/8/r2p1N1K/8/8/8/8 w - d6 0 2", "f5d6",
            "7k/8/3N4/r2p3K/8/8/8/8 b - - 1 2"
        ),
        (
            "8/8/8/8/R2P1n1k/8/8/7K b - d3 0 2", "f4d3",
            "8/8/8/8/R2P3k/3n4/8/7K w - - 1 3"
        ),
    ]
)
func nonPawnPreservesEnPassantPawn(
    fen: String, coordinateMove: String, expectedFen: String
) throws {
    let serializer = FenSerialization()
    let position = try serializer.deserialize(fen: fen)
    let game = Game(position: position)
    let move = try Move(string: coordinateMove)

    #expect(!game.isCheck)
    try #require(game.legalMoves.contains(move))
    #expect(game.position == position)

    try game.make(move: move)

    #expect(serializer.serialize(position: game.position) == expectedFen)
}

@Test(
    "En passant can capture the pawn that gives check",
    arguments: [
        (
            "7k/8/8/3pP3/4K3/8/8/8 w - d6 0 2", "e5d6",
            "7k/8/3P4/8/4K3/8/8/8 b - - 0 2"
        ),
        (
            "8/8/8/4k3/3Pp3/8/8/7K b - d3 0 2", "e4d3",
            "8/8/8/4k3/8/3p4/8/7K w - - 0 3"
        ),
    ]
)
func enPassantEscapesPawnCheck(
    fen: String, coordinateMove: String, expectedFen: String
) throws {
    let serializer = FenSerialization()
    let game = try Game(position: serializer.deserialize(fen: fen))
    let move = try Move(string: coordinateMove)

    #expect(game.isCheck)
    try #require(game.legalMoves.contains(move))

    try game.make(move: move)

    #expect(serializer.serialize(position: game.position) == expectedFen)
}

@Test(
    "En passant cannot expose the moving side's king to a rook",
    arguments: [
        // Removing both pawns opens the rank.
        ("7k/8/8/r2pP2K/8/8/8/8 w - d6 0 2", "e5d6"),
        ("8/8/8/8/R2Pp2k/8/8/7K b - d3 0 2", "e4d3"),
        // Moving the pinned pawn opens the file.
        ("k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 2", "e5d6"),
        ("4k3/8/8/8/3Pp3/8/8/K3R3 b - d3 0 2", "e4d3"),
    ]
)
func enPassantCannotExposeRookCheck(fen: String, coordinateMove: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let move = try Move(string: coordinateMove)

    #expect(!game.isCheck)
    #expect(!game.legalMoves.contains(move))
    #expect(game.position == position)
}
