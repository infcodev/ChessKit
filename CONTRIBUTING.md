# Contributions

We accept changes with a clear purpose and supporting evidence.
We use `main` as the base branch.
We keep rule corrections separate from API changes and formatting changes.

## Report a defect

1. Open an issue in [our repository](https://github.com/infcodev/ChessKit/issues).
2. Include the package revision and Swift version.
3. Include the initial FEN and the move sequence.
4. Describe the expected result.
5. Describe the actual result.
6. Include a small reproduction when possible.

We need enough information to reproduce the defect.
We distinguish an executed failure from a source review finding.

## Prepare a change

1. Create a branch from `main`.
2. Add a regression test for the reported defect.
3. Confirm that the test detects the defect before the correction.
4. Apply the correction.
5. Run the tests:

   ```sh
   swift test
   ```

6. Check the patch for whitespace errors:

   ```sh
   git diff --check
   ```

7. Update the relevant documentation.
8. Record the test commands and results in the pull request.

For a documentation-only change, we require a documentation review and a whitespace check.
We do not require a new rule test for a text change.
For public API changes, we require a consumer test without `@testable`.

## Continuous integration

We run CI for pushes to `main` and pull requests to `main`.
We also support manual runs after the workflow is available on `main`.
We open pull requests against `main` to check changes on a feature branch.
We check all CI jobs before we merge a pull request.
We use the `macos-15` runner with Xcode 16.4.
We run debug tests with coverage, optimized tests, and the independent comparison.
We build the package for the iOS Simulator and execute its test targets.
We keep the coverage report as a GitHub artifact for 14 days.
We do not upload coverage to Codecov or require a coverage token.

The generic simulator build checks compilation for both architectures.
A separate step runs the tests on an available iPhone simulator.
The [verification guide](Documentation/VERIFICATION.md) lists the local equivalents.
We run `ChessKitPublicAPITests` with the main test command.
This separate target uses `import ChessKit` without `@testable`.
We extend these consumer tests when we change the public API.
We also run `ChessKitAdversarialTests` without internal access.
We verify its frozen corpus and run its independent campaign in CI.

## Review evidence

We check behavior, public contracts, test evidence, and documentation.
We use the [writing guide](Documentation/WRITING-GUIDE.md) for new prose.
We preserve API identifiers, attribution, and license notices.
We do not change historical release notes to describe new behavior.

We can propose general corrections to the upstream project after we validate them.
We do not promise an upstream merge or release date.

## Documentation changes

We use the [documentation index](Documentation/README.md) to select the correct destination.
We keep current contracts separate from defect history and release work.
We follow the [API generation procedure](Documentation/API-DOCUMENTATION.md) when public declarations or API articles change.
We validate local links and Swift examples before confirming a documentation update.
We do not rewrite historical test results as newly executed evidence.
