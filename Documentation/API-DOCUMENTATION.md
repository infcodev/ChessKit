# API documentation

We generate the public API reference with the installed Swift-DocC plugin.
We store the generated static archive in `docs/`.
We replaced the inherited upstream pages with pages for the corrected API.
We do not use those old pages as current consumer guidance.

## Sources

We extract declarations from the public `ChessKit` module.
We maintain the module overview in [ChessKit.docc/ChessKit.md](ChessKit.docc/ChessKit.md).
We keep contracts and migration instructions in the [documentation index](README.md).
We do not edit generated HTML, JavaScript, or JSON by hand.

## Generate a new archive

1. Select the installed Xcode developer directory.
2. Resolve the package dependencies with Swift Package Manager.
3. Generate the archive in a fresh temporary directory.

```sh
swift package --allow-writing-to-directory /tmp/ChessKit-docs-consolidation generate-documentation Documentation/ChessKit.docc --target ChessKit --output-path /tmp/ChessKit-docs-consolidation --hosting-base-path ChessKit --transform-for-static-hosting --warnings-as-errors
```

4. Check that DocC reports no warnings or errors.
5. Check the module overview and public declarations in the generated JSON.
6. Replace the generated contents of `docs/` with the new archive.
7. Remove obsolete generated files that are absent from the new archive.
8. Check local links and compile the Swift examples in the Markdown guides.
9. Review the generated diff and run `git diff --check`.

We do not overwrite unrelated files or user-authored guides during archive replacement.
We use `ChessKit` as the static hosting base path.
We do not enable or publish GitHub Pages as part of local generation.
We do not claim that an online documentation site is deployed.

## Review the output

We inspect the generated [module reference](../docs/documentation/chesskit/index.html).
We confirm throwing signatures for FEN input, coordinate moves, game updates, and SAN conversion.
We confirm public pages for `PositionKey`, validation errors, results, and draw claims.
We check that the archive contains its referenced pages and static assets.
We keep inherited upstream release notes unchanged in the changelog.

## Generation evidence — 10 September 2026

We generated this archive with Xcode 26.6 and its DocC toolchain.
The command above completed with warnings treated as errors.
We compiled the three Swift examples in the current Markdown guides against the public module.
We did not rerun runtime suites for this documentation-only change.
We retain the earlier package test evidence in [validation results](VALIDATION-RESULTS.md).
