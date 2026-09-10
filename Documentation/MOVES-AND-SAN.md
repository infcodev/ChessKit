# Moves and SAN

We separate coordinate syntax, SAN matching, and game updates.
We return errors that the host app can handle.
We use the [PGN specification, section 8.2.3](https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm) as our SAN reference.

## Coordinate input

We read coordinate moves with `try Move(string:)`.
We require four ASCII characters, such as `e2e4`, with an optional promotion letter.
We accept `q`, `r`, `b`, and `n` in either case and write lowercase promotion letters.
We reject identical source and destination squares.
We do not trim coordinate input.

We throw these `MoveParsingError` cases:

| Error | Condition |
| --- | --- |
| `invalidLength` | The input does not contain four or five bytes. |
| `invalidSourceSquare` | The source is outside ASCII files `a` through `h` or ranks `1` through `8`. |
| `invalidDestinationSquare` | The destination is outside those files or ranks. |
| `identicalSquares` | The move does not change squares. |
| `invalidPromotion` | The last character is not an accepted promotion letter. |

We check these conditions in the listed order.
A parsed coordinate move does not establish legality in a position.
The structured `Move(from:to:promotion:)` initializer remains nonthrowing.
We check structured moves when we apply them or serialize them to SAN.

## SAN input

We read one SAN token with `try SanSerialization().move(for:in:)`.
We require one legal move that matches the piece, origin, destination, capture marker, and promotion.
We reject ambiguous input instead of selecting the first candidate.
We check ambiguity before evaluating a supplied check suffix.

We accept surrounding whitespace and `0-0` or `0-0-0` as castling alternatives.
We accept an omitted check or mate suffix.
We also accept a correct but unnecessary source file, rank, or square.
A supplied `+` must indicate check without mate; a supplied `#` must indicate mate.
We do not infer a missing capture marker or promotion choice.

We require uppercase English piece letters and uppercase promotion letters after `=`.
Move numbers, annotations such as `!?`, comments, and full PGN records belong to the host app.
We do not parse those elements in this method.

We throw these `SanSerializationError` cases:

| Error | Condition |
| --- | --- |
| `invalidNotation` | The token does not match the supported grammar. |
| `illegalMove` | No legal move matches the token, or the move supplied for output is illegal. |
| `ambiguousMove` | More than one legal move matches. |
| `invalidCheckSuffix` | The supplied check or mate suffix is incorrect. |

## SAN output

We write canonical SAN with `try SanSerialization().san(for:in:)`.
We select the source file, rank, or full square when disambiguation is necessary.
Only legal alternatives affect that choice; a pinned piece does not create an ambiguity.
We retain capture markers, promotion choices, and check or mate suffixes.

We calculate SAN from a temporary position without incrementing counters or modifying history.
This permits SAN inspection when a stored counter is already at `Int.max`.
Reading or writing SAN does not apply the move to the game.

## Game updates

We apply moves with `try Game.make(move:)`.
Both the string overload and the structured overload check legality.
We use the legal moves of the source piece for that check.

We calculate the next position, counters, and occurrence count before we modify the game.
An error leaves the position, move history, and occurrence counts unchanged.
We throw `GameMoveError.illegalMove` if the move is not legal.
We throw `GameMoveError.invalidPositionCounters` if direct edits supplied invalid counters.

We throw `GameMoveError.counterOverflow` if an increment would exceed `Int.max`.
Its associated counter identifies `halfMoves`, `fullMoves`, or `repetitions`.
We do not wrap or clamp the counter.
Pawn moves and captures reset the halfmove clock to zero, including when its previous value was `Int.max`.
The fullmove number changes only after Black moves.

## Migration

We changed these public APIs to throwing operations:

- `Move.init(string:)`
- `Game.make(move:)`, for both overloads
- `SanSerialization.move(for:in:)`
- `SanSerialization.san(for:in:)`

We include these changes in the planned major release.

1. Add `try` at each affected call.
2. Handle the error with `do/catch`, or propagate it from a throwing function.
3. Update the app interface only after the game update succeeds.
4. Keep the current study visible when an operation fails.

This example reads and applies one SAN move:

```swift
import ChessKit

func applySAN(_ text: String, to game: Game) throws {
    let serializer = SanSerialization()
    let move = try serializer.move(for: text, in: game)
    try game.make(move: move)
}
```

## Evidence and remaining limits

We reproduced unsupported promotions, illegal game updates, SAN ambiguity, incorrect capture and check markers, and missing full-square disambiguation.
We also reproduced a fullmove overflow in a separate test process before the correction.
We added public consumer tests for these defects and their accepted boundaries.
We use internal access only to construct a repetition counter at its otherwise impractical storage limit.
We retain the perft baseline and test SAN round trips for all legal moves in selected positions.

We still depend on the legal move generator for rule correctness.
We do not establish whether a position is reachable from legal play.
These changes do not complete validation of arbitrary direct board or square edits.
The occurrence key still uses piece placement; correcting that identity remains separate work.
