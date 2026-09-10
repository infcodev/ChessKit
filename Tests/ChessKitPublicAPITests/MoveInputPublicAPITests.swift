import ChessKit
import Testing

@Test("Coordinate input rejects an unsupported promotion")
func coordinateRejectsUnsupportedPromotion() {
    #expect(throws: MoveParsingError.invalidPromotion) {
        try Move(string: "e2e4x")
    }
}

@Test(
    "Coordinate input requires four or five ASCII characters",
    arguments: ["", "e", "e2", "e2e", "e2e4qq", "e2-e4q", " e2e4 ", "♞e4x"]
)
func coordinateRejectsInvalidLength(text: String) {
    #expect(throws: MoveParsingError.invalidLength) {
        try Move(string: text)
    }
}

@Test(
    "Coordinate input validates both squares and promotion symbols",
    arguments: [
        ("a0e4", MoveParsingError.invalidSourceSquare),
        ("a9e4", .invalidSourceSquare), ("i2e4", .invalidSourceSquare),
        ("E2e4", .invalidSourceSquare), ("é2e4", .invalidSourceSquare), ("22e4", .invalidSourceSquare),
        ("e2a0", .invalidDestinationSquare), ("e2a9", .invalidDestinationSquare),
        ("e2i4", .invalidDestinationSquare), ("e2E4", .invalidDestinationSquare),
        ("e2e2", .identicalSquares), ("e7e8k", .invalidPromotion),
        ("e7e8p", .invalidPromotion), ("e7e8K", .invalidPromotion),
        ("e2e4 ", .invalidPromotion), ("e2e4\n", .invalidPromotion),
        ("e2e4\u{0}", .invalidPromotion),
    ]
)
func coordinateRejectsInvalidFields(text: String, error: MoveParsingError) {
    #expect(throws: error) {
        try Move(string: text)
    }
}

@Test(
    "Coordinate promotions accept both letter cases and normalize output",
    arguments: ["q", "r", "b", "n", "Q", "R", "B", "N"], ["a7a8", "h2h1"]
)
func coordinateReadsPromotion(symbol: String, coordinates: String) throws {
    let move = try Move(string: coordinates + symbol)

    #expect(move.description == coordinates + symbol.lowercased())
    #expect(move.promotion != nil)
}

@Test(
    "Coordinate parsing preserves each board file and rank",
    arguments: ["a", "b", "c", "d", "e", "f", "g", "h"], Array(1...8)
)
func coordinateReadsSquare(file: String, rank: Int) throws {
    let source = "\(file)\(rank)"
    let destination = source == "a1" ? "h8" : "a1"
    let move = try Move(string: source + destination)

    #expect(move.from.coordinate == source)
    #expect(move.to.coordinate == destination)
    #expect(move.promotion == nil)
}
