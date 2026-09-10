import ChessKit
import Testing

// Position data and reference counts: https://chessprogramming.org/Perft_Results
// Attribution and validation scope: Documentation/PERFT.md.
@Test(
    "Legal move sequences match published perft counts",
    arguments: [
        (
            "Initial position",
            "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
            [1, 20, 400, 8_902, 197_281, 4_865_609]
        ),
        (
            "Kiwipete",
            "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
            [1, 48, 2_039, 97_862, 4_085_603]
        ),
        (
            "Rook and pawn ending",
            "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
            [1, 14, 191, 2_812, 43_238, 674_624]
        ),
        (
            "Promotions and castling, White to move",
            "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1",
            [1, 6, 264, 9_467]
        ),
        (
            "Promotions and castling, mirrored",
            "r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1",
            [1, 6, 264, 9_467]
        ),
        (
            "Tactical promotions",
            "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8",
            [1, 44, 1_486, 62_379]
        ),
        (
            "Middlegame",
            "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10",
            [1, 46, 2_079, 89_890]
        ),
    ]
)
func standardPerft(name: String, fen: String, expectedCounts: [Int]) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let initialOccurrences = game.positionsCounter

    for (depth, expected) in expectedCounts.enumerated() {
        let actual = try perftNodes(in: game, depth: depth)
        let context = "\(name), depth \(depth), FEN: \(fen)"

        if actual != expected {
            let branches = try perftDivide(in: game, depth: depth)
            Issue.record("\(context): expected \(expected), got \(actual). Root branches: \(branches)")
        }

        #expect(game.position == position, "\(context): the input position must remain unchanged")
        #expect(game.movesHistory.isEmpty)
        #expect(game.positionsCounter == initialOccurrences)
    }
}

@Test(
    "Perft counts terminal positions only at depth zero",
    arguments: [
        ("Checkmate", "7k/6Q1/5K2/8/8/8/8/8 b - - 0 1", true),
        ("Stalemate", "7k/5K2/6Q1/8/8/8/8/8 b - - 0 1", false),
    ]
)
func terminalPerft(name: String, fen: String, expectedCheck: Bool) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))

    #expect(game.isCheck == expectedCheck, "\(name)")
    #expect(game.legalMoves.isEmpty, "\(name)")
    #expect(try perftNodes(in: game, depth: 0) == 1)
    #expect(try perftNodes(in: game, depth: 1) == 0)
    #expect(try perftNodes(in: game, depth: 2) == 0)
}

private func perftNodes(in game: Game, depth: Int) throws -> Int {
    if depth == 0 {
        return 1
    }

    let moves = game.legalMoves
    if depth == 1 {
        return moves.count
    }

    var count = 0
    for move in moves {
        let child = game.deepCopy()
        try child.make(move: move)
        count += try perftNodes(in: child, depth: depth - 1)
    }

    return count
}

private func perftDivide(in game: Game, depth: Int) throws -> String {
    guard depth > 0 else {
        return "depth zero"
    }

    return try game.legalMoves.sorted { $0.description < $1.description }.map { move in
        let child = game.deepCopy()
        try child.make(move: move)
        let count = try perftNodes(in: child, depth: depth - 1)
        return "\(move): \(count)"
    }.joined(separator: ", ")
}
