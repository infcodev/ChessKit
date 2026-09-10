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
