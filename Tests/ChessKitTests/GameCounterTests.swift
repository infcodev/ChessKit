import Testing
@testable import ChessKit

@Test("A repetition count overflow does not partially apply the move")
func repetitionCountOverflowIsAtomic() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/4K1N1 w - - 0 1")
    var nextBoard = position.board
    nextBoard["f3"] = nextBoard["g1"]
    nextBoard["g1"] = nil
    var next = position
    next.board = nextBoard
    next.state.turn = .black
    let occurrences = [PositionKey(position: position): 1, PositionKey(position: next): Int.max]
    let game = Game(position: position, moves: [], positionsCounter: occurrences)

    #expect(throws: GameMoveError.counterOverflow(.repetitions)) {
        try game.make(move: "g1f3")
    }
    #expect(game.position == position)
    #expect(game.movesHistory.isEmpty)
    #expect(game.positionsCounter == occurrences)
}

@Test("A single-square mask rejects zero and multiple set bits")
func squareMaskBoundaries() {
    #expect(!Square(bitboardMask: 0).isValid)
    #expect(!Square(bitboardMask: UInt64.max).isValid)
    #expect(!Square(bitboardMask: 3).isValid)
    for index in 0..<64 {
        #expect(Square(bitboardMask: UInt64(1) << index) == Square(index: index))
    }
}
