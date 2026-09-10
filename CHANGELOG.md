# Change history

## Unreleased

We have not assigned or published a fork version for these changes.
We require a major version because public contracts changed.
The [migration guide](Documentation/MIGRATION.md) lists the required consumer changes.

### Incompatible changes

- We make FEN input, coordinate-move parsing, both game-update overloads, and both SAN conversions throw recoverable errors.
- We replace board-only occurrence keys with public `PositionKey` values.
- We reset recorded history and repetitions when the caller assigns or edits `Game.position`.
- We reject illegal moves, invalid playable positions, and counter overflow without partial game updates.
- We return safe invalid squares for malformed coordinates and ignore invalid board writes.

### Rule and notation corrections

- We correct en passant simulation and include its capture marker and source file in SAN.
- We require the starting king and rook for castling and respect attacks on the king's route.
- We reject king captures and inconsistent en passant captures.
- We correct full-square SAN disambiguation and reject ambiguous input.
- We validate capture, promotion, and check details without changing the game during SAN inspection.
- We write castling rights in canonical FEN order after direct edits.

### Public capabilities

- We expose public serializer and position initializers and structured errors.
- We add static position validation and full repetition identity.
- We expose automatic results, current draw claims, and intended-move claims.
- We document conservative dead-position proofs and their limits.
- We preserve independent game copies through Swift value storage.

### Verification

- We add public consumer tests and an additional adversarial black-box target.
- We run 33 perft count checks, terminal controls, long-line tests, and independent comparisons.
- We freeze external expected results and test hostile input, rejected moves, and state isolation.
- We run optimized tests, iOS Simulator tests, and independent campaigns in the configured CI workflow.
- We record executed results separately from pending remote CI and app acceptance.

### Documentation

We keep the README as the project guide and centralize incompatible changes in the migration guide.
We separate current limits, remaining work, historical corrections, and dated validation evidence.
We regenerate the API reference from the corrected public declarations.
We retain the upstream license, attribution, and original release notes.

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
