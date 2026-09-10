/// An error while reading or writing a SAN move in a position.
public enum SanSerializationError: Error, Equatable, Sendable {
    /// Input does not match the supported SAN token grammar.
    case invalidNotation
    /// No legal move matches the input or the move supplied for serialization.
    case illegalMove
    /// More than one legal move matches the specified origin and destination.
    case ambiguousMove
    /// A supplied check or mate suffix does not match the resulting position.
    case invalidCheckSuffix
}
