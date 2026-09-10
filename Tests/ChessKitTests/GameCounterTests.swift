import Testing
@testable import ChessKit

@Test("A repetition count overflow does not partially apply the move")
func repetitionCountOverflowIsAtomic() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/4K1N1 w - - 0 1")
    var nextBoard = position.board
    nextBoard["f3"] = nextBoard["g1"]
    nextBoard["g1"] = nil
    let occurrences = [position.board: 1, nextBoard: Int.max]
    let game = Game(position: position, moves: [], positionsCounter: occurrences)

    #expect(throws: GameMoveError.counterOverflow(.repetitions)) {
        try game.make(move: "g1f3")
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
    #expect(game.positionsCounter == occurrences)
}
