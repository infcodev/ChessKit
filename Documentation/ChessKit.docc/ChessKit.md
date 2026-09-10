# ``ChessKit``

We provide standard chess position data, legal moves, and notation for Swift apps.

## Overview

We keep chess operations independent of app views and storage.
We parse FEN, read and write individual SAN tokens, and apply validated moves.
We use recoverable errors for invalid input and failed game updates.

We validate a completed diagram before play.
We use ``PositionKey`` for repetition identity and ``GameStatus`` for supported automatic results.
We keep draw claims separate from automatic results.
We permit legal analysis after an automatic draw; the host app retains any adjudicated result.
We do not prove all dead positions or provide PGN trees, UI, or a chess engine.

We document consumer changes and scope in the [repository guides](https://github.com/infcodev/ChessKit/tree/chesskit-corrections/Documentation).
We have not published a fork release for this correction candidate.

## Topics

### Position data

- ``Board``
- ``Square``
- ``Piece``
- ``Position``
- ``PositionKey``

### Moves and notation

- ``Game``
- ``Move``
- ``StandardRules``
- ``FenSerialization``
- ``SanSerialization``

### Errors and results

- ``FenSerializationError``
- ``MoveParsingError``
- ``SanSerializationError``
- ``GameMoveError``
- ``PositionValidationError``
- ``GameStatus``
- ``DrawClaim``
- ``DeadPositionAssessment``
