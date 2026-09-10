import ChessKit
import Testing

private let identityFEN = "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1"

@Test("Position identity includes turn and rights but excludes counters and rights order")
func positionIdentityFields() throws {
    let original = try FenSerialization().deserialize(fen: identityFEN)
    let key = PositionKey(position: original)
    var edited = original
    edited.counter.halfMoves = 90
    edited.counter.fullMoves = 80
    edited.state.castlings.reverse()
    #expect(PositionKey(position: edited) == key)
    edited.state.turn = .black
    #expect(PositionKey(position: edited) != key)
    edited = original
    edited.state.castlings.removeLast()
    #expect(PositionKey(position: edited) != key)
}

@Test("Only a legal en passant capture changes repetition identity", arguments: [
    ("7k/8/8/3pP3/8/8/8/4K3 w - d6 0 1", true),
    ("7k/8/8/3p4/8/8/8/4K3 w - d6 0 1", false),
    ("4r2k/8/8/3pP3/8/8/8/4K3 w - d6 0 1", false),
    ("7k/8/8/r4pPK/8/8/8/8 w - f6 0 1", false),
    ("4k3/8/8/8/3Pp3/8/8/7K b - d3 0 1", true),
    ("4k3/8/8/8/3Pp3/8/8/4R2K b - d3 0 1", false),
])
func positionIdentityEnPassant(fen: String, relevant: Bool) throws {
    let original = try FenSerialization().deserialize(fen: fen)
    var withoutTarget = original
    withoutTarget.state.enPasant = nil
    #expect((PositionKey(position: original) != PositionKey(position: withoutTarget)) == relevant)
}

@Test("Copies preserve repetitions and remain independent")
func repetitionCopyAndEdit() throws {
    let position = try FenSerialization().deserialize(fen: identityFEN)
    let game = Game(position: position)
    for move in ["a1a2", "a8a7", "a2a1", "a7a8"] {
        try game.make(move: move)
    }
    let copy = game.deepCopy()
    #expect(copy.positionsCounter == game.positionsCounter)
    try copy.make(move: "a1a2")
    #expect(game.movesHistory.count == 4)
    game.position.counter.halfMoves = 42
    #expect(game.movesHistory.isEmpty)
    #expect(game.repetitionCount == 1)
    #expect(copy.movesHistory.count == 5)
}

@Test("Valid edited castling rights serialize in canonical FEN order")
func editedCastlingFENRoundTrip() throws {
    let serializer = FenSerialization()
    let original = try serializer.deserialize(fen: identityFEN)
    var edited = original
    edited.state.castlings.reverse()
    try edited.validate()
    let fen = serializer.serialize(position: edited)
    #expect(fen == identityFEN)
    let restored = try serializer.deserialize(fen: fen)
    #expect(PositionKey(position: restored) == PositionKey(position: edited))
}
