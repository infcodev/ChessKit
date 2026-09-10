# Change history

## Unreleased

We expose public initializers for `FenSerialization` and `SanSerialization`.
We add a separate test target that uses only the public API.
We correct en passant simulation so that other pieces do not remove the pawn.
We include the source file and capture marker in en passant SAN, including captures that give check.
We add regression tests for both colors and preserve the public method signatures.

We require the king and a friendly rook on their starting squares before we generate castling moves.
We reject castling from a square attacked by an adjacent opposing king.
We test blocked paths, attacked squares, valid castling, and the resulting position.

We add a perft baseline with seven reference positions and 30 count checks.
We add mate and stalemate controls and root-move diagnostics for count failures.
We preserve the current rules implementation in this test-only change.

### Incompatible API change: FEN input

We changed `FenSerialization.deserialize(fen:)` to a throwing method.
We added public `FenSerializationError` cases for each invalid field and the field count.
We check rank structure, ASCII symbols, castling order, en passant state, and counter bounds.
We accept surrounding whitespace and normalize leading counter zeros on output.
We preserve incomplete boards for position editing.
We added public input tests and updated all existing test consumers to use `try`.
The [FEN input guide](Documentation/FEN-INPUT.md) describes the migration and validation limits.

### Incompatible API change: moves and SAN

We changed `Move.init(string:)`, both `Game.make` overloads, and both SAN conversion methods to throwing operations.
We added `MoveParsingError`, `GameMoveError`, and `SanSerializationError`.
We reject malformed coordinate and SAN input, illegal moves, ambiguous SAN, and incorrect check suffixes.
We corrected SAN output when disambiguation requires the full source square.
We calculate counter updates before modifying the game and reject overflow without partial changes.
We share board effects between game updates and SAN inspection; notation does not advance counters.
We added public regressions and preserved the existing rule and perft checks.
The [moves and SAN guide](Documentation/MOVES-AND-SAN.md) describes the migration and remaining limits.

### Incompatible API change: position identity and editing

We change `Game.positionsCounter` from board keys to public `PositionKey` values.
We account for the turn, castling rights, and legal en passant captures.
We reset history and occurrence counts after direct edits to `Game.position`.
We expose initializers and static validation for position data.
We reject invalid starting positions in `Game.make` without partial updates.
We make invalid square access safe and reject malformed coordinate aliases.
We write castling rights in canonical FEN order after position edits.
We reject king captures and en passant captures without the required board state.

### Results and verification

We add automatic results and separate current and declared-move draw claims.
We document the conservative scope of dead-position detection.
We preserve independent copies with Swift value storage instead of copying each history element.
We extend perft to 33 count checks and add long-line and public contract tests.
We compare public behavior with a separate pinned python-chess installation.
We extend CI to optimized tests, independent comparison, and iOS Simulator test execution.
The [game-state guide](Documentation/GAME-STATE.md) and [verification guide](Documentation/VERIFICATION.md) record the contracts and checks.

### Fork documentation

We made the README a project guide.
We separated project status, known limits, and planned work into reference documents.
We added contribution instructions and documentation rules.
We retained the upstream source code, tests, license, and release history.
We did not publish a new package release.

## Upstream release history

We preserve the original release notes below.

## [2.0.0] - 30.09.2025

### Added

### Changed

- Updated Swift Tools to version `6.1`.
- Removed the default field from several classes to meet the requirements of Swift 6.0 and higher:
    - `FenSerialization.default`
    - `Rays.default`
    - `MovingTranslations.default`
    - `SanSerialization.default`
- Migrated tests from **XCTest** to the modern **Testing** framework.
- Migrated documentation from **Jazzy** to **DocC**.
- Removed **CocoaPods** support.

### Fixed

## [1.3.7] - 01.04.2022

### Added

### Changed

### Fixed

– Bug fixes

## [1.3] - 04.03.2021

### Added

– SAN serialization

### Changed

### Fixed

– Fix for king moves
