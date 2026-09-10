# Positions, repetitions, and results

We keep position editing separate from standard play.
We use the [FIDE Laws of Chess](https://handbook.fide.com/chapter/E012023), articles 5 and 9, for the result rules.
We do not model tournament administration or time controls.

## Position editing

We expose initializers for `Position`, `Position.State`, and `Position.Counter`.
We accept incomplete diagrams in these data types and in the FEN parser.
We call `position.validate()` before we use an edited diagram for play.
We can read `position.validationIssues` to show all detected defects.

We check king counts, adjacent kings, piece and pawn counts, and pawns on the back ranks.
We also check castling pieces, en passant geometry, counter bounds, and an attacked opposing king.
We do not prove that a legal game can reach the position.
We do not infer missing move history or verify a fullmove number against it.
We do not infer the halfmove clock from an en passant target.

We keep `StandardRules.movesForPiece` available for incomplete editing diagrams.
We return safe geometric candidates where possible.
We do not treat those candidates as proof that the diagram is valid for play.
We reject king captures and refuse move generation with multiple kings of one color.
`Game.make` rejects an invalid starting position with `GameMoveError.invalidPosition`.
We retain `invalidPositionCounters` for counter errors and `illegalMove` for rejected moves.
We test the move and counters before we report other position defects.

## Square boundaries

We accept indices from 0 through 63, file and rank indices from 0 through 7, and coordinates from `a1` through `h8`.
We return a safe invalid `Square` for other values.
We expose `Square.isValid` for the caller.
We return `--` from an invalid square's coordinate and description.
We return an invalid square when translation leaves the board.
We check integer bounds before we calculate an index or apply an offset.

We return `nil` for an invalid board subscript read.
We ignore an invalid board subscript write without modifying another square.
We recommend checking `Square.isValid` before accepting a position edit.

## Repetition identity

We use `PositionKey` instead of `Board` as the key in `Game.positionsCounter`.
We include piece placement, the turn, castling rights, and a legally usable en passant target.
We exclude move counters and the order of castling rights.
We write castling rights in canonical `KQkq` order in FEN output.
We exclude an en passant target if the only capturing pawn is pinned.
We expose `Game.repetitionCount` for the current position.

We start the current position at one occurrence.
We count later occurrences only through successful `Game.make` calls.
We preserve the count, history, and position in `Game.deepCopy()`.
We use Swift value storage so independent copies do not require an eager history traversal.

We reset the history and occurrences when the caller assigns or edits `game.position`.
This includes a nested counter or board edit and assignment of an equal position.
We treat that operation as a new starting position.
We do not reset history when `Game.make` advances the line.

We retain the optional `moves` initializer argument for an existing display history.
Those moves do not prove earlier position occurrences.
To reconstruct repetition evidence, we start at the original position and replay the recorded legal moves.

## Results and claims

We inspect the current position with `Game.status`.
We report an invalid position, an ongoing position, checkmate with a winner, or an automatic draw reason.
We check mate and stalemate before move-count and repetition draws.
We support fivefold repetition and the seventy-five-move threshold as automatic results.
We keep threefold repetition and the fifty-move threshold as claims.

We read `Game.availableDrawClaims` for claims supported by the current position.
We call `try game.drawClaims(after: move)` to inspect a declared move without changing the game.
We reject an illegal declared move or an update that would overflow a counter.
We return no claims when a terminal result takes precedence.
We do not apply a claim or record the arbiter's decision.

We permit legal analysis moves after an automatic draw.
We calculate status for the current position; we do not retain an earlier result after the study continues.
The host app must retain an adjudicated result if it runs a live game.

## Dead-position scope

We report a proven material draw for these cases:

- Two bare kings.
- One bishop or one knight in total, in addition to the kings.
- Bishops only, with every bishop confined to the same square color, in addition to the kings.

We do not declare two knights against a king dead: a mating position can exist.
We do not declare opposite-colored bishops dead from material alone.
We report `.notEstablished` for material outside the proven cases.
That value does not prove that mate is possible.
We do not solve arbitrary blocked positions, fortresses, or forced capture sequences.
Thus `.ongoing` means that our supported checks did not establish a terminal result.
It is not an exhaustive dead-position proof.

## Migration

We describe the position-key change, direct-edit behavior, and consumer integration in the [migration guide](MIGRATION.md).
