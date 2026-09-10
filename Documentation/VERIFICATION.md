# Verification

We use regression tests, public API tests, perft, and a separate implementation comparison.
We keep verification tools outside the library target.
We do not add a runtime dependency to the ChessKit product.

## Local commands

We select the installed Xcode developer directory before these commands when needed.
We run the complete debug suite with coverage:

```sh
swift test --enable-code-coverage
```

We also run optimized tests and reject Swift compiler warnings:

```sh
swift test -c release -Xswiftc -warnings-as-errors
```

We build the package for both simulator architectures:

```sh
xcodebuild -scheme ChessKit -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/ChessKit-iOS-build CODE_SIGNING_ALLOWED=NO build
```

We run the complete test suite on an available iPhone simulator:

```sh
python3 Tools/Verification/run-ios-tests.py --derived-data /tmp/ChessKit-iOS-tests
```

We can select an existing simulator with `--device-id` and optimized tests with `--configuration Release`.
We enable testability for this test invocation because inherited tests use `@testable import`.
We retain optimization in Release and leave ordinary library builds unchanged.
We fail the check if no suitable simulator is available.
We do not substitute compilation for test execution.

## Independent comparison

We compare with [python-chess 1.11.2](https://python-chess.readthedocs.io/en/latest/core.html).
We run its published package as a separate development tool.
We require its exact version in `Tools/Verification/requirements.txt`.
We do not copy its implementation, install it in the app, or link it into ChessKit.
We retain its [GPL-3.0-or-later license](https://github.com/niklasf/python-chess/blob/v1.11.2/LICENSE.txt).
We wrote our harness and test seeds separately under the repository's MIT license.
We retain the Kiwipete and rook-ending reference attribution in [perft notes](PERFT.md).

We use a separate Python environment:

```sh
python3 -m venv /tmp/chesskit-reference
/tmp/chesskit-reference/bin/python -m pip install -r Tools/Verification/requirements.txt
swift build --package-path Tools/Verification -c release -Xswiftc -warnings-as-errors
/tmp/chesskit-reference/bin/python Tools/Verification/compare.py --binary Tools/Verification/.build/release/ChessKitVerify
```

We compare legal move sets, SAN, SAN round trips, resulting FEN, check, results, repetition counts, and draw claims.
We include both colors, legal and pinned en passant, castling, promotion, draw thresholds, and terminal positions.
We include full histories for repetition checks.
We generate additional legal lines with fixed random seeds.
We report the original FEN, full move sequence, and differing fields on failure.
We never convert a failed comparison into a passing test.

We use twelve generated lines of up to eighty half-moves by default.
We can increase this scope with `--games` and `--plies`.
We do not compare invalid diagrams with a reference that has different editing semantics.
We test those boundaries through our public API instead.
Neither this finite corpus nor the material reference proves exhaustive dead-position detection.

## Adversarial black-box suite

We keep an additional consumer target in `Tests/ChessKitAdversarialTests`.
We design it from rules, public contracts, and frozen independent results without reading library internals.
We include hostile text, illegal moves, edited diagrams, state isolation, and an expanded rules campaign.
We document its matrix, commands, and limits in [adversarial testing](ADVERSARIAL-TESTING.md).

## Long lines

We test lines of 2,000 and 10,000 half-moves and copies of their recorded state.
We assert exact counters, history length, repetition counts, and independent mutation after copying.
We report elapsed time for move application and one hundred copies.
We do not use a fragile elapsed-time threshold as a correctness assertion.
For a separate optimized measurement, we run:

```sh
swift test -c release --filter LongLineTests
```

## Recorded local evidence

We record the final commands, counts, toolchain, and limits after the checks finish.
We distinguish local execution from remote CI.
We keep the latest evidence in [validation results](VALIDATION-RESULTS.md).

## CI

We run debug tests with coverage and optimized tests on the configured Xcode 16.4 runner.
We also run the independent comparison and iOS Simulator tests.
We keep the generic iOS Simulator build to cover compilation for both architectures.
We must check the remote jobs on the pushed revision before merging.
Local Xcode 26.6 evidence does not establish an executed Xcode 16.4 result.
