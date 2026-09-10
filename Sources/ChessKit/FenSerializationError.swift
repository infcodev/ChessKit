/// A format error found while reading a FEN position.
///
/// These errors describe input fields, not the legality of a chess position.
public enum FenSerializationError: Error, Equatable, Sendable {
    /// A FEN record must contain exactly six fields.
    case invalidFieldCount(actual: Int)

    /// Piece placement must contain eight ranks of eight squares with valid symbols.
    case invalidPiecePlacement

    /// The active color must be lowercase `w` or `b`.
    case invalidActiveColor

    /// Castling rights must be `-` or unique letters in `KQkq` order.
    case invalidCastlingRights

    /// The target must be `-` or a square on rank 6 for White, or rank 3 for Black.
    case invalidEnPassantTarget

    /// The halfmove clock must be an unsigned decimal integer that fits in `Int`.
    case invalidHalfmoveClock

    /// The fullmove number must be a positive decimal integer that fits in `Int`.
    case invalidFullmoveNumber
}
