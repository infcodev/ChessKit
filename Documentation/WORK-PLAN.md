# Work plan

We will correct confirmed defects before we add new functions.
All work below is pending.
The [known limits](KNOWN-LIMITS.md) contain the supporting findings.

## Delivery order

| Step | Work                           | Acceptance criteria                                                            |
| ---- | ------------------------------ | ------------------------------------------------------------------------------ |
| 1    | Public serializer initializers | An external package constructs both serializers without `@testable`.           |
| 2    | Legal move defects             | Each reproduced defect has a passing regression test after the correction.     |
| 3    | Input contracts                | Invalid FEN, SAN, and move input returns documented errors.                    |
| 4    | SAN conversion                 | Capture markers and source-square disambiguation match the expected notation.  |
| 5    | Position identity              | Repetition tests account for the turn and relevant move rights.                |
| 6    | Game results                   | Tests distinguish draw claims, automatic draws, stalemate, and dead positions. |
| 7    | Release checks                 | The agreed tests pass on the documented toolchains and platforms.              |

We will define error types before we change parser signatures.
We will document incompatible API changes separately from rule corrections.
We will keep position editing separate from legal move generation.

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

We will replace the inherited branch filters with our agreed `main` workflow.
We will review action versions and external uploads before we enable CI.
We will keep credentials outside the source code.
We will not use the original project's coverage configuration.

## Release criteria

We will publish a release after the agreed checks pass.
We will document the supported platforms, toolchain, known limits, and migration steps.
We will use a major version for incompatible public API changes.
We will add an installation example with an exact tested version.

The inherited tags identify upstream releases.
We will not present an upstream tag as a release that includes our corrections.
