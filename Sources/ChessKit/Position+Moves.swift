//
//  Position+Moves.swift
//  ChessKit
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

extension Position {
    /// Applies board and move-right effects for a move already checked by the caller.
    /// Counters remain unchanged so notation can inspect the result without advancing a game.
    func applyingLegalMove(_ move: Move) -> Position {
        var next = self
        let enPassant = next.updateEnPassant(for: move)

        next.updateCastlings(for: move)
        next.perform(move: move)
        next.state.enPasant = enPassant
        next.state.turn = next.state.turn.negotiated

        return next
    }

    private mutating func perform(move: Move) {
        let isCastling =
            self.board.bitboards.king & move.from.bitboardMask != Int64.zero
            && abs(move.from.file - move.to.file) > 1

        let isEnPassant =
            self.board.bitboards.pawn & move.from.bitboardMask != Int64.zero
            && move.to == self.state.enPasant

        let isPawnPromotion = move.promotion != nil

        if isCastling {
            self.performCastling(move: move)
        } else if isEnPassant {
            self.performEnPassant(move: move)
        } else if isPawnPromotion {
            self.performPawnPromotion(move: move)
        } else {
            self.performSimple(move: move)
        }
    }

    private mutating func performSimple(move: Move) {
        self.board[move.to] = self.board[move.from]
        self.board[move.from] = nil
    }

    private mutating func performCastling(move: Move) {
        self.performSimple(move: move)

        let rank = self.state.turn == .white ? 0 : 7
        let rookFromFile = move.to.file == 2 ? 0 : 7
        let rookToFile = move.to.file == 2 ? 3 : 5
        let rookMove = Move(
            from: Square(file: rookFromFile, rank: rank),
            to: Square(file: rookToFile, rank: rank)
        )
        self.performSimple(move: rookMove)
    }

    private mutating func performEnPassant(move: Move) {
        self.performSimple(move: move)

        guard let enPassant = self.state.enPasant else {
            return
        }

        let rank = self.state.turn == .white ? 4 : 3
        self.board[Square(file: enPassant.file, rank: rank)] = nil
    }

    private mutating func performPawnPromotion(move: Move) {
        self.performSimple(move: move)

        guard let kind = move.promotion else {
            return
        }
        self.board[move.to] = Piece(kind: kind, color: self.state.turn)
    }

    private func updateEnPassant(for move: Move) -> Square? {
        if self.board.bitboards.pawn & move.from.bitboardMask == Int64.zero {
            return nil
        }
        guard abs(move.from.rank - move.to.rank) == 2 else {
            return nil
        }

        let rank = self.state.turn == .white ? 2 : 5
        return Square(file: move.from.file, rank: rank)
    }

    private mutating func updateCastlings(for move: Move) {
        guard let piece = self.board[move.from] else {
            return
        }

        if piece.kind == .king {
            self.state.castlings = self.state.castlings
                .filter { $0.color != self.state.turn }
        }

        self.state.castlings = self.state.castlings.filter {
            // filter should return true if we should not exclude
            // filter should return false if we should exclude current castling
            // $0 is one of KQkq pieces (white K, white Q, black k, black q)
            // castlingColorAndSideToExclude returns piece if move from/to is at some of 4 corners
            // if castlingColorAndSideToExclude returns piece
            // for either "from" or for "to" square - we have to exclude casling
            var excludeBecauseOfFrom = false
            var excludeBecauseOfTo = false
            if let colorAndSideToExclude = castlingColorAndSideToExclude(square: move.from) {
                excludeBecauseOfFrom =
                    $0.color == colorAndSideToExclude.color && $0.kind == colorAndSideToExclude.kind
            }
            if let colorAndSideToExclude = castlingColorAndSideToExclude(square: move.to) {
                excludeBecauseOfTo =
                    $0.color == colorAndSideToExclude.color && $0.kind == colorAndSideToExclude.kind
            }
            return !(excludeBecauseOfFrom || excludeBecauseOfTo)
        }
    }

    private func castlingColorAndSideToExclude(square: Square) -> Piece? {
        // is A1?
        if square.file == 0 && square.rank == 0 {
            return Piece(kind: .queen, color: .white)
        }
        // is H1?
        if square.file == 7 && square.rank == 0 {
            return Piece(kind: .king, color: .white)
        }
        // is A8?
        if square.file == 0 && square.rank == 7 {
            return Piece(kind: .queen, color: .black)
        }
        // is H8?
        if square.file == 7 && square.rank == 7 {
            return Piece(kind: .king, color: .black)
        }
        return nil
    }

}
