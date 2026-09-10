# Work plan

We will correct confirmed defects before we add new functions.
We completed the public API correction and the two en passant corrections in the working revision.
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
We preserved the parser signatures and conversion behavior.

## Completed en passant corrections

We corrected pawn removal in the legal move simulation.
We corrected the source file and capture marker in SAN output.
We confirmed four legal-move failures and eight SAN failures before their corrections.
We added 22 cases across six parameterized tests, including controls for existing behavior.
We test both colors, pawn checks, rook checks, captures, and ordinary pawn advances.

We wrote the small test positions for these regressions.
We use [FIDE Laws of Chess](https://handbook.fide.com/chapter/E012023), articles 3.7.3 and 3.9.2, for the capture and king-safety rules.
We keep malformed position validation separate from these corrections.

## Test plan

We will add these test groups:

- Public API tests without internal access.
- Regression tests for reproduced defects.
- Perft tests with reference positions and expected node counts.
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
