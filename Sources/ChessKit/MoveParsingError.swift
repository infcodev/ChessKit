/// A format error in a coordinate move such as `e2e4` or `e7e8q`.
public enum MoveParsingError: Error, Equatable, Sendable {
    /// Input must contain four coordinate bytes and at most one promotion byte.
    case invalidLength
    /// The source must use an ASCII file from a to h and rank from 1 to 8.
    case invalidSourceSquare
    /// The destination must use an ASCII file from a to h and rank from 1 to 8.
    case invalidDestinationSquare
    /// The source and destination cannot be the same square.
    case identicalSquares
    /// Only queen, rook, bishop, or knight promotion letters are accepted.
    case invalidPromotion
}
