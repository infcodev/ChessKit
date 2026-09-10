# Adversarial black-box tests

We define these tests from public contracts and independent results.
We do not inspect `Sources/ChessKit` when we design this suite.
We use plain `import ChessKit`, without `@testable`, mocks, or internal state injection.
We keep failures visible. We do not correct library code during this test-design phase.

## Sources and scope

We use the [FIDE Laws of Chess](https://handbook.fide.com/chapter/E012023), articles 3, 5, and 9, for standard play.
We use the [PGN specification](https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm), sections 8.2.3 and 16.1.3, for notation.
We use our published [FEN](FEN-INPUT.md), [move and SAN](MOVES-AND-SAN.md), and [state](GAME-STATE.md) contracts for import allowances and errors.
We compare legal positions with the external `chess==1.11.2` package through its public API.
We do not use that package's more permissive notation parser as our input-validation contract.
We do not copy its implementation into this repository.

## Test matrix defined before execution

| Area | Adversarial input | Required observation |
| --- | --- | --- |
| En passant | Edge files, two possible capturers, pins, discovered check, check evasion, both colors | Exact legal move set, removed pawn, SAN, and position identity |
| Castling | Each right subset, attacked transit squares, pinned attackers, corner-rook captures, blocked paths | Exact legal moves and rights after each candidate |
| Promotion | Every file and choice, capture and quiet promotion, check and mate | No missing or extra move; exact SAN and resulting piece |
| Disambiguation | Multiple equal pieces, pins, crowded and sparse boards | Canonical source file, rank, or full square; no arbitrary choice |
| King safety | Single and double check, x-rays, adjacent attack squares | Exact legal evasions; no king capture |
| State history | Repetition cycles, lost rights, branches, copies, rejected moves, direct edits | Exact occurrence count; independent branches; failure is atomic |
| Draw boundaries | Halfmove clocks 98, 99, 100, 149, and 150; repetition thresholds; terminal positions | Correct current and intended claims; mate takes precedence |
| Numeric bounds | Integer extrema, promotion and capture resets | Recoverable errors; unchanged state after overflow |
| Hostile text | Control characters, Unicode lookalikes, long tokens, malformed FEN fields | Rejection according to grammar; recovery with the same serializer |
| Geometric bounds | Every board square and invalid translations | No wraparound or aliasing |
| Long sequences | Deterministic lines biased toward tactical moves | Agreement at sampled positions, including full history |

## Independent expected results

We generate the committed JSON corpus before we compare it with ChessKit.
We record legal moves, canonical SAN, child FEN, check, result, repetition, and claims.
We keep generation separate from verification: verification never rewrites expected results.
We include mirrored positions to exercise both colors.
We screen generated positions with the reference validator.
We do not claim that every synthetic position has a known legal history.

We also run a larger deterministic campaign against the public API executable.
We report the seed, full move sequence, and differing fields on failure.
We impose a response timeout so that a hung library fails the campaign.
We record scenario and special-move counts to detect an accidentally trivial corpus.

## Limits

We do not prove that every chess position is correct.
A second implementation can share a mistake with ours.
We therefore combine comparison tests with explicit contract checks and state invariants.
We do not infer complete dead-position detection from a material-only oracle.
We do not test Chess960, full PGN parsing, clocks, or app UI contracts here.
We cannot reach a repetition count near `Int.max` through a practical public-API test.
We do not inspect coverage or mutate library code to select these cases.

## Execution

We run the offline suite with `swift test --filter Adversarial`.
We include 14 test functions across five suites.
We test all 64 × 64 coordinate pairs and five promotion states in eight selected positions.
This produces 163,840 move-acceptance checks against independently generated legal sets.
We also test 306 frozen positions and 4,862 legal candidates, including their child positions.
We alter canonical SAN tokens to test incorrect suffixes and missing capture or promotion markers.
We retain each manually defined anchor when we sample the generated corpus.

We verify the frozen corpus without consulting ChessKit or rewriting the fixture:

```sh
python3 Tools/Verification/adversarial.py --check-corpus Tests/ChessKitAdversarialTests/Fixtures/independent.json
```

We run the default campaign after we build the existing public API verifier:

```sh
swift build --package-path Tools/Verification -c release -Xswiftc -warnings-as-errors
python3 Tools/Verification/adversarial.py --binary Tools/Verification/.build/release/ChessKitVerify --report /tmp/chesskit-adversarial-report.json
```

We run a larger local campaign with these arguments:

```sh
python3 Tools/Verification/adversarial.py --binary Tools/Verification/.build/release/ChessKitVerify --sparse 12000 --games 96 --plies 400 --report /tmp/chesskit-adversarial-expanded.json
```

We include the offline target in the complete Swift test command.
We add corpus verification and the default campaign to CI.
We upload the campaign report, including failures, as a CI artifact.
We do not treat local execution as proof that the remote CI runner passed.

We use `--write-corpus` only when we deliberately revise the input matrix.
We generate expected results before querying ChessKit and review changes to the fixture.
We never update the fixture from the actual ChessKit response.

## Test-design correction

We initially expected a claim query at `Int.max` halfmoves to throw an overflow error.
That position already has an automatic result.
Our public contract gives terminal results priority and returns no claims.
We corrected this expectation from the contract, without inspecting the implementation.
We retain an overflow assertion for the actual move, and for intended moves in ongoing positions.
We did not disable or skip a failing library regression.

## Local results — 2026-09-10

We tested the library at revision `ed8a509ac891003e6dc30e2807727b20cd661ddb` with the additional tests in the working tree.
We used Xcode 26.6, Swift 6.3.3, and an iPhone 16e simulator with iOS 18.6.
We did not read or modify the library implementation during this work.

| Check | Executed command | Result |
| --- | --- | --- |
| Complete Debug suite | `swift test --enable-code-coverage` | 145 test functions passed |
| Complete Release suite | `swift test -c release -Xswiftc -warnings-as-errors` | 145 test functions passed; no compiler warnings |
| iPhone Release suites | `python3 Tools/Verification/run-ios-tests.py --derived-data /tmp/ChessKit-final-validation-iOS --device-id 6C910ADD-E346-40A3-97DC-D55F8692EEAD --configuration Release` | 14 adversarial, 76 public API, and 55 inherited test functions passed |
| Frozen corpus | `adversarial.py --check-corpus` with the path above | 306 positions and 4,862 candidates reproduced exactly |
| Existing independent baseline | `python3 Tools/Verification/compare.py --binary Tools/Verification/.build/release/ChessKitVerify` | 1,034 positions and 20,982 candidates matched |
| Expanded campaign | `adversarial.py --sparse 12000 --games 96 --plies 400` with the binary and report arguments above | 23,702 positions and 327,848 candidates matched |

We found no new reproducible library defect in this scope.
The expanded campaign included 913 castling candidates, 350 en passant candidates, and 1,620 underpromotion candidates.
It included 824 mating SAN candidates and 6,496 positions in check.
These are observations across the campaign, not counts of unique chess positions or distinct defects.
We report test functions separately from parameter cases and assertions.
We did not add skipped tests, expected failures, or internal-state exceptions.

We still require remote CI evidence on the configured Xcode 16.4 runner before merging.
We do not claim that local execution proves compatibility with every supported compiler.
We have no dedicated Swift or Python lint runner configured in this repository.
We check Swift compilation with warnings as errors, Python syntax, workflow YAML syntax, and patch whitespace.
