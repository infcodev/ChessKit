//
//  SanSerialization.swift
//  ChessKit
//
//  Created by Alexander Perechnev, 2021.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2021-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// SAN moves serialization and deserialization.
public class SanSerialization {
    /// Creates a serializer for use by the calling app.
    public init() {}

    /// Writes canonical SAN for a legal move without modifying the game.
    /// - Throws: `SanSerializationError.illegalMove` for an invalid or illegal move.
    public func san(for move: Move, in game: Game) throws -> String {
        guard game.isLegal(move: move), let piece = game.position.board[move.from] else {
            throw SanSerializationError.illegalMove
        }

        var notation: String
        if Self.isCastling(move, kind: piece.kind) {
            notation = move.to.file == 6 ? "O-O" : "O-O-O"
        } else {
            notation = self.moveText(for: move, piece: piece, in: game)
        }

        return notation + self.checkSuffix(after: move, in: game)
    }

    private func moveText(for move: Move, piece: Piece, in game: Game) -> String {
        let isCapture = Self.isCapture(move, kind: piece.kind, in: game.position)
        var notation = ""

        if piece.kind == .pawn {
            if isCapture {
                notation += String(Board.fileCoordinates[move.from.file])
            }
        } else {
            notation += piece.kind.description.uppercased()
            notation += self.disambiguation(for: move, kind: piece.kind, in: game)
        }

        if isCapture {
            notation += "x"
        }
        notation += move.to.coordinate

        if let promotion = move.promotion {
            notation += "=" + promotion.description.uppercased()
        }

        return notation
    }

    private func disambiguation(for move: Move, kind: PieceKind, in game: Game) -> String {
        let alternatives = game.legalMoves.filter {
            $0.to == move.to && $0.from != move.from && game.position.board[$0.from]?.kind == kind
        }

        guard !alternatives.isEmpty else {
            return ""
        }

        let sharesFile = alternatives.contains { $0.from.file == move.from.file }
        let sharesRank = alternatives.contains { $0.from.rank == move.from.rank }

        if !sharesFile {
            return String(Board.fileCoordinates[move.from.file])
        }
        if !sharesRank {
            return String(Board.rankCoordinates[move.from.rank])
        }
        return move.from.coordinate
    }

    /// Reads one SAN move and requires a unique legal match.
    ///
    /// Surrounding whitespace, zero-based castling spelling, and omitted check suffixes are accepted.
    /// A supplied check suffix must be correct. Annotations belong to the host app.
    /// - Throws: `SanSerializationError` for invalid, illegal, ambiguous, or incorrect-check input.
    public func move(for san: String, in game: Game) throws -> Move {
        let parsed = try ParsedSanMove(san: san, turn: game.position.state.turn)
        let candidates = game.legalMoves.filter { move in
            guard game.position.board[move.from]?.kind == parsed.kind,
                move.to == parsed.destination, move.promotion == parsed.promotion
            else {
                return false
            }

            if let file = parsed.fromFile, move.from.file != file {
                return false
            }
            if let rank = parsed.fromRank, move.from.rank != rank {
                return false
            }

            return Self.isCastling(move, kind: parsed.kind) == parsed.isCastling
                && Self.isCapture(move, kind: parsed.kind, in: game.position) == parsed.isCapture
        }

        guard let move = candidates.first else {
            throw SanSerializationError.illegalMove
        }
        guard candidates.count == 1 else {
            throw SanSerializationError.ambiguousMove
        }

        if let suffix = parsed.checkSuffix,
            String(suffix) != self.checkSuffix(after: move, in: game)
        {
            throw SanSerializationError.invalidCheckSuffix
        }

        return move
    }

    private static func isCastling(_ move: Move, kind: PieceKind) -> Bool {
        kind == .king && abs(move.to.file - move.from.file) == 2
    }

    private static func isCapture(_ move: Move, kind: PieceKind, in position: Position) -> Bool {
        position.board[move.to] != nil || (kind == .pawn && move.to == position.state.enPasant)
    }

    private func checkSuffix(after move: Move, in game: Game) -> String {
        let next = Game(position: game.position.applyingLegalMove(move))

        if next.isMate {
            return "#"
        }
        if next.isCheck {
            return "+"
        }
        return ""
    }
}
