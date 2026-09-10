//
//  KingMoving.swift
//  ChessKit
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

class KingMoving: ShortRangeMoving {

    init() {
        super.init(translations: MovingTranslations().crossDiagonal)
    }

    override func coveredSquares(from square: Square, in position: Position) -> [Square] {
        let normalDestinations = super.coveredSquares(from: square, in: position)
        let castlingDestinations = self.castlingSquares(from: square, in: position)
        let destinations = normalDestinations + castlingDestinations

        return self.filterOppositeKingSquares(destinations: destinations, from: square, in: position)
    }

    private func filterOppositeKingSquares(
        destinations: [Square], from origin: Square, in position: Position
    ) -> [Square] {
        let mask =
            position.board.bitboards.bitboard(for: position.state.turn.negotiated)
            & position.board.bitboards.king

        guard mask != Int64.zero else {
            return destinations
        }

        let oppositeKing = Square(bitboardMask: mask)
        let startsUnderKingAttack =
            abs(origin.file - oppositeKing.file) <= 1
            && abs(origin.rank - oppositeKing.rank) <= 1

        return destinations.filter { destination in
            let entersKingAttack =
                abs(destination.file - oppositeKing.file) <= 1
                && abs(destination.rank - oppositeKing.rank) <= 1
            guard !entersKingAttack else {
                return false
            }

            let isCastling = abs(destination.file - origin.file) > 1
            return !isCastling || !startsUnderKingAttack
        }
    }

    private func castlingSquares(from square: Square, in position: Position) -> [Square] {
        let color = position.state.turn
        let rank = color == .white ? 0 : 7
        guard square == Square(file: 4, rank: rank) else {
            return []
        }

        let castlings = position.state.castlings.filter { $0.color == color }
        let shouldBeEmpty: [PieceKind: [Int]] = [
            .king: [5, 6],
            .queen: [1, 2, 3],
        ]
        var squares = [Square]()

        for castling in castlings {
            guard let emptyFiles = shouldBeEmpty[castling.kind] else {
                continue
            }

            let rookFile = castling.kind == .king ? 7 : 0
            let rookSquare = Square(file: rookFile, rank: rank)
            guard position.board[rookSquare] == Piece(kind: .rook, color: color) else {
                continue
            }

            let isPathClear = emptyFiles.allSatisfy { file in
                position.board[Square(file: file, rank: rank)] == nil
            }
            guard isPathClear else {
                continue
            }

            let destinationFile = castling.kind == .king ? 6 : 2
            squares.append(Square(file: destinationFile, rank: rank))
        }

        return squares
    }

}
