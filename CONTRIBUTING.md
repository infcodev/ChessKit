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

## Review requirements

We check behavior, public contracts, test evidence, and documentation.
We use the [writing guide](Documentation/WRITING-GUIDE.md) for new prose.
We preserve API identifiers, attribution, and license notices.
We do not change historical release notes to describe new behavior.

We can propose general corrections to the upstream project after we validate them.
We do not promise an upstream merge or release date.
