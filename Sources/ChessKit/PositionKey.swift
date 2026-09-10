/// Position identity for standard-chess repetitions. Move counters are excluded.
public struct PositionKey: Hashable {
    public let board: Board
    public let turn: PieceColor
    public let castlingRights: Set<Piece>
    /// Present only when at least one en passant capture is legal.
    public let enPassant: Square?

    public init(position: Position) {
        self.init(position: position, rules: StandardRules())
    }

    init(position: Position, rules: Rules) {
        board = position.board
        turn = position.state.turn
        castlingRights = Set(position.state.castlings)
        enPassant = Self.legalEnPassant(in: position, rules: rules)
    }

    private static func legalEnPassant(in position: Position, rules: Rules) -> Square? {
        guard let target = position.validEnPassantTarget else {
            return nil
        }
        let rankOffset = position.state.turn == .white ? -1 : 1
        let pawn = Piece(kind: .pawn, color: position.state.turn)
        for fileOffset in [-1, 1] {
            let source = target.translate(file: fileOffset, rank: rankOffset)
            guard position.board[source] == pawn else {
                continue
            }
            let capture = Move(from: source, to: target)
            if rules.movesForPiece(at: source, in: position).contains(capture) {
                return target
            }
        }
        return nil
    }
}
