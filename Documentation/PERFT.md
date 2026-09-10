# Perft checks

We use perft to compare legal move sequences with published reference counts.
A depth of one means one half-move, not a full turn by both players.
We count leaves at the requested depth. We count transpositions as separate move sequences.

## Reference data

We use the [Perft Results tables](https://chessprogramming.org/Perft_Results) from the Chess Programming Wiki.
We retrieved the tables on 10 September 2026.
The contributors include GerdIsenberg, Alessandro Iavicoli, Phhnguyen, Smatovic, Folkert van Heusden, and Callum Moss.
The page credits Peter McKenzie for Kiwipete and Steven Edwards for several reference results.

We retain the source attribution and [CC BY-SA 3.0 license](https://creativecommons.org/licenses/by-sa/3.0/) for the reference data.
We transcribed the FEN positions and node counts and limited the checked depths.
We added the FEN move counters `0 1` to Kiwipete.
We wrote the test implementation separately under this repository's MIT license.
We did not copy engine code or add a runtime dependency.

| Position | Maximum depth | Expected leaves at that depth |
| --- | --- | --- |
| Initial position | 5 | 4,865,609 |
| Kiwipete | 4 | 4,085,603 |
| Rook and pawn ending | 5 | 674,624 |
| Promotions and castling, White to move | 3 | 9,467 |
| Promotions and castling, mirrored | 3 | 9,467 |
| Tactical promotions | 3 | 62,379 |
| Middlegame | 3 | 89,890 |

We check every depth from zero through the maximum in this table.
This gives 33 reference count checks across seven positions.
We use depth zero to check the perft convention of one leaf, including at terminal positions.

## Test procedure

Run the perft tests:

```sh
swift test --filter 'standardPerft|terminalPerft'
```

Run all tests with coverage:

```sh
swift test --enable-code-coverage
```

We include perft in the normal test suite and CI.
The tests use fixed local data and need no external chess service.
We use `Game.legalMoves`, `Game.deepCopy`, and `Game.make` through their public API.
We use no position cache or draw adjudication in the counter.

We count legal moves directly at depth one.
At greater depths, we copy the game and apply each move before continuing.
We check that the original position, history, and repetition counter remain unchanged.
We also test checkmate and stalemate: each has zero leaves at positive depths when there are no legal moves.

## Failure diagnosis

We report the position, depth, expected count, and actual count on failure.
We also report the count for each root move to help locate a branch with incorrect moves.
We calculate this additional report only when a reference count differs.

## Validation limits

These tests check move generation and state changes across a bounded set of positions and depths.
They do not prove complete chess correctness or validate SAN, malformed input, draw claims, or a full release matrix.
We keep individual regression tests for those responsibilities.
We also run a separate comparison against python-chess.
The [verification guide](VERIFICATION.md) describes that check.
