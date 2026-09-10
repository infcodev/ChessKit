# Correction history

We retain the implementation record from the correction phase that started with upstream 2.0.0.
We keep historical failure counts as evidence for their original changes.
We use [project status](PROJECT-STATUS.md) for the current state and [known limits](KNOWN-LIMITS.md) for remaining restrictions.
We record the later black-box campaign in [adversarial testing](ADVERSARIAL-TESTING.md).

## Completed correction steps

### Completed API correction

We added public initializers for both serializers.
We added a separate test target for public API consumption.
We confirmed the access errors before the correction.
That access correction preserved the parser signatures and conversion behavior.
The later FEN input correction changes its parser signature, as documented below.

### Completed en passant corrections

We corrected pawn removal in the legal move simulation.
We corrected the source file and capture marker in SAN output.
We confirmed four legal-move failures and eight SAN failures before their corrections.
We added 22 cases across six parameterized tests, including controls for existing behavior.
We test both colors, pawn checks, rook checks, captures, and ordinary pawn advances.

We wrote the small test positions for these regressions.
We use [FIDE Laws of Chess](https://handbook.fide.com/chapter/E012023), articles 3.7.3 and 3.9.2, for the capture and king-safety rules.
We keep malformed position validation separate from these corrections.

### Completed castling corrections

We require the king and a friendly rook on their starting squares.
We prevent castling from the attack of an adjacent opposing king.
We preserve the existing public method signatures.
We confirmed 22 failures before the correction and added 70 parameterized cases.

We wrote the test positions for these regressions.
We use [FIDE Laws of Chess](https://handbook.fide.com/chapter/E012023), articles 3.8.2 and 3.9.2, for the castling requirements.
We test both colors, both sides, blocked paths, and attacked squares.
We also test valid castling with an attacked rook or b-file square.

### Completed perft baseline

We added seven reference positions with 30 count checks and separate mate and stalemate controls.
We compare the results at every depth through each position's stated maximum.
We preserve the starting position, history, and repetition counter during traversal.
We report counts per root move when a result differs.
The [perft notes](PERFT.md) record data attribution, commands, and validation limits.

### Completed FEN input contract

We added the public `FenSerializationError` type before changing the parser signature.
We made `deserialize(fen:)` throw recoverable errors for invalid fields.
We reproduced eight invalid active-color cases before the correction.
We added public consumer tests for malformed records and accepted input boundaries.

We preserve incomplete positions for editing and keep game-state legality separate.
The [FEN input guide](FEN-INPUT.md) records the contract, migration, and validation limits.
The later move and SAN correction completes their input contracts and protects counter increments.

### Completed move and SAN input contracts

We added public errors for coordinate input, SAN conversion, and game updates.
We changed their public operations to throw recoverable errors.
We reject illegal moves and calculate all updates before modifying game state.
We use checked increments for halfmove, fullmove, and occurrence counters.

We reproduced five failing tests with ten assertions before the correction.
We also reproduced the fullmove overflow in an isolated test process.
We corrected SAN ambiguity and full-square disambiguation.
We test both colors, promotion choices, check suffixes, malformed input, and unchanged state after failure.
The [moves and SAN guide](MOVES-AND-SAN.md) records the contract and migration.

### Completed position and result contracts

We use a public `PositionKey` for repetitions and reset evidence after direct position edits.
We distinguish current draw claims, declared-move claims, and automatic results.
We expose static position validation and safe square boundaries.
We reject king captures and inconsistent en passant captures.
We use conservative material proofs for dead positions and expose the remaining uncertainty.
The [game-state guide](GAME-STATE.md) records these contracts and migration steps.

We confirmed six failing regressions with nine assertions before these corrections.
We later reproduced and corrected noncanonical FEN output after reordering castling rights.
We corrected an inherited test that expected a knight to capture the opposing king.
We retained a separate public regression for that rule.
We extended perft, added long-line checks, and added an independent comparison tool.
The [verification guide](VERIFICATION.md) records commands and platform scope.


## Original defect reports

We retain these reports to explain the corrected behavior.
We do not list them as open defects.

## Public serializers

We corrected this access limit in the working revision.
The FEN and SAN serializer classes now have public initializers.
We test their construction and basic conversions without `@testable` in a separate test target.
We confirmed that these tests failed to compile before the correction.

We track the upstream report in [issue 15](https://github.com/aperechnev/ChessKit/issues/15).
[Pull request 16](https://github.com/aperechnev/ChessKit/pull/16) proposes public initializers and an external API test.
We added the initializers and our own public API regression tests.

### Invalid input

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
We added safe square and board access and static position validation.
The [game-state guide](GAME-STATE.md) defines the editing boundary and its errors.
We have not established that an edited position is reachable from legal play.

### Castling

We reproduced and corrected castling moves with missing or incorrect starting pieces.
We now require the king on e1 or e8 and a friendly rook on the relevant corner.
We retain the checks for castling rights and an empty path.
We also reject castling from the attack of an adjacent opposing king in an imported position.

We confirmed 22 failures before the correction.
We added 70 cases across five parameterized tests for both colors and both sides.
We cover attacks on the king's route, including attacks by pinned pieces.
We also verify that an attacked rook or b-file square does not prevent valid castling.
We check SAN, the resulting FEN, move history, and castling rights after all four castling moves.

### En passant simulation

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

### SAN output and input

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

### Repetition and game results

We corrected repetition identity to include the turn and relevant move rights.
We distinguish claims from automatic results and reject results from structurally invalid positions.
We reset recorded repetition evidence after a direct position edit.
We cannot reconstruct prior repetitions from a FEN or an unverified historical move list alone.

We use conservative material proofs for dead positions.
We do not solve all blocked positions or forced continuations.
We return `DeadPositionAssessment.notEstablished` outside the proven cases.
We do not claim that this value proves a possible mate.
We do not model time controls, resignation, draw agreements, or claim acceptance.
The [game-state guide](GAME-STATE.md) records these limits.

