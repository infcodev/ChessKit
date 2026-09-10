/// A result derived from the current position and the recorded line.
/// We do not model resignation, time controls, agreements, or an arbiter's acceptance of a claim.
public enum GameStatus: Equatable, Sendable {
    case invalidPosition([PositionValidationIssue])
    /// No terminal result was established by the supported checks.
    case ongoing
    case checkmate(winner: PieceColor)
    case draw(AutomaticDrawReason)
}

public enum AutomaticDrawReason: Equatable, Sendable {
    case stalemate
    case deadPosition
    case fivefoldRepetition
    case seventyFiveMoveRule
}

public enum DrawClaim: Hashable, Sendable {
    case threefoldRepetition
    case fiftyMoveRule
}

/// A conservative proof from material, not an exhaustive search of all legal continuations.
public enum DeadPositionAssessment: Equatable, Sendable {
    case dead
    /// No proof was found. This value does not mean that mate is possible.
    case notEstablished
}

extension Position {
    /// Covers bare kings, one minor piece in total, and bishops confined to one square color.
    /// Other positions, including blocked positions, require a separate analysis.
    public var deadPositionAssessment: DeadPositionAssessment {
        guard validationIssues.isEmpty else {
            return .notEstablished
        }
        let material = board.enumeratedPieces().filter { $0.1.kind != .king }
        if material.isEmpty {
            return .dead
        }
        if material.count == 1, let piece = material.first?.1,
            piece.kind == .bishop || piece.kind == .knight
        {
            return .dead
        }
        if material.allSatisfy({ $0.1.kind == .bishop }) {
            let colors = Set(material.map { ($0.0.file + $0.0.rank) % 2 })
            if colors.count == 1 {
                return .dead
            }
        }
        return .notEstablished
    }
}

extension Game {
    /// Inspects this position. Legal analysis moves remain available after a draw.
    /// The result does not latch when a study continues past a terminal position.
    public var status: GameStatus {
        let issues = position.validationIssues
        guard issues.isEmpty else {
            return .invalidPosition(issues)
        }
        if legalMoves.isEmpty {
            return isCheck ? .checkmate(winner: position.state.turn.negotiated) : .draw(.stalemate)
        }
        if position.deadPositionAssessment == .dead {
            return .draw(.deadPosition)
        }
        if position.counter.halfMoves >= 150 {
            return .draw(.seventyFiveMoveRule)
        }
        if repetitionCount >= 5 {
            return .draw(.fivefoldRepetition)
        }
        return .ongoing
    }

    /// Claims supported by the current position. No claim is applied automatically.
    public var availableDrawClaims: Set<DrawClaim> {
        guard status == .ongoing else {
            return []
        }
        var claims: Set<DrawClaim> = []
        if repetitionCount >= 3 {
            claims.insert(.threefoldRepetition)
        }
        if position.counter.halfMoves >= 100 {
            claims.insert(.fiftyMoveRule)
        }
        return claims
    }

    /// Tests a declared move without changing this game.
    /// - Throws: `GameMoveError` for an illegal move, invalid position, or counter overflow.
    public func drawClaims(after move: Move) throws -> Set<DrawClaim> {
        guard isLegal(move: move) else {
            throw GameMoveError.illegalMove
        }
        let issues = position.validationIssues
        guard issues.isEmpty else {
            throw GameMoveError.invalidPosition(issues)
        }
        guard status == .ongoing else {
            return []
        }
        let continuation = deepCopy()
        try continuation.make(move: move)
        return continuation.availableDrawClaims
    }
}
