import ChessKit
import Testing

@Test(
    "FEN rejects an invalid active color through the public error API",
    arguments: ["x", "W", "B", "white", "black", "ww", "0", "-"]
)
func publicFenRejectsInvalidActiveColor(color: String) {
    let serializer = FenSerialization()
    let fen = "8/8/8/8/8/8/8/8 \(color) - - 0 1"

    #expect(throws: FenSerializationError.invalidActiveColor) {
        try serializer.deserialize(fen: fen)
    }
}

@Test(
    "FEN rejects missing and extra fields",
    arguments: [
        ("", 0),
        (" \t\r\n", 0),
        ("8/8/8/8/8/8/8/8", 1),
        ("8/8/8/8/8/8/8/8 w", 2),
        ("8/8/8/8/8/8/8/8 w -", 3),
        ("8/8/8/8/8/8/8/8 w - -", 4),
        ("8/8/8/8/8/8/8/8 w - - 0", 5),
        ("8/8/8/8/8/8/8/8 w - - 0 1 extra", 7),
        ("8/8/8/8/8/8/8/8 w - - 0 1\n8/8/8/8/8/8/8/8 b - - 0 1", 12),
    ]
)
func fenRejectsInvalidFieldCount(fen: String, count: Int) {
    #expect(throws: FenSerializationError.invalidFieldCount(actual: count)) {
        try FenSerialization().deserialize(fen: fen)
    }
}

@Test(
    "FEN requires exactly eight ranks",
    arguments: [
        "8", "8/8/8/8/8/8/8", "8/8/8/8/8/8/8/8/8",
        "/8/8/8/8/8/8/8/8", "8/8/8/8/8/8/8/8/", "////////",
    ]
)
func fenRejectsInvalidRankCount(placement: String) {
    #expect(throws: FenSerializationError.invalidPiecePlacement) {
        try FenSerialization().deserialize(fen: "\(placement) w - - 0 1")
    }
}

@Test(
    "FEN rejects an invalid row at every rank",
    arguments: Array(0..<8), [
        "", "7", "9", "0", "44", "11111111", "7P1", "8P", "PPPPPPPPP",
        "4P4", "7X", "7.", "7*", "7♔", "7K", "７P", "7\u{0}", "7P\u{301}",
    ]
)
func fenRejectsInvalidRank(rankIndex: Int, rank: String) {
    var ranks = Array(repeating: "8", count: 8)
    ranks[rankIndex] = rank
    let fen = "\(ranks.joined(separator: "/")) w - - 0 1"

    #expect(throws: FenSerializationError.invalidPiecePlacement) {
        try FenSerialization().deserialize(fen: fen)
    }
}

@Test(
    "FEN rejects invalid, duplicate, and unordered castling letters",
    arguments: ["KK", "qq", "KQK", "QK", "qk", "kK", "Kqk", "-K", "K-", "--", "P", "N", "X", "HAha", "♔", "K"]
)
func fenRejectsInvalidCastlingRights(rights: String) {
    #expect(throws: FenSerializationError.invalidCastlingRights) {
        try FenSerialization().deserialize(fen: "8/8/8/8/8/8/8/8 w \(rights) - 0 1")
    }
}

@Test(
    "FEN rejects malformed en passant targets",
    arguments: ["w", "b"], ["a", "a33", "i3", "i6", "A3", "A6", "a0", "a9", "33", "a4", "a5", "--", "é6"]
)
func fenRejectsInvalidEnPassantTarget(turn: String, target: String) {
    #expect(throws: FenSerializationError.invalidEnPassantTarget) {
        try FenSerialization().deserialize(fen: "8/8/8/8/8/8/8/8 \(turn) - \(target) 0 1")
    }
}

@Test(
    "FEN rejects an en passant rank inconsistent with the turn",
    arguments: [("w", "a3"), ("w", "h3"), ("b", "a6"), ("b", "h6")]
)
func fenRejectsWrongEnPassantRank(turn: String, target: String) {
    #expect(throws: FenSerializationError.invalidEnPassantTarget) {
        try FenSerialization().deserialize(fen: "8/8/8/8/8/8/8/8 \(turn) - \(target) 0 1")
    }
}

@Test(
    "FEN rejects invalid halfmove clocks",
    arguments: ["-1", "+1", "-0", "1.0", "1e2", "zero", "١", "１", "0x10", "1_000", "1\u{0}", "\(Int.max)0"]
)
func fenRejectsInvalidHalfmoveClock(clock: String) {
    #expect(throws: FenSerializationError.invalidHalfmoveClock) {
        try FenSerialization().deserialize(fen: "8/8/8/8/8/8/8/8 w - - \(clock) 1")
    }
}

@Test(
    "FEN rejects invalid fullmove numbers",
    arguments: ["0", "000", "-1", "+1", "1.0", "1e2", "one", "١", "１", "0x10", "1_000", "1\u{0}", "\(Int.max)0"]
)
func fenRejectsInvalidFullmoveNumber(number: String) {
    #expect(throws: FenSerializationError.invalidFullmoveNumber) {
        try FenSerialization().deserialize(fen: "8/8/8/8/8/8/8/8 w - - 0 \(number)")
    }
}

@Test("FEN returns the first field error and remains usable after failure")
func fenReportsFirstErrorAndRecovers() throws {
    let serializer = FenSerialization()

    #expect(throws: FenSerializationError.invalidPiecePlacement) {
        try serializer.deserialize(fen: "7/8/8/8/8/8/8/8 x X z9 -1 0")
    }
    #expect(throws: FenSerializationError.invalidActiveColor) {
        try serializer.deserialize(fen: "8/8/8/8/8/8/8/8 x X z9 -1 0")
    }
    #expect(throws: FenSerializationError.invalidCastlingRights) {
        try serializer.deserialize(fen: "8/8/8/8/8/8/8/8 w X z9 -1 0")
    }
    #expect(throws: FenSerializationError.invalidEnPassantTarget) {
        try serializer.deserialize(fen: "8/8/8/8/8/8/8/8 w - z9 -1 0")
    }
    #expect(throws: FenSerializationError.invalidHalfmoveClock) {
        try serializer.deserialize(fen: "8/8/8/8/8/8/8/8 w - - -1 0")
    }

    let fen = "8/8/8/8/8/8/8/8 w - - 0 1"
    let position = try serializer.deserialize(fen: fen)

    #expect(serializer.serialize(position: position) == fen)
}

@Test(
    "FEN accepts each castling rights combination without requiring the starting pieces",
    arguments: ["-", "K", "Q", "k", "q", "KQ", "Kk", "Kq", "Qk", "Qq", "kq", "KQk", "KQq", "Kkq", "Qkq", "KQkq"]
)
func fenPreservesCastlingRights(rights: String) throws {
    let serializer = FenSerialization()
    let fen = "8/8/8/8/8/8/8/8 w \(rights) - 0 1"
    let position = try serializer.deserialize(fen: fen)
    let actualRights = position.state.castlings.map { $0.description }.joined()

    #expect(actualRights == (rights == "-" ? "" : rights))
    #expect(serializer.serialize(position: position) == fen)
}

@Test(
    "FEN accepts each en passant file without requiring a capturing pawn",
    arguments: ["a", "b", "c", "d", "e", "f", "g", "h"], ["w", "b"]
)
func fenPreservesEnPassantTarget(file: String, turn: String) throws {
    let target = file + (turn == "w" ? "6" : "3")
    let fen = "8/8/8/8/8/8/8/8 \(turn) - \(target) 0 1"
    let serializer = FenSerialization()
    let position = try serializer.deserialize(fen: fen)

    #expect(position.state.enPasant?.description == target)
    #expect(serializer.serialize(position: position) == fen)
}

@Test("FEN preserves a double pawn advance without an available en passant capture")
func fenPreservesUncapturableDoubleAdvance() throws {
    let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    let serializer = FenSerialization()
    let position = try serializer.deserialize(fen: fen)
    let game = Game(position: position)

    #expect(position.state.enPasant == Square(coordinate: "e3"))
    #expect(!game.legalMoves.contains { $0.to == Square(coordinate: "e3") })
    #expect(serializer.serialize(position: position) == fen)
}

@Test("FEN maps all piece symbols and the edge squares to board data")
func fenReadsPiecePlacement() throws {
    let serializer = FenSerialization()
    let fen = "rnbqkbnr/8/8/3p4/4P3/8/8/RNBQKBNR b - - 7 42"
    let position = try serializer.deserialize(fen: fen)
    let expectedPieces = [
        ("a8", "r"), ("b8", "n"), ("c8", "b"), ("d8", "q"),
        ("e8", "k"), ("f8", "b"), ("g8", "n"), ("h8", "r"),
        ("a1", "R"), ("b1", "N"), ("c1", "B"), ("d1", "Q"),
        ("e1", "K"), ("f1", "B"), ("g1", "N"), ("h1", "R"),
        ("d5", "p"), ("e4", "P"),
    ]

    for (coordinate, piece) in expectedPieces {
        #expect(position.board[Square(coordinate: coordinate)]?.description == piece)
    }

    #expect(position.board.enumeratedPieces().count == expectedPieces.count)
    #expect(position.state.turn == .black)
    #expect(position.counter.halfMoves == 7)
    #expect(position.counter.fullMoves == 42)
    #expect(serializer.serialize(position: position) == fen)
}

@Test(
    "FEN normalizes whitespace and leading counter zeros",
    arguments: [" ", "  ", "\t", "\n", "\r\n", "\u{00A0}"]
)
func fenNormalizesWhitespace(separator: String) throws {
    let fields = ["8/8/8/8/8/8/8/8", "w", "-", "-", "000", "001"]
    let fen = separator + fields.joined(separator: separator) + separator
    let serializer = FenSerialization()
    let position = try serializer.deserialize(fen: fen)

    #expect(position.counter.halfMoves == 0)
    #expect(position.counter.fullMoves == 1)
    #expect(serializer.serialize(position: position) == "8/8/8/8/8/8/8/8 w - - 0 1")
}

@Test(
    "FEN preserves counters up to the storage limit",
    arguments: [(0, 1), (100, 51), (1_000_000, 1_000_000), (Int.max, Int.max)]
)
func fenPreservesCounterRange(halfMoves: Int, fullMoves: Int) throws {
    let serializer = FenSerialization()
    let fen = "8/8/8/8/8/8/8/8 w - - \(halfMoves) \(fullMoves)"
    let position = try serializer.deserialize(fen: fen)

    #expect(position.counter.halfMoves == halfMoves)
    #expect(position.counter.fullMoves == fullMoves)
    #expect(serializer.serialize(position: position) == fen)
}
