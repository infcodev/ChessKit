/// A rejected game update. The game remains unchanged when this error is thrown.
public enum GameMoveError: Error, Equatable, Sendable {
    /// A counter which cannot represent another increment.
    public enum Counter: Equatable, Sendable {
        case halfMoves
        case fullMoves
        case repetitions
    }

    /// The move is not legal in the current position.
    case illegalMove
    /// A direct edit set a negative halfmove clock or a fullmove number below one.
    case invalidPositionCounters
    /// Applying the move would exceed the storage range of the indicated counter.
    case counterOverflow(Counter)
}
