# Migration from upstream 2.0.0

We changed public contracts in the correction candidate.
We plan a major release for these changes.
We have not published a version tag for them.
We use a reviewed candidate commit until release acceptance is complete.

## Update the package reference

1. Use the fork URL `https://github.com/infcodev/ChessKit.git`.
2. Select the reviewed candidate commit in Swift Package Manager.
3. Keep the product and module name `ChessKit`.
4. Retain the package resolution in the app repository.
5. Replace the commit requirement with the tested version after publication.

We identify the candidate branch and upstream baseline in [project status](PROJECT-STATUS.md).
We do not require changes to app UI architecture to use the fork.

## Handle throwing operations

| Operation | Required handling |
| --- | --- |
| `FenSerialization.deserialize(fen:)` | Add `try`; handle `FenSerializationError` |
| `Move.init(string:)` | Add `try`; handle `MoveParsingError` |
| Both `Game.make(move:)` overloads | Add `try`; handle `GameMoveError` and coordinate parsing errors where applicable |
| `SanSerialization.move(for:in:)` | Add `try`; handle `SanSerializationError` |
| `SanSerialization.san(for:in:)` | Add `try`; handle `SanSerializationError` |

We expose public initializers for both serializers.
We do not use `try!` for imported or user-supplied input.
We keep the current study visible if an operation fails.
We update app state only after the operation succeeds.
We define accepted input and errors in the [FEN](FEN-INPUT.md) and [SAN](MOVES-AND-SAN.md) guides.

This example validates a position, reads SAN, and applies the move:

```swift
import ChessKit

func openAndPlay(fen: String, san: String) throws -> Game {
    let position = try FenSerialization().deserialize(fen: fen)
    try position.validate()

    let game = Game(position: position)
    let move = try SanSerialization().move(for: san, in: game)
    try game.make(move: move)
    return game
}
```

## Replace board-only repetition keys

We changed `Game.positionsCounter` to use `PositionKey` instead of `Board`.
We expose the dictionary for reading, not direct mutation.

1. Use `game.repetitionCount` to read the current occurrence count.
2. Use `PositionKey(position:)` when a lookup requires the full position identity.
3. Replay legal moves from the starting position to establish historical occurrences.

We include the turn, castling rights, and legally usable en passant state in the key.
We exclude move counters.
An existing display history passed to `Game(position:moves:)` does not establish earlier occurrences.

## Separate editing from play

We apply ordinary moves through `Game.make`.
We treat assignment or nested edits to `game.position` as a new starting position.
Those edits reset move history and repetition evidence, including assignment of an equal position.

1. Keep direct board writes in position-setup flows.
2. Check `Square.isValid` for user-selected coordinates.
3. Validate the completed position before play.
4. Use `Game.deepCopy()` to create an independent analysis branch.

We return a safe invalid square for out-of-range coordinates.
Invalid board reads return `nil`; invalid writes have no effect.
We do not silently alias an invalid square to another square.

## Handle results and claims

We use `game.status` for supported automatic results.
We use `game.availableDrawClaims` for claims in the current position.
We inspect an intended move with `try game.drawClaims(after: move)` without applying it.
We return no claims when a terminal result takes precedence.
We reject counter overflow for an intended move in an ongoing position.

We do not equate `.notEstablished` with proof that checkmate is possible.
We keep a live game's adjudicated result in the host app if analysis continues.
The [game-state guide](GAME-STATE.md) defines these contracts and dead-position limits.

## Verify the app integration

1. Load a normal study and an imported position.
2. Navigate and apply legal moves, including all promotion choices.
3. Check SAN display and move-entry error messages.
4. Reject malformed input without replacing the current study.
5. Check independent analysis branches and direct position edits.
6. Check result display and distinguish claims from automatic draws.

We record package-level tests separately from this app acceptance check.
We do not claim that passing library tests completes StudyChess integration.
