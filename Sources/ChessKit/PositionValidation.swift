/// A failed static check. Passing these checks does not prove historical reachability.
public enum PositionValidationIssue: Equatable, Sendable {
    case whiteKingCount
    case blackKingCount
    case adjacentKings
    case tooManyWhitePieces
    case tooManyBlackPieces
    case tooManyWhitePawns
    case tooManyBlackPawns
    case pawnOnBackRank
    case invalidCastlingRights
    case invalidEnPassant
    case invalidCounters
    case opponentInCheck
}

public struct PositionValidationError: Error, Equatable, Sendable {
    public let issues: [PositionValidationIssue]

    public init(issues: [PositionValidationIssue]) {
        self.issues = issues
    }
}

extension Position {
    /// Reports static defects in a position intended for standard play.
    /// An incomplete editing diagram can still be stored and serialized.
    public var validationIssues: [PositionValidationIssue] {
        let bitboards = board.bitboards
        let whiteKings = bitboards.king & bitboards.white
        let blackKings = bitboards.king & bitboards.black
        var issues: [PositionValidationIssue] = []

        if whiteKings.nonzeroBitCount != 1 {
            issues.append(.whiteKingCount)
        }
        if blackKings.nonzeroBitCount != 1 {
            issues.append(.blackKingCount)
        }

        if whiteKings.nonzeroBitCount == 1, blackKings.nonzeroBitCount == 1 {
            let white = Square(bitboardMask: whiteKings)
            let black = Square(bitboardMask: blackKings)
            if abs(white.file - black.file) <= 1, abs(white.rank - black.rank) <= 1 {
                issues.append(.adjacentKings)
            }
        }

        if bitboards.white.nonzeroBitCount > 16 {
            issues.append(.tooManyWhitePieces)
        }
        if bitboards.black.nonzeroBitCount > 16 {
            issues.append(.tooManyBlackPieces)
        }
        if (bitboards.white & bitboards.pawn).nonzeroBitCount > 8 {
            issues.append(.tooManyWhitePawns)
        }
        if (bitboards.black & bitboards.pawn).nonzeroBitCount > 8 {
            issues.append(.tooManyBlackPawns)
        }
        if bitboards.pawn & 0x8181818181818181 != 0 {
            issues.append(.pawnOnBackRank)
        }

        if !hasConsistentCastlingRights {
            issues.append(.invalidCastlingRights)
        }
        if state.enPasant != nil, validEnPassantTarget == nil {
            issues.append(.invalidEnPassant)
        }
        if counter.halfMoves < 0 || counter.fullMoves < 1 {
            issues.append(.invalidCounters)
        }

        if whiteKings.nonzeroBitCount == 1, blackKings.nonzeroBitCount == 1 {
            var opponentPosition = self
            opponentPosition.state.turn = state.turn.negotiated
            if StandardRules().isCheck(in: opponentPosition) {
                issues.append(.opponentInCheck)
            }
        }
        return issues
    }

    public func validate() throws {
        let issues = validationIssues
        guard issues.isEmpty else {
            throw PositionValidationError(issues: issues)
        }
    }

    private var hasConsistentCastlingRights: Bool {
        guard Set(state.castlings).count == state.castlings.count else {
            return false
        }
        return state.castlings.allSatisfy { right in
            guard right.kind == .king || right.kind == .queen else {
                return false
            }
            let rank = right.color == .white ? 0 : 7
            let king = Square(file: 4, rank: rank)
            let rook = Square(file: right.kind == .king ? 7 : 0, rank: rank)
            return board[king] == Piece(kind: .king, color: right.color)
                && board[rook] == Piece(kind: .rook, color: right.color)
        }
    }

    /// Checks the previous double pawn move's geometry, without requiring a capturer.
    var validEnPassantTarget: Square? {
        guard let target = state.enPasant, target.isValid else {
            return nil
        }
        let direction = state.turn == .white ? 1 : -1
        let expectedRank = state.turn == .white ? 5 : 2
        guard target.rank == expectedRank, board[target] == nil else {
            return nil
        }
        let pawnSquare = target.translate(file: 0, rank: -direction)
        let originSquare = target.translate(file: 0, rank: direction)
        let pawn = Piece(kind: .pawn, color: state.turn.negotiated)
        guard board[pawnSquare] == pawn, board[originSquare] == nil else {
            return nil
        }
        return target
    }
}
