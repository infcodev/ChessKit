# Project status

We completed the planned rule and public API corrections.
We also completed local verification, including the adversarial black-box suite.
We have no remaining confirmed defect from that plan.
We have not completed release acceptance or published a fork release.

## Baseline and candidate

We started from upstream 2.0.0 at commit `bee00f535ae6c6182cc3d9c9a5bd5cfb5cbc5d83`.
We use `main` as the default branch of [our fork](https://github.com/infcodev/ChessKit).
We prepare these corrections on `chesskit-corrections` before merging them into `main`.
We do not assume that `main` contains an unmerged candidate.
We use a reviewed commit for development integration.
The inherited version tags refer to upstream releases and do not include these corrections.

## Current implementation

We provide recoverable FEN, coordinate-move, and SAN errors.
We validate legal moves and reject counter overflow before changing a game.
We support position identity, repetition counts, static position validation, results, and draw claims.
We keep incomplete position editing separate from legal play.
We describe incompatible changes in the [migration guide](MIGRATION.md).

We use conservative dead-position checks.
We retain the remaining restrictions in [known limits](KNOWN-LIMITS.md).
We keep corrected defects in [correction history](HISTORY.md), not in the open work list.

## Verification and documentation

We passed 145 test functions locally in macOS Debug, macOS Release, and the iPhone simulator.
We matched 23,702 positions and 327,848 candidate moves in the expanded independent campaign.
These finite checks do not prove correctness for every chess position.
The [validation record](VALIDATION-RESULTS.md) identifies the commands, environment, and limits.

We maintain user guides and the DocC source catalog in `Documentation/`.
We exclude the generated API website from version control.
The [documentation index](README.md) identifies the purpose of each document.
The [API generation guide](API-DOCUMENTATION.md) describes how we rebuild the reference.

## Remaining release work

We must verify the candidate in a host app and review the required integration changes.
We must check the remote CI jobs on the exact commit proposed for merge.
The recorded local results do not establish a passed Xcode 16.4 remote run.
We must then select the major version, finalize release notes, and publish the tested revision.
We track these steps in the [work plan](WORK-PLAN.md).
