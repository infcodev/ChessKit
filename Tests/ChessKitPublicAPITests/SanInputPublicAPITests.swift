import ChessKit
import Testing

@Test("SAN rejects ambiguity instead of selecting the first piece")
func sanRejectsAmbiguousMove() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/1N2KN2 w - - 0 1")
    let game = Game(position: position)

    #expect(throws: SanSerializationError.ambiguousMove) {
        try SanSerialization().move(for: "Nd2", in: game)
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}

@Test(
    "SAN rejects incorrect move details",
    arguments: [
        ("Nxf3", SanSerializationError.illegalMove),
        ("O-O", SanSerializationError.illegalMove),
        ("e4+", SanSerializationError.invalidCheckSuffix),
    ]
)
func sanRejectsIncorrectDetails(san: String, error: SanSerializationError) throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)

    #expect(throws: error) {
        try SanSerialization().move(for: san, in: game)
    }
}

@Test("SAN includes both source file and rank when required")
func sanWritesFullDisambiguation() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/1N6/8/1N2KN2 w - - 0 1")
    let game = Game(position: position)
    let move = Move(from: Square(coordinate: "b1"), to: Square(coordinate: "d2"))
    let san = try SanSerialization().san(for: move, in: game)

    #expect(san == "Nb1d2")
}

@Test(
    "SAN rejects malformed tokens with a recoverable error",
    arguments: [
        "", " ", "e", "x", "N", "+", "#", "O", "0", "--",
        "e9", "i4", "E4", "nf3", "Pe4", "e2e4", "e2-e4",
        "Nxxf3", "N@f3", "N1gf3", "Nggf3", "e4++", "e4+#", "+e4", "e#4",
        "e4!", "e4??", "e4 e5", "1.e4", "O-O-O-O", "o-o",
        "e8=K", "e8=P", "e8=q", "e8=", "Nf3=Q", "e8=QQ",
        "♞f3", "Kf3", "e4\u{0}", "e4\u{301}",
    ]
)
func sanRejectsMalformedToken(text: String) throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)

    #expect(throws: SanSerializationError.invalidNotation) {
        try SanSerialization().move(for: text, in: game)
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}

@Test(
    "SAN requires a legal destination, capture, promotion, and castling state",
    arguments: ["e5", "exd5", "Nf6", "Nxf3", "e4=Q", "O-O", "O-O-O"]
)
func sanRejectsIllegalToken(text: String) throws {
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)

    #expect(throws: SanSerializationError.illegalMove) {
        try SanSerialization().move(for: text, in: game)
    }
}

@Test(
    "SAN uses file, rank, or full square as required",
    arguments: [
        ("7k/8/8/8/8/1N6/8/1N2KN2 w - - 0 1", "b1d2", "Nb1d2"),
        ("7k/8/8/8/8/1N6/8/1N2KN2 w - - 0 1", "b3d2", "N3d2"),
        ("7k/8/8/8/8/1N6/8/1N2KN2 w - - 0 1", "f1d2", "Nfd2"),
        ("1n2kn2/8/1n6/8/8/8/8/7K b - - 0 1", "b8d7", "Nb8d7"),
        ("1n2kn2/8/1n6/8/8/8/8/7K b - - 0 1", "b6d7", "N6d7"),
        ("1n2kn2/8/1n6/8/8/8/8/7K b - - 0 1", "f8d7", "Nfd7"),
        ("7k/8/8/8/1b6/2N5/8/4K1N1 w - - 0 1", "g1e2", "Ne2"),
    ]
)
func sanDisambiguationRoundTrip(fen: String, coordinates: String, expectedSan: String) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))
    let move = try Move(string: coordinates)
    let serializer = SanSerialization()

    #expect(try serializer.san(for: move, in: game) == expectedSan)
    #expect(try serializer.move(for: expectedSan, in: game) == move)
}

@Test(
    "A check suffix cannot select one of several ambiguous moves",
    arguments: ["Nd5", "Nd5+", "Nd5#"]
)
func sanDoesNotDisambiguateWithCheck(text: String) throws {
    let game = try Game(position: FenSerialization().deserialize(
        fen: "4k3/8/8/8/8/2N1N3/8/K3R3 w - - 0 1"
    ))
    let serializer = SanSerialization()

    #expect(throws: SanSerializationError.ambiguousMove) {
        try serializer.move(for: text, in: game)
    }
    #expect(try serializer.move(for: "Ned5+", in: game).description == "e3d5")
    #expect(try serializer.move(for: "Ncd5", in: game).description == "c3d5")
}

@Test(
    "SAN retains each promotion choice for both colors and captures",
    arguments: ["Q", "R", "B", "N"], [
        ("8/P7/7k/8/8/8/8/7K w - - 0 1", "a7a8", "a8="),
        ("r7/1P6/7k/8/8/8/8/7K w - - 0 1", "b7a8", "bxa8="),
        ("7k/8/8/8/8/7K/p7/8 b - - 0 1", "a2a1", "a1="),
        ("7k/8/8/8/8/7K/1p6/R7 b - - 0 1", "b2a1", "bxa1="),
    ]
)
func sanPromotionRoundTrip(symbol: String, context: (String, String, String)) throws {
    let (fen, coordinates, prefix) = context
    let game = try Game(position: FenSerialization().deserialize(fen: fen))
    let move = try Move(string: coordinates + symbol)
    let serializer = SanSerialization()
    let expectedSan = prefix + symbol

    #expect(try serializer.move(for: expectedSan, in: game) == move)
    #expect(try serializer.san(for: move, in: game) == expectedSan)

    try game.make(move: move)
    #expect(game.position.board[move.to]?.kind == move.promotion)
    #expect(game.position.counter.halfMoves == 0)
}

@Test(
    "SAN cannot omit a promotion or disguise castling as a king move",
    arguments: [
        ("8/P7/7k/8/8/8/8/7K w - - 0 1", "a8"),
        ("r7/1P6/7k/8/8/8/8/7K w - - 0 1", "bxa8"),
        ("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1", "Kg1"),
        ("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1", "Kc1"),
    ]
)
func sanRequiresSpecialMoveNotation(fen: String, text: String) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))

    #expect(throws: SanSerializationError.illegalMove) {
        try SanSerialization().move(for: text, in: game)
    }
}

@Test(
    "SAN verifies a supplied check or mate suffix",
    arguments: [
        ("7k/8/5KQ1/8/8/8/8/8 w - - 0 1", "g6g7", "Qg7#", "Qg7+"),
        ("7k/8/5KQ1/8/8/8/8/8 w - - 0 1", "g6g8", "Qg8+", "Qg8#"),
    ]
)
func sanValidatesCheckSuffix(fen: String, coordinates: String, expected: String, incorrect: String) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))
    let move = try Move(string: coordinates)
    let serializer = SanSerialization()

    #expect(try serializer.san(for: move, in: game) == expected)
    #expect(try serializer.move(for: expected, in: game) == move)
    #expect(try serializer.move(for: String(expected.dropLast()), in: game) == move)
    #expect(throws: SanSerializationError.invalidCheckSuffix) {
        try serializer.move(for: incorrect, in: game)
    }
}

@Test(
    "SAN accepts surrounding whitespace and castling with zeros",
    arguments: [
        ("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1", " \t0-0\n", "e1g1", "O-O"),
        ("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1", "0-0-0", "e1c1", "O-O-O"),
        ("r3k2r/8/8/8/8/8/8/4K3 b kq - 0 1", "0-0", "e8g8", "O-O"),
        ("r3k2r/8/8/8/8/8/8/4K3 b kq - 0 1", "0-0-0", "e8c8", "O-O-O"),
    ]
)
func sanNormalizesImportSpelling(fen: String, text: String, coordinates: String, canonical: String) throws {
    let game = try Game(position: FenSerialization().deserialize(fen: fen))
    let serializer = SanSerialization()
    let move = try Move(string: coordinates)

    #expect(try serializer.move(for: text, in: game) == move)
    #expect(try serializer.san(for: move, in: game) == canonical)
}

@Test(
    "SAN reading and writing do not increment extreme counters",
    arguments: [
        ("7k/8/5KQ1/8/8/8/8/8 w - - \(Int.max) \(Int.max)", "g6g7", "Qg7#"),
        ("8/8/8/8/8/5kq1/8/7K b - - \(Int.max) \(Int.max)", "g3g2", "Qg2#"),
        ("3k4/8/8/8/8/8/8/R3K3 w Q - \(Int.max) \(Int.max)", "e1c1", "O-O-O+"),
    ]
)
func sanPreservesExtremeCounters(fen: String, coordinates: String, expectedSan: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let move = try Move(string: coordinates)
    let serializer = SanSerialization()
    let occurrences = game.positionsCounter

    #expect(try serializer.san(for: move, in: game) == expectedSan)
    #expect(try serializer.move(for: expectedSan, in: game) == move)
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
    #expect(game.positionsCounter == occurrences)
}

@Test(
    "SAN serialization rejects illegal and unsafe structured moves",
    arguments: Array(0..<4)
)
func sanRejectsIllegalSerialization(index: Int) throws {
    let moves = [
        Move(from: Square(index: -1), to: Square(coordinate: "e4")),
        Move(from: Square(coordinate: "e2"), to: Square(index: 64)),
        Move(from: Square(coordinate: "e2"), to: Square(coordinate: "e5")),
        Move(from: Square(coordinate: "f3"), to: Square(coordinate: "f4")),
    ]
    let position = try FenSerialization().deserialize(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    )
    let game = Game(position: position)

    #expect(throws: SanSerializationError.illegalMove) {
        try SanSerialization().san(for: moves[index], in: game)
    }
    #expect(game.position == position)
}

@Test(
    "Every legal move in reference positions has unique round-trip SAN",
    arguments: [
        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
        "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQkq - 1 8",
        "7k/8/8/3pP3/8/8/8/4K3 w - d6 0 1",
        "7k/8/8/8/8/1N6/8/1N2KN2 w - - 0 1",
    ]
)
func sanRoundTripsLegalMoves(fen: String) throws {
    // Published positions use the attribution recorded in Documentation/PERFT.md.
    let position = try FenSerialization().deserialize(fen: fen)
    let game = Game(position: position)
    let serializer = SanSerialization()
    let moves = game.legalMoves
    var notations = Set<String>()

    for move in moves {
        let notation = try serializer.san(for: move, in: game)
        #expect(notations.insert(notation).inserted, "Duplicate SAN: \(notation)")
        #expect(try serializer.move(for: notation, in: game) == move)
    }

    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
}
