# Work plan

We completed the planned correction phase.
We keep its defect reports and regression evidence in [correction history](HISTORY.md).
We use this document for remaining delivery work.

## Completed work

| Area | Delivered result |
| --- | --- |
| Public API | Public serializer construction and recoverable input errors |
| Rules and SAN | Corrected en passant, castling, move validation, and disambiguation |
| Position state | Position keys, static validation, safe square access, and editing boundaries |
| Results | Current and intended draw claims, automatic results, and explicit dead-position limits |
| Verification | Public consumer tests, regressions, perft, long lines, and independent comparisons |
| Adversarial tests | Frozen external results, hostile input, rejected moves, and state-isolation checks |
| Documentation | Current guides, migration, API reference, and separate historical evidence |

We recorded the executed checks in [validation results](VALIDATION-RESULTS.md).
We do not repeat old implementation tasks as pending work.

## Release acceptance

1. Integrate a reviewed candidate commit into a host app.
2. Apply the public API changes in the app's ChessKit adapter.
3. Verify study loading, legal moves, promotions, notation, and error recovery in the app.
4. Check every required remote CI job on the final commit.
5. Review the [known limits](KNOWN-LIMITS.md) and document the supported platforms.
6. Merge the accepted candidate into `main`.
7. Select a major version and finalize the changelog and installation example.
8. Publish the tested commit with its version tag and release notes.

We require a major version because public method signatures and position-history contracts changed.
We have not assigned or published that version in this documentation update.
We do not treat an inherited upstream tag as our corrected release.

## Separate future scope

We do not require full PGN support, chess variants, exhaustive dead-position proofs, or app UI components for this correction release.
We assess those additions separately when the host app needs them.
