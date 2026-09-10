import ChessKit
import Foundation
import Testing

@Suite(.serialized)
struct LongLineTests {
    @Test("Long analysis lines preserve exact state and independent copies", arguments: [2_000, 10_000])
    func longLine(plies: Int) throws {
        let fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let initial = try FenSerialization().deserialize(fen: fen)
        let game = Game(position: initial)
        let cycle = try ["g1f3", "g8f6", "f3g1", "f6g8"].map { try Move(string: $0) }
        let start = Date.timeIntervalSinceReferenceDate
        for index in 0..<plies {
            try game.make(move: cycle[index % 4])
        }
        let elapsed = Date.timeIntervalSinceReferenceDate - start
        #expect(game.position.board == initial.board)
        #expect(game.position.counter.halfMoves == plies)
        #expect(game.position.counter.fullMoves == plies / 2 + 1)
        #expect(game.movesHistory.count == plies)
        #expect(game.positionsCounter.count == 4)
        #expect(game.repetitionCount == plies / 4 + 1)

        let copyStart = Date.timeIntervalSinceReferenceDate
        let copies = (0..<100).map { _ in game.deepCopy() }
        let copyElapsed = Date.timeIntervalSinceReferenceDate - copyStart
        let copy = try #require(copies.first)
        try copy.make(move: "e2e4")
        #expect(game.movesHistory.count == plies)
        #expect(copy.movesHistory.count == plies + 1)
        #expect(game.position.board == initial.board)
        #expect(copy.position.board["e4"] == Piece(kind: .pawn, color: .white))
        print("LongLine plies=\(plies) play_seconds=\(elapsed) copies=100 copy_seconds=\(copyElapsed)")
    }
}
