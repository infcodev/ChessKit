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

The FEN, SAN, and move parsers assume valid input in several locations.
Invalid input can cause an index error, a failed forced unwrap, or a failed precondition.
These failures can stop the app instead of returning an error.

`Game.make` applies a move without a legal move check.
A consumer must check a move before it calls this method.
This check still depends on the correctness of the legal move generator.

We also found limits in position validation.
For example, the castling generator trusts the supplied rights without checking that the required rook exists.
We will define parser and position checks separately.

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

Our source review also found incomplete SAN disambiguation.
Some positions require both the source file and the source rank.
The current output logic does not handle that combination.
The input parser can select the first candidate without checking that it is unique.
We will add regression cases for both conditions.

## Repetition and game results

The repetition counter uses piece placement as its key.
The key does not include the turn, castling rights, or relevant en passant state.
We cannot use this counter alone to decide a draw by repetition.

The package has no complete game-result API.
We still need decisions and tests for draw claims, automatic draws, and dead positions.
We can identify stalemate from an empty legal move list when the side to move is not in check.

## Test and platform limits

The existing suite tests piece moves, special moves, SAN, FEN, and some game sequences.
We did not find a perft suite or an independent rules comparison in this revision.
We did not validate this revision across an iOS and macOS release matrix.

The [project status](PROJECT-STATUS.md) describes the inherited API pages and CI configuration.

## Scope limits

We do not provide full PGN import, a study tree, a board view, or a chess engine.
We did not establish support for Chess960 or other chess variants.
The [work plan](WORK-PLAN.md) covers the changes we intend to make.
