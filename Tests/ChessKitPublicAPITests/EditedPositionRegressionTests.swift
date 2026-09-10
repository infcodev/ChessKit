import ChessKit
import Testing

@Test("Malformed square strings cannot read or change another square")
func editedCoordinateDoesNotAlias() {
    var board = Board()
    board["e4"] = Piece(kind: .pawn, color: .white)
    let original = board
    #expect(board["e-middle-4"] == nil)
    board["e-middle-4"] = nil
    #expect(board == original)
}

@Test("Out-of-range file and rank cannot alias a valid board index")
func editedSquareDoesNotAlias() {
    var board = Board()
    board["a1"] = Piece(kind: .rook, color: .white)
    let original = board
    let invalid = Square(file: -1, rank: 8)
    #expect(board[invalid] == nil)
    board[invalid] = nil
    #expect(board == original)
}

@Test("An en passant target without a captured pawn creates no capture")
func editedEnPassantNeedsPawn() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/4P3/8/8/8/4K3 w - d6 0 1")
    let game = Game(position: position)
    #expect(!game.legalMoves.contains(try Move(string: "e5d6")))
}

@Test("A king cannot be captured in an edited position")
func editedKingCannotBeCaptured() throws {
    let position = try FenSerialization().deserialize(fen: "4k3/8/8/8/8/8/4R3/4K3 w - - 0 1")
    let game = Game(position: position)
    #expect(!game.legalMoves.contains(try Move(string: "e2e8")))
}

@Test("Restoring piece placement after a rook move does not restore castling rights")
func repetitionsDistinguishLostRights() throws {
    let position = try FenSerialization().deserialize(fen: "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")
    let game = Game(position: position)
    for move in ["h1h2", "e8e7", "h2h1", "e7e8"] {
        try game.make(move: move)
    }
    #expect(game.position.board == position.board)
    #expect(game.positionsCounter.values.allSatisfy { $0 == 1 })
}

@Test("Direct position replacement starts a new history")
func editedGameResetsHistory() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/4K1N1 w - - 0 1")
    let game = Game(position: position)
    try game.make(move: "g1f3")
    game.position = position
    #expect(game.movesHistory.isEmpty)
    #expect(game.positionsCounter.count == 1)
}
