# FEN input

We read a FEN record with `try FenSerialization().deserialize(fen:)`.
We return a `Position` only after all six fields pass the format checks.
We throw `FenSerializationError` when a check fails.
We do not return a partial position.

## Accepted format

We use the [FEN specification, section 16.1.3](https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm#c16.1.3) as our field reference.

| Field | Accepted input |
| --- | --- |
| Piece placement | Eight ranks of eight squares. ASCII piece letters and digits `1` through `8`. No consecutive digits. |
| Active color | Lowercase `w` or `b`. |
| Castling rights | `-`, or unique letters in `KQkq` order. |
| En passant target | `-`, or files `a` through `h` on rank `6` for White, or rank `3` for Black. |
| Halfmove clock | ASCII decimal digits with a value from zero through `Int.max`. |
| Fullmove number | ASCII decimal digits with a value from one through `Int.max`. |

We accept whitespace between fields and around the record, including tabs and line endings.
This import allowance also accepts Unicode whitespace.
We accept leading zeros in counters.
We write single spaces and counters without leading zeros when we serialize the position.
We reject signs, overflow, extra fields, and unsupported piece or castling symbols.

## Error contract

We check the field count first.
We then check fields from left to right and report the first error.
The error identifies the field without including the input text.

| Error | Field or condition |
| --- | --- |
| `invalidFieldCount(actual:)` | The record does not contain six fields. |
| `invalidPiecePlacement` | Rank count, rank width, or piece symbols. |
| `invalidActiveColor` | Side to move. |
| `invalidCastlingRights` | Castling symbols, duplicates, or order. |
| `invalidEnPassantTarget` | Target square or its rank for the active color. |
| `invalidHalfmoveClock` | Halfmove clock syntax or range. |
| `invalidFullmoveNumber` | Fullmove number syntax or range. |

We expose this error type as `Error`, `Equatable`, and `Sendable`.
An app can catch the error and select its own message.
The same serializer remains available after a failed read.

## Migration

We changed `deserialize(fen:)` to a throwing method.
This is an incompatible public API change for the next major release.
The serializer initializer and `serialize(position:)` signatures remain unchanged.

1. Add `try` at each FEN read.
2. Propagate the error from a throwing function, or handle it with `do/catch`.
3. Select an app message from the error case.
4. Keep the current study unchanged if the read fails.

This example propagates the error to the caller:

```swift
import ChessKit

func readPosition(from fen: String) throws -> Position {
    let serializer = FenSerialization()
    return try serializer.deserialize(fen: fen)
}
```

We avoid `try!` for imported text.
It converts a recoverable error into an app failure.

## Validation boundary

We check the format, not whether legal play can reach the position.
We accept empty boards, missing kings, and castling rights without the starting pieces.
We preserve an en passant target without requiring a capturing pawn.
We keep these controls separate so that position editing remains possible.

We accept counters through `Int.max` for storage and serialization.
The later [move-input correction](MOVES-AND-SAN.md) rejects overflowing game updates with a recoverable error.
SAN inspection does not increment those counters.
A valid FEN format alone does not guarantee safe game play from an arbitrary edited position.

## Verification

We reproduced eight invalid active-color cases that returned a position before the correction.
We test field errors, every board rank, whitespace, Unicode input, counter bounds, and valid special-move state.
We use a public consumer target without `@testable` for the new input tests.
We retain the existing rule tests and the perft baseline.

We require the full test command and the iOS Simulator build before delivery.
The build checks compilation; it does not run iOS tests.
