# Known limits

We list current restrictions here.
We keep resolved defects and their evidence in [correction history](HISTORY.md).
We have no remaining confirmed defect from the completed correction plan.
That statement does not prove that the library has no undiscovered defects.

## Position editing

We accept incomplete FEN diagrams for editing.
Successful FEN parsing does not establish that a position is valid for play.
We validate a completed diagram with `try position.validate()`.
We check static invariants but do not prove reachability from a legal game.
We do not reconstruct previous moves or repetitions from FEN.

## Dead positions and results

We prove dead positions only for the material cases listed in [game state](GAME-STATE.md#dead-position-scope).
We do not solve arbitrary blocked positions, fortresses, or forced continuations.
We return `.notEstablished` outside the supported proofs.
This value does not prove that a mating sequence exists.

We permit legal analysis moves after an automatic draw.
We calculate the result for the current position and do not retain an earlier adjudicated result.
The host app must retain that result for a live game.
We do not model clocks, resignation, draw agreements, or acceptance of a draw claim.

## Input scope

We parse FEN positions, coordinate moves, and individual SAN tokens.
We do not parse full PGN records, comments, annotations, or variations.
We keep those operations in the host app.
We document import allowances and error precedence in the [FEN](FEN-INPUT.md) and [SAN](MOVES-AND-SAN.md) guides.

## Product scope

We do not provide a board view, a study tree, storage, or a chess engine.
We have not established Chess960 or other variant support.
We do not add those features as prerequisites for this correction release.

## Verification scope

We use finite regression, perft, contract, and independent comparison tests.
We do not claim a proof of complete chess correctness.
The independent reference also has limits and can share an error with another implementation.
We combine it with explicit contract and state-invariant checks.

We recorded local macOS and iPhone simulator results in [validation results](VALIDATION-RESULTS.md).
We have no recorded physical iOS device or Intel Mac test run for this change.
We still require remote CI evidence for the final commit, including the configured Xcode 16.4 runner.
We have no dedicated Swift or Python lint runner configured.
We use compiler warnings, syntax checks, and whitespace checks within the documented verification scope.
