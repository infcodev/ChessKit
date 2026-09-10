import ChessKit
import Testing

@Test("Invalid squares remain safe to construct, translate, describe, and index")
func squareInputBoundaries() {
    let invalid = [
        Square(index: Int.min), Square(index: Int.max), Square(index: 64),
        Square(file: Int.max, rank: Int.min), Square(file: -1, rank: 8),
        Square(coordinate: "e40"), Square(coordinate: " e4"), Square(coordinate: "é4"),
        Square(coordinate: "e4").translate(file: Int.max, rank: Int.min),
    ]
    var board = Board()
    board["a1"] = Piece(kind: .rook, color: .white)
    let original = board
    for square in invalid {
        #expect(!square.isValid)
        #expect(square.coordinate == "--")
        #expect(!square.translate(file: 1, rank: 1).isValid)
        #expect(board[square] == nil)
        board[square] = Piece(kind: .queen, color: .black)
    }
    for index in [Int.min, -1, 64, Int.max] {
        #expect(board[index] == nil)
        board[index] = nil
    }
    #expect(board == original)
}

@Test("All valid squares preserve coordinates and inverse translations")
func validSquareRoundTrips() {
    for file in 0..<8 {
        for rank in 0..<8 {
            let square = Square(file: file, rank: rank)
            #expect(square.isValid)
            #expect(Square(coordinate: square.coordinate) == square)
            #expect(Square(index: file * 8 + rank) == square)
            #expect(square.translate(file: 0, rank: 0) == square)
        }
    }
}

@Test("An edited position reports its specific structural defect", arguments: [
    ("8/8/8/8/8/8/8/4K3 w - - 0 1", PositionValidationIssue.blackKingCount),
    ("4k3/8/8/8/8/8/8/4KK2 w - - 0 1", .whiteKingCount),
    ("4k3/8/8/8/8/8/4k3/4K3 w - - 0 1", .blackKingCount),
    ("8/8/8/8/8/8/4k3/4K3 w - - 0 1", .adjacentKings),
    ("P3k3/8/8/8/8/8/8/4K3 w - - 0 1", .pawnOnBackRank),
    ("4k3/8/8/8/8/8/4R3/4K3 w - - 0 1", .opponentInCheck),
    ("4k3/8/8/8/8/8/8/4K3 w K - 0 1", .invalidCastlingRights),
    ("4k3/8/8/4P3/8/8/8/4K3 w - d6 0 1", .invalidEnPassant),
])
func invalidPositionDiagnostics(fen: String, issue: PositionValidationIssue) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    #expect(position.validationIssues.contains(issue))
    let game = Game(position: position)
    #expect(game.status == .invalidPosition(position.validationIssues))
    // Inspection must not trap, even with multiple kings.
    _ = game.legalMoves
    _ = game.isCheck
    _ = game.isMate
    #expect(throws: PositionValidationError(issues: position.validationIssues)) {
        try position.validate()
    }
}

@Test("Position editing permits incomplete diagrams while game updates reject them")
func editAndPlayBoundaries() throws {
    let position = Position(board: Board(), state: .init(turn: .white), counter: .init())
    #expect(position.validationIssues == [.whiteKingCount, .blackKingCount])
    var incomplete = position
    incomplete.board["e2"] = Piece(kind: .pawn, color: .white)
    #expect(StandardRules().movesForPiece(at: Square(coordinate: "e2"), in: incomplete).count == 2)
    let game = Game(position: incomplete)
    #expect(throws: GameMoveError.invalidPosition(incomplete.validationIssues)) {
        try game.make(move: "e2e4")
    }
    #expect(game.position == incomplete)
}

@Test("Edited en passant state cannot remove an unrelated piece", arguments: [
    "7k/8/8/3rP3/8/8/8/4K3 w - d6 0 1",
    "7k/8/8/3PP3/8/8/8/4K3 w - d6 0 1",
    "7k/3p4/8/3pP3/8/8/8/4K3 w - d6 0 1",
    "7k/8/3N4/3pP3/8/8/8/4K3 w - d6 0 1",
])
func invalidEnPassantState(fen: String) throws {
    let position = try FenSerialization().deserialize(fen: fen)
    #expect(position.validationIssues.contains(.invalidEnPassant))
    #expect(!Game(position: position).legalMoves.contains(try Move(string: "e5d6")))
}

@Test("Validation checks edited rights, counters, and en passant coordinates")
func editedStateDiagnostics() throws {
    let base = try FenSerialization().deserialize(fen: "4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")
    var position = base
    position.state.castlings.append(Piece(kind: .king, color: .white))
    #expect(position.validationIssues.contains(.invalidCastlingRights))
    position = base
    position.state.castlings = [Piece(kind: .pawn, color: .black)]
    #expect(position.validationIssues.contains(.invalidCastlingRights))
    position = base
    position.state.enPasant = Square(index: Int.max)
    #expect(position.validationIssues.contains(.invalidEnPassant))
    position.state.enPasant = Square(coordinate: "d3")
    #expect(position.validationIssues.contains(.invalidEnPassant))
    position.counter.fullMoves = 0
    #expect(position.validationIssues.contains(.invalidCounters))
}

@Test("Validation rejects excess pieces and pawns for each color", arguments: [PieceColor.white, .black])
func editedMaterialLimits(color: PieceColor) throws {
    var position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/8/K7 w - - 0 1")
    for file in 0..<8 {
        for rank in 1...3 {
            position.board[Square(file: file, rank: rank)] = Piece(kind: .pawn, color: color)
        }
    }
    let expectedPieces: PositionValidationIssue = color == .white ? .tooManyWhitePieces : .tooManyBlackPieces
    let expectedPawns: PositionValidationIssue = color == .white ? .tooManyWhitePawns : .tooManyBlackPawns
    #expect(position.validationIssues.contains(expectedPieces))
    #expect(position.validationIssues.contains(expectedPawns))
}

@Test("Safe query APIs handle deliberately incomplete and inconsistent diagrams")
func invalidPositionQueryBoundaries() throws {
    let position = try FenSerialization().deserialize(fen: "7k/8/8/8/8/8/4P3/8 w - - 0 1")
    #expect(position.deadPositionAssessment == .notEstablished)
    let game = Game(position: position)
    #expect(game.availableDrawClaims.isEmpty)
    #expect(throws: GameMoveError.invalidPosition(position.validationIssues)) {
        _ = try game.drawClaims(after: Move(string: "e2e4"))
    }
    #expect(game.movesHistory.isEmpty)
}
