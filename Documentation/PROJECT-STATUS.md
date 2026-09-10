# Project status

We use this document for version-specific information.
The [README](../README.md) describes the purpose and use of the library.

## Baseline

We started from upstream `master` at commit `bee00f535ae6c6182cc3d9c9a5bd5cfb5cbc5d83`.
This commit is upstream version `2.0.0`.
We use `main` as the default branch of [our fork](https://github.com/infcodev/ChessKit).

We updated the project documentation and CI configuration.
We added public serializer initializers and a separate public API test target.
We corrected en passant simulation and SAN capture output.
We added tests for legal moves, illegal moves, and capture notation.
We corrected castling generation to require the starting pieces and respect attacks by the opposing king.
We added castling regression cases and controls for valid moves.
We did not publish a new package release.
The inherited tags identify upstream releases, not our corrections.

## Integration status

We expose public initializers for the FEN and SAN serializers in the working revision.
An external app can construct both serializers.
The README board example remains valid.
We changed `FenSerialization.deserialize(fen:)` to throw recoverable errors for invalid FEN fields.
Consumers must add `try` and handle or propagate `FenSerializationError`.
The [FEN input guide](FEN-INPUT.md) describes this incompatible API change.
SAN and coordinate-move validation and the remaining rule corrections are still pending.

We do not recommend this revision for production use.
The [known limits](KNOWN-LIMITS.md) record the current findings.
The [work plan](WORK-PLAN.md) defines the proposed corrections and tests.

## Existing tests

The original tests use `@testable import ChessKit` and can access internal declarations.
We added `ChessKitPublicAPITests` as a separate test target with a plain `import ChessKit`.
We test serializer construction, a FEN round trip, and SAN input and output for pawn and knight moves.
We extended this target with FEN errors, input boundaries, and recovery after failure.
These tests do not establish complete SAN validation or position legality.

We added a perft baseline with 30 published count checks and terminal-position controls.
We include these checks in the normal test suite.
The [perft notes](PERFT.md) describe their scope and reference data.

## Generated API pages

We retain the upstream pages in `docs/` as historical reference material.
Those pages can contain examples that do not compile from an external app.
We did not regenerate those pages for this documentation update.
We will check the examples and generate new pages after the public API changes.

## CI

We configured CI for pushes and pull requests to `main`, with optional manual runs.
We run tests with coverage on macOS and build for the iOS Simulator.
We use Xcode 16.4 on `macos-15` and store coverage as a GitHub artifact.
We removed the inherited Codecov configuration.

## Release publication

We will publish a release after the agreed checks pass.
We will record the supported toolchains, platforms, and migration steps with that release.
The [change history](../CHANGELOG.md) will identify the changes in each version.
