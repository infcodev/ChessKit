# Validation results

We keep the latest recorded package checks here.
We distinguish test execution from release acceptance and remote CI.
This documentation consolidation does not constitute a new runtime test run.

## Latest package validation — 10 September 2026

We validated the correction implementation with the added adversarial suite.
We used macOS 26.6, Xcode 26.6, Swift 6.3.3, and an iPhone 16e simulator with iOS 18.6.
We used the external `chess==1.11.2` reference through Python 3.12.
We selected the installed Xcode with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

| Executed check | Recorded result |
| --- | --- |
| `swift test --enable-code-coverage` | 145 test functions passed |
| `swift test -c release -Xswiftc -warnings-as-errors` | 145 test functions passed; no Swift compiler warnings |
| Complete iPhone Release suites | 145 functions passed: 14 adversarial, 76 public API, and 55 inherited |
| Frozen independent corpus | 306 positions and 4,862 candidates reproduced exactly |
| Expanded independent campaign | 23,702 positions and 327,848 candidates matched |
| Existing independent comparison | 1,034 positions and 20,982 candidates matched |

We recorded the full commands and tested revision in [adversarial evidence](ADVERSARIAL-TESTING.md#local-results--2026-09-10).
We found no new reproducible library defect in that campaign.
We count functions separately from parameterized cases, candidate moves, and assertions.
We do not use an empty XCTest wrapper count as the Swift Testing result.

## Earlier implementation evidence

We retain the earlier 131-function results, platform build, coverage, and regression measurements in a [dated record](validation/2026-09-10-implementation.md).
That record predates the extra 14-function adversarial suite.
Its 99.27% line coverage is a historical measurement, not a new coverage claim for this documentation change.
The [perft guide](PERFT.md) records the 33 reference count checks and attribution.

## Remaining acceptance limits

We have not recorded remote Xcode 16.4 results for the final merge candidate here.
We must verify that exact commit in CI before merging.
We have no recorded physical iOS device or Intel Mac test run for this change.
We must verify the consumer integration in StudyChess before release acceptance.
We do not infer exhaustive chess correctness from coverage, perft, or a finite independent comparison.
We track these limits in [known limits](KNOWN-LIMITS.md) and delivery work in the [work plan](WORK-PLAN.md).

## Documentation consolidation — 10 September 2026

We regenerated the API archive with DocC and warnings treated as errors.
We compiled all three current Swift documentation examples against the public module.
We checked local documentation links, generated archive references, and patch whitespace.
We preserved the upstream release notes and separated dated measurements from current status.
We did not modify Swift implementation or test files and did not rerun runtime tests.
The [API documentation guide](API-DOCUMENTATION.md) records the generation command and scope.
