# Work plan

We will correct confirmed defects before we add new functions.
We completed the serializer access and input contracts described below.
We also corrected en passant, castling, and SAN conversion in the working revision.
The remaining corrections are pending.
The [known limits](KNOWN-LIMITS.md) contain the supporting findings.

## Delivery order

| Step | Work                           | Acceptance criteria                                                            |
| ---- | ------------------------------ | ------------------------------------------------------------------------------ |
| 1    | Public serializer initializers | A separate consumer test target constructs both serializers without `@testable`.           |
| 2    | Legal move defects             | Each reproduced defect has a passing regression test after the correction.     |
| 3    | Input contracts                | Invalid FEN, SAN, and move input returns documented errors.                    |
| 4    | SAN conversion                 | Capture markers and source-square disambiguation match the expected notation.  |
| 5    | Position identity              | Repetition tests account for the turn and relevant move rights.                |
| 6    | Game results                   | Tests distinguish draw claims, automatic draws, stalemate, and dead positions. |
| 7    | Release checks                 | The agreed tests pass on the documented toolchains and platforms.              |

We will define error types before we change parser signatures.
We will document incompatible API changes separately from rule corrections.
We will keep position editing separate from legal move generation.

## Completed API correction

We added public initializers for both serializers.
We added a separate test target for public API consumption.
We confirmed the access errors before the correction.
That access correction preserved the parser signatures and conversion behavior.
The later FEN input correction changes its parser signature, as documented below.

## Completed en passant corrections

We corrected pawn removal in the legal move simulation.
We corrected the source file and capture marker in SAN output.
We confirmed four legal-move failures and eight SAN failures before their corrections.
We added 22 cases across six parameterized tests, including controls for existing behavior.
We test both colors, pawn checks, rook checks, captures, and ordinary pawn advances.

We wrote the small test positions for these regressions.
We use [FIDE Laws of Chess](https://handbook.fide.com/chapter/E012023), articles 3.7.3 and 3.9.2, for the capture and king-safety rules.
We keep malformed position validation separate from these corrections.

## Completed castling corrections

We require the king and a friendly rook on their starting squares.
We prevent castling from the attack of an adjacent opposing king.
We preserve the existing public method signatures.
We confirmed 22 failures before the correction and added 70 parameterized cases.

We wrote the test positions for these regressions.
We use [FIDE Laws of Chess](https://handbook.fide.com/chapter/E012023), articles 3.8.2 and 3.9.2, for the castling requirements.
We test both colors, both sides, blocked paths, and attacked squares.
We also test valid castling with an attacked rook or b-file square.

## Completed perft baseline

We added seven reference positions with 30 count checks and separate mate and stalemate controls.
We compare the results at every depth through each position's stated maximum.
We preserve the starting position, history, and repetition counter during traversal.
We report counts per root move when a result differs.
The [perft notes](PERFT.md) record data attribution, commands, and validation limits.

## Completed FEN input contract

We added the public `FenSerializationError` type before changing the parser signature.
We made `deserialize(fen:)` throw recoverable errors for invalid fields.
We reproduced eight invalid active-color cases before the correction.
We added public consumer tests for malformed records and accepted input boundaries.

We preserve incomplete positions for editing and keep game-state legality separate.
The [FEN input guide](FEN-INPUT.md) records the contract, migration, and validation limits.
The later move and SAN correction completes their input contracts and protects counter increments.

## Completed move and SAN input contracts

We added public errors for coordinate input, SAN conversion, and game updates.
We changed their public operations to throw recoverable errors.
We reject illegal moves and calculate all updates before modifying game state.
We use checked increments for halfmove, fullmove, and occurrence counters.

We reproduced five failing tests with ten assertions before the correction.
We also reproduced the fullmove overflow in an isolated test process.
We corrected SAN ambiguity and full-square disambiguation.
We test both colors, promotion choices, check suffixes, malformed input, and unchanged state after failure.
The [moves and SAN guide](MOVES-AND-SAN.md) records the contract and migration.

Position identity and game results remain the next rule domains.
They are not completed by these input checks.

## Test plan

We will add these test groups:

- Public API tests without internal access.
- Regression tests for reproduced defects.
- Deeper perft tests beyond the completed baseline.
- Tests for both colors and all four promotion choices.
- Castling, en passant, pinned piece, and double-check tests.
- FEN and SAN input and output tests.
- Invalid and ambiguous input tests.
- Repetition and game-result tests.
- Comparisons with an independent chess implementation.
- Performance measurements for long move sequences.

We will record the source and license of external test data.
We will record the toolchain, command, result, and limits of each check.
We will not present unexecuted tests as evidence of correctness.

## CI preparation

We configured the `main` workflow with macOS tests and an iOS Simulator build.
We pinned action revisions and removed the inherited Codecov configuration.
We keep credentials outside the source code.
We check CI results for each pull request.

## Release criteria

We will publish a release after the agreed checks pass.
We will document the supported platforms, toolchain, known limits, and migration steps.
We will use a major version for incompatible public API changes.
We will add an installation example with an exact tested version.

The inherited tags identify upstream releases.
We will not present an upstream tag as a release that includes our corrections.
