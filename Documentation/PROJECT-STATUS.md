# Project status

We use this document for version-specific information.
The [README](../README.md) describes the purpose and use of the library.

## Baseline

We started from upstream `master` at commit `bee00f535ae6c6182cc3d9c9a5bd5cfb5cbc5d83`.
This commit is upstream version `2.0.0`.
We use `main` as the default branch of [our fork](https://github.com/infcodev/ChessKit).

We changed the project documentation only.
We did not change the Swift source code or the existing tests.
We did not publish a new package release.
The inherited tags identify upstream releases, not our corrections.

## Integration status

The public FEN and SAN serializers have no public initializers.
An external app cannot construct these serializers through the documented upstream API.
The board example in our README uses public board and piece initializers instead.

We do not recommend this revision for production use.
The [known limits](KNOWN-LIMITS.md) record the current findings.
The [work plan](WORK-PLAN.md) defines the proposed corrections and tests.

## Existing tests

The existing tests use `@testable import ChessKit`.
These tests can access internal declarations.
A successful run does not establish that the public API works from an external app.
We will add an external consumer test before release.

## Generated API pages

We retain the upstream pages in `docs/` as historical reference material.
Those pages can contain examples that do not compile from an external app.
We did not regenerate those pages for this documentation update.
We will check the examples and generate new pages after the public API changes.

## CI

We retain the upstream CI workflow without changes.
It refers to upstream branches and external coverage configuration.
We will review that workflow before we enable it for this fork.

## Release publication

We will publish a release after the agreed checks pass.
We will record the supported toolchains, platforms, and migration steps with that release.
The [change history](../CHANGELOG.md) will identify the changes in each version.
