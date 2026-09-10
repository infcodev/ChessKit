import ChessKit
import Testing

@Test("An external consumer can serialize and deserialize FEN")
func publicFenSerialization() throws {
    let serializer = FenSerialization()
    let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

    let position = try serializer.deserialize(fen: fen)
    let serialized = serializer.serialize(position: position)

    #expect(serialized == fen)
    #expect(position.state.turn == .white)
}

@Test(
    "An external consumer can serialize and deserialize SAN",
    arguments: [("e4", "e2e4"), ("Nf3", "g1f3")]
)
func publicSanSerialization(san: String, coordinateMove: String) throws {
    let fenSerializer = FenSerialization()
    let sanSerializer = SanSerialization()
    let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    let position = try fenSerializer.deserialize(fen: fen)
    let game = Game(position: position)
    let expectedMove = Move(string: coordinateMove)

    let move = sanSerializer.move(for: san, in: game)
    let serialized = sanSerializer.san(for: expectedMove, in: game)

    #expect(move == expectedMove)
    #expect(serialized == san)
}
