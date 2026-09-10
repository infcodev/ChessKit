import ChessKit
import Testing

@Test(
    "SAN includes the source file and capture marker for en passant",
    arguments: [
        // Capture toward either side, for both colors.
        ("7k/8/8/3pP3/8/8/8/7K w - d6 0 2", "e5d6", "exd6"),
        ("7k/8/8/8/3Pp3/8/8/7K b - d3 0 2", "e4d3", "exd3"),
        ("7k/8/8/2Pp4/8/8/8/7K w - d6 0 2", "c5d6", "cxd6"),
        ("7k/8/8/8/2pP4/8/8/7K b - d3 0 2", "c4d3", "cxd3"),
        // The capturing pawn gives check.
        ("8/2k5/8/3pP3/8/8/8/7K w - d6 0 2", "e5d6", "exd6+"),
        ("7k/8/8/8/3Pp3/8/2K5/8 b - d3 0 2", "e4d3", "exd3+"),
        // Removing both pawns opens a rook check.
        ("8/8/8/R2pP2k/8/8/8/7K w - d6 0 2", "e5d6", "exd6+"),
        ("7k/8/8/8/r2Pp2K/8/8/8 b - d3 0 2", "e4d3", "exd3+"),
    ]
)
func enPassantSanRoundTrip(fen: String, coordinateMove: String, expectedSan: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let serializer = SanSerialization()
    let move = Move(string: coordinateMove)

    try #require(game.legalMoves.contains(move))

    let san = serializer.san(for: move, in: game)
    let parsedMove = serializer.move(for: expectedSan, in: game)

    #expect(san == expectedSan)
    #expect(parsedMove == move)
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}

@Test(
    "Other pawn moves keep their SAN capture notation",
    arguments: [
        // An available en passant capture does not make a pawn advance a capture.
        ("7k/8/8/3pP3/8/8/8/7K w - d6 0 2", "e5e6", "e6"),
        ("7k/8/8/8/3Pp3/8/8/7K b - d3 0 2", "e4e3", "e3"),
        // Ordinary captures still include the capture marker.
        ("7k/8/3p4/4P3/8/8/8/7K w - - 0 2", "e5d6", "exd6"),
        ("7k/8/8/8/4p3/3P4/8/7K b - - 0 2", "e4d3", "exd3"),
    ]
)
func pawnSanCaptureControls(fen: String, coordinateMove: String, expectedSan: String) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))
    let move = Move(string: coordinateMove)

    try #require(game.legalMoves.contains(move))
    #expect(SanSerialization().san(for: move, in: game) == expectedSan)
}
