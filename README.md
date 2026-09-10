# ChessKit

We develop ChessKit for apps that work with standard chess positions and moves.
We provide a Swift library for board data, move rules, and chess notation.
We keep the core independent of the host app interface.

## Scope

| Area          | Purpose                                                 |
| ------------- | ------------------------------------------------------- |
| Board data    | Represent pieces, squares, and positions.               |
| Move rules    | Generate legal moves and identify check or checkmate.   |
| Special moves | Handle castling, en passant, and pawn promotion.        |
| Notation      | Convert positions with FEN and moves with SAN.          |
| Game state    | Track repetitions, inspect results, and distinguish draw claims. |

We keep board views, study trees, comments, full PGN import, and engine control in the host app.
We describe version-specific restrictions in [known limits](Documentation/KNOWN-LIMITS.md).

## Requirements

- Swift 6.1 or later.
- Swift Package Manager.

The package name, library product, and module name are `ChessKit`.

## Add the package

For development, we use a reviewed candidate commit.
We do not use an inherited upstream tag to obtain the fork corrections.
The [project status](Documentation/PROJECT-STATUS.md) identifies the release baseline and current integration limits.

1. Open the package dependency settings in your Xcode project.
2. Add this repository URL:

   ```text
   https://github.com/infcodev/ChessKit.git
   ```

3. Select the reviewed commit identified for your integration.
4. Add the `ChessKit` product to the required target.
5. Import the module in your Swift source file:

   ```swift
   import ChessKit
   ```

## Create a board

We use `Board` to store pieces by square.
This example creates a board with two kings and a white pawn.
It reads a piece without a view or a notation parser.

```swift
import ChessKit

var board = Board()
board["e1"] = Piece(kind: .king, color: .white)
board["e8"] = Piece(kind: .king, color: .black)
board["e2"] = Piece(kind: .pawn, color: .white)

let pawn = board["e2"]
let pieces = board.enumeratedPieces()
```

A `Board` stores piece placement.
A `Position` also contains the turn, castling rights, en passant state, and move counters.
A `Game` uses a position to generate and apply moves.

## Use the library in an app

We keep ChessKit types behind the app's integration layer.
The app controls user input, navigation, and data storage.
The library supplies chess data and move operations.

We use `Game.legalMoves` to show available moves.
We apply a move with `try Game.make(move:)`, which checks legality and counter bounds before changing the game.
Direct board edits change piece placement without applying game rules.
We use direct edits for position setup, not for game play.
We validate a completed diagram with `try position.validate()`.
We inspect `Game.status` and `Game.availableDrawClaims` when we need a result or a draw claim.
We use conservative material checks for dead positions; we do not solve arbitrary fortresses.
The [game-state guide](Documentation/GAME-STATE.md) defines editing, repetition, and result contracts.

We read FEN with `try FenSerialization().deserialize(fen:)` and handle `FenSerializationError` in the app.
The [FEN input guide](Documentation/FEN-INPUT.md) describes accepted position input and error handling.
The [moves and SAN guide](Documentation/MOVES-AND-SAN.md) describes move parsing, notation, and game-update errors.

## Documentation

We use the [documentation index](Documentation/README.md) to separate current contracts, delivery work, and historical evidence.

- [Migration](Documentation/MIGRATION.md): consumer changes from upstream 2.0.0.
- [API documentation](Documentation/API-DOCUMENTATION.md): optional generation from the public declarations.

- [Known limits](Documentation/KNOWN-LIMITS.md): current restrictions and verification limits.
- [Project status](Documentation/PROJECT-STATUS.md): baseline, candidate, and release state.
- [Work plan](Documentation/WORK-PLAN.md): development priorities and acceptance criteria.
- [Verification](Documentation/VERIFICATION.md): test commands and independent comparisons.
- [Contributions](CONTRIBUTING.md): defect reports and local checks.
- [Writing guide](Documentation/WRITING-GUIDE.md): language rules and technical terms.
- [Change history](CHANGELOG.md): release notes.

## Contributions

We accept focused changes with tests and clear documentation.
We use regression tests for rule corrections and external consumer tests for public API changes.
The [contribution guide](CONTRIBUTING.md) describes the procedure.

## License and credits

We distribute ChessKit under the [MIT license](LICENSE).
We base this fork on [ChessKit by Alexander Perechnev](https://github.com/aperechnev/ChessKit) and its contributors.
We preserve the original copyright notice and code history.
