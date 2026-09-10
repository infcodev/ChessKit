# Known limits

We reviewed upstream `2.0.0` at commit `bee00f535ae6c6182cc3d9c9a5bd5cfb5cbc5d83`.
We separate source review findings from executed test results.

## Public serializers

We corrected this access limit in the working revision.
The FEN and SAN serializer classes now have public initializers.
We test their construction and basic conversions without `@testable` in a separate test target.
We confirmed that these tests failed to compile before the correction.

We track the upstream report in [issue 15](https://github.com/aperechnev/ChessKit/issues/15).
[Pull request 16](https://github.com/aperechnev/ChessKit/pull/16) proposes public initializers and an external API test.
We added the initializers and our own public API regression tests.

## Invalid input

We corrected FEN format handling in the working revision.
`FenSerialization.deserialize(fen:)` now throws `FenSerializationError` for invalid fields.
We check all six fields before returning a position.
The [FEN input guide](FEN-INPUT.md) records the accepted format and the required `try` migration.

We added recoverable coordinate-move and SAN errors in the working revision.
`Game.make` now checks legality and calculates all updates before it changes the game.
Counter overflow returns an error without modifying the position, history, or occurrence counts.
The [moves and SAN guide](MOVES-AND-SAN.md) records the accepted input and required API migration.

We keep parser and position checks separate.
FEN parsing still accepts incomplete boards for position editing.
The legality checks depend on the move generator and do not validate arbitrary direct board or square edits.
We have not established that an edited position is reachable from legal play.

## Castling

We reproduced and corrected castling moves with missing or incorrect starting pieces.
We now require the king on e1 or e8 and a friendly rook on the relevant corner.
We retain the checks for castling rights and an empty path.
We also reject castling from the attack of an adjacent opposing king in an imported position.

We confirmed 22 failures before the correction.
We added 70 cases across five parameterized tests for both colors and both sides.
We cover attacks on the king's route, including attacks by pinned pieces.
We also verify that an attacked rook or b-file square does not prevent valid castling.
We check SAN, the resulting FEN, move history, and castling rights after all four castling moves.

## En passant simulation

We reproduced and corrected a defect in the legal move filter.
The filter removed a pawn when another piece moved to the en passant square.
This could accept an illegal move or reject a legal move.
We now remove the captured pawn in the simulation only when a pawn moves.

We retain this regression case:

| Field           | Value                                                                   |
| --------------- | ----------------------------------------------------------------------- |
| FEN             | `7k/8/8/3p1N2/4K3/8/8/8 w - d6 0 2`                                     |
| Move            | `f5d6`                                                                  |
| Expected result | The move is illegal. The pawn on d5 still attacks the white king on e4. |
| Evidence        | Executed regression tests for both colors.                             |
| Test status     | Failed before the correction; passed after the correction.              |

## SAN output and input

We reproduced and corrected the missing source file and capture marker in en passant SAN.
The serializer now produces `exd6` for the capture from e5 to d6.
We test both colors, both capture directions, and captures that give direct or discovered check.
We confirmed eight SAN failures before the correction.
[Upstream issue 17](https://github.com/aperechnev/ChessKit/issues/17) reports the original defect.

We reproduced and corrected incomplete source-square disambiguation.
We now write both the file and rank when neither alone identifies the moving piece.
We require a unique legal match when reading SAN.
We verify supplied capture, promotion, castling, and check details.
SAN inspection no longer advances counters on a game copy.
The [moves and SAN guide](MOVES-AND-SAN.md) describes accepted import alternatives and rejected annotations.

## Repetition and game results

The repetition counter uses piece placement as its key.
The key does not include the turn, castling rights, or relevant en passant state.
We cannot use this counter alone to decide a draw by repetition.

The package has no complete game-result API.
We still need decisions and tests for draw claims, automatic draws, and dead positions.
We can identify stalemate from an empty legal move list when the side to move is not in check.

## Test and platform limits

The existing suite tests piece moves, special moves, SAN, FEN, and some game sequences.
We added a perft baseline with seven reference positions and two terminal-position controls.
We check all intermediate depths, through depth four for the initial position and rook ending, and depth three for the others.
The [perft notes](PERFT.md) record the sources, counts, and limits.
We have not added a live comparison against an independent chess implementation.
We did not validate this revision across an iOS and macOS release matrix.

The [project status](PROJECT-STATUS.md) describes the inherited API pages and CI configuration.

## Scope limits

We do not provide full PGN import, a study tree, a board view, or a chess engine.
We did not establish support for Chess960 or other chess variants.
The [work plan](WORK-PLAN.md) covers the changes we intend to make.
