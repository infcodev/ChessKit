# Validation results — 10 September 2026

We validated the local working revision on `chesskit-corrections`.
We did not publish a release, create a tag, commit, or push these changes.
We keep the commands and limits here so a reviewer can repeat the checks.

## Environment

| Component | Executed configuration |
| --- | --- |
| macOS | 26.6, build 25G72, Apple silicon |
| Xcode | 26.6, build 17F113 |
| Swift | 6.3.3 |
| iOS runtime | iOS Simulator 18.6, iPhone 16e, arm64 |
| Independent reference | Python 3.12 with chess 1.11.2 |

We set `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` for Swift and Xcode commands.
We have not executed the configured Xcode 16.4 remote jobs for this patch.

## Correctness checks

| Command | Final result |
| --- | --- |
| `swift test --enable-code-coverage` | 131 test functions passed; 107.981 seconds of test execution. |
| `swift test -c release -Xswiftc -warnings-as-errors` | 131 test functions passed; 4.922 seconds of test execution. |
| `python3 Tools/Verification/run-ios-tests.py --derived-data /tmp/ChessKit-final-validation-iOS --device-id 6C910ADD-E346-40A3-97DC-D55F8692EEAD --configuration Release` | 131 test functions passed across both test targets; Xcode reported `TEST SUCCEEDED`. |
| `xcodebuild -scheme ChessKit -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/ChessKit-final-validation-iOS-build CODE_SIGNING_ALLOWED=NO build` | Build passed for arm64 and x86_64. |
| `swift build --package-path Tools/Verification -c release -Xswiftc -warnings-as-errors` | Public API verifier compiled without Swift warnings. |
| `python3 Tools/Verification/compare.py --binary Tools/Verification/.build/release/ChessKitVerify` | 1,034 positions and 20,982 legal move candidates matched; 3.667 seconds. |

We count Swift Testing functions separately from their parameterized cases.
We do not use the empty XCTest wrapper's count as the Swift Testing result.
We executed the complete iOS debug suite before the final FEN-order regression was added.
We use the final iOS Release run above as the evidence for all 131 functions.
We enabled testability for that test invocation because the inherited tests use `@testable import`.
We kept Release optimization enabled.

The Xcode test build emitted two AppIntents metadata warnings because this library has no AppIntents dependency.
We observed no Swift compiler warning in the optimized package or verifier build.

## Regression evidence

We confirmed six failures with nine assertions before correcting square aliases, missing en passant pawns, king capture, repetition rights, and direct-edit history.
We separately confirmed a failing FEN-order test with two issues before correcting the output order.
We corrected one inherited expectation that allowed a knight to capture the opposing king.
We retained a dedicated public regression for that prohibition.

## Perft and coverage

We checked 33 counts across seven reference positions and retained the terminal-position controls.
We reached 4,865,609 leaves at depth five from the initial position.
We reached 4,085,603 leaves at depth four from Kiwipete and 674,624 at depth five from the rook ending.
The [perft notes](PERFT.md) record the reference attribution.

We measured source line coverage of 1,767 out of 1,780 lines, or 99.27%.
We measured 100% line coverage in Board, Square, PositionKey, PositionValidation, and GameStatus.
We do not treat line coverage as proof of complete rule correctness.

## Long-line measurements

We run `swift test -c release -Xswiftc -warnings-as-errors --filter LongLineTests` separately from perft.
We test 2,000 and 10,000 half-moves, exact history and counters, and one hundred independent game copies.
We report timing in the test output without a fixed performance threshold.
We use a reversible knight cycle, so these measurements do not represent a large branching study tree.
We retain value-copy independence when a copied game makes a different move.

## Static checks

We parse the workflow YAML and confirm that all three jobs are present.
We parse both Python scripts with `ast.parse`.
We check changed lines with `git diff --check` and check new files for trailing whitespace and missing final newlines.
We review local documentation links.
We have no separate Swift linter configured in this repository.

## Remaining limits

We still need the remote CI result on the pushed revision, including Xcode 16.4.
We did not run tests on physical iOS hardware or an Intel Mac in this change.
We use conservative dead-position detection and static position validation, not exhaustive reachability proofs.
We have not regenerated the inherited API pages or prepared a release.
The [game-state guide](GAME-STATE.md) and [known limits](KNOWN-LIMITS.md) define the supported contracts.
