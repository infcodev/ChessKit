# Optional API documentation

We maintain the public contracts and migration instructions in the [documentation index](README.md).
We keep the DocC source catalog in [ChessKit.docc/ChessKit.md](ChessKit.docc/ChessKit.md).
These source documents remain in version control.
We do not commit the generated API website or its HTML, JavaScript, CSS, and search indexes.
We ignore `docs/` if a local workflow uses that output directory.

## Generate a local reference when needed

We use the installed Swift-DocC plugin to extract public declarations.
We generate its output outside the repository.

1. Select the installed Xcode developer directory.
2. Resolve the package dependencies with Swift Package Manager.
3. Generate the archive in a fresh temporary directory.

```sh
swift package --allow-writing-to-directory /tmp/ChessKit-docs-consolidation generate-documentation Documentation/ChessKit.docc --target ChessKit --output-path /tmp/ChessKit-docs-consolidation --hosting-base-path ChessKit --transform-for-static-hosting --warnings-as-errors
```

4. Check that DocC reports no warnings or errors.
5. Check the overview and public declarations in the generated archive.
6. Keep the archive outside version control.

We use `ChessKit` as the static hosting base path for this optional output.
We do not enable or publish GitHub Pages as part of local generation.
We do not edit generated HTML, JavaScript, or JSON by hand.

## Review the output

We inspect `documentation/chesskit/index.html` inside the generated archive.
We confirm throwing signatures for FEN input, coordinate moves, game updates, and SAN conversion.
We confirm public pages for position identity, validation errors, results, and draw claims.
We check that the archive contains its referenced pages and assets.
We compile changed Swift examples in the Markdown guides before confirming their documentation update.

## Earlier generation evidence — 10 September 2026

We generated the reference with Xcode 26.6 and warnings treated as errors during documentation consolidation.
We compiled the three Swift examples in the Markdown guides against the public module.
We later removed the generated website from the repository and retained its source catalog.
We do not require the generated website to compile or use the library.
We retain the package test evidence in [validation results](VALIDATION-RESULTS.md).
