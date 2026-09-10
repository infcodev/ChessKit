//
//  FenSerialization.swift
//  ChessKit
//
//  Created by Alexander Perechnev, 2020.
//  Modified by Alexander Perechnev, 2025.
//  Copyright © 2020-2025 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// FEN positions serialization and deserialization.
public class FenSerialization {

    /// Creates a serializer for use by the calling app.
    public init() {}

    /// Reads a position from six FEN fields separated by whitespace.
    ///
    /// This method checks the format, not whether a legal game can reach the position.
    /// Incomplete boards remain available for position editing.
    ///
    /// - Parameter fen: A FEN record. Castling letters must use `KQkq` order.
    /// - Returns: The position described by the record.
    /// - Throws: `FenSerializationError` for the first invalid field, from left to right.
    public func deserialize(fen: String) throws -> Position {
        let fields = fen.split(whereSeparator: { $0.isWhitespace })

        guard fields.count == 6 else {
            throw FenSerializationError.invalidFieldCount(actual: fields.count)
        }

        let board = try self.board(from: fields[0])
        let turn = try self.turn(from: fields[1])
        let castlings = try self.castlings(from: fields[2])
        let enPassant = try self.enPassant(from: fields[3], turn: turn)
        let halfMoves = try self.moveCount(
            from: fields[4], minimum: 0, error: .invalidHalfmoveClock
        )
        let fullMoves = try self.moveCount(
            from: fields[5], minimum: 1, error: .invalidFullmoveNumber
        )

        let state = Position.State(turn: turn, castlings: castlings, enPasant: enPassant)
        let counter = Position.Counter(halfMoves: halfMoves, fullMoves: fullMoves)

        return Position(board: board, state: state, counter: counter)
    }

    /**
     Serialize position to FEN string.
    
     - Parameters:
        - position: `Position` object that sould be serialized.
    
     - Returns: FEN string describing given position.
     */
    public func serialize(position: Position) -> String {
        let board = self.fen(from: position.board)
        let turn = position.state.turn == .white ? "w" : "b"

        var castling = position.state.castlings
            .map { "\($0)" }
            .sorted()
            .joined()
        if castling == "" {
            castling = "-"
        }

        let enPasant = position.state.enPasant != nil ? "\(position.state.enPasant!)" : "-"

        let halfmove = "\(position.counter.halfMoves)"
        let fullmove = "\(position.counter.fullMoves)"

        return [board, turn, castling, enPasant, halfmove, fullmove]
            .joined(separator: " ")
    }

    // MARK: Serialization

    private func fen(from board: Board) -> String {
        var lines: [String] = []

        for rank in (0...7).reversed() {
            var empty = 0
            var line = ""

            for file in 0...7 {
                let square = Square(file: file, rank: rank)

                if let piece = board[square] {
                    if empty > 0 {
                        line += "\(empty)"
                        empty = 0
                    }
                    line += "\(piece)"
                } else {
                    empty += 1
                }
            }

            if empty > 0 {
                line += "\(empty)"
                empty = 0
            }

            lines.append(line)
        }

        return lines.joined(separator: "/")
    }

    // MARK: Deserialization

    private func board(from sequence: Substring) throws -> Board {
        let ranks = sequence.split(separator: "/", omittingEmptySubsequences: false)

        guard ranks.count == 8 else {
            throw FenSerializationError.invalidPiecePlacement
        }

        var board = Board()

        for (offset, sequence) in ranks.enumerated() {
            try self.readRank(sequence, rank: 7 - offset, into: &board)
        }

        return board
    }

    private func readRank(_ sequence: Substring, rank: Int, into board: inout Board) throws {
        var file = 0
        var previousWasDigit = false

        for symbol in sequence {
            guard file < 8 else {
                throw FenSerializationError.invalidPiecePlacement
            }

            if let ascii = symbol.asciiValue, (49...56).contains(ascii) {
                guard !previousWasDigit else {
                    throw FenSerializationError.invalidPiecePlacement
                }

                file += Int(ascii - 48)
                previousWasDigit = true
                continue
            }

            guard symbol.asciiValue != nil, let piece = Piece(character: symbol) else {
                throw FenSerializationError.invalidPiecePlacement
            }

            board[Square(file: file, rank: rank)] = piece
            file += 1
            previousWasDigit = false
        }

        guard file == 8 else {
            throw FenSerializationError.invalidPiecePlacement
        }
    }

    private func turn(from sequence: Substring) throws -> PieceColor {
        switch sequence {
        case "w":
            return .white
        case "b":
            return .black
        default:
            throw FenSerializationError.invalidActiveColor
        }
    }

    private func castlings(from sequence: Substring) throws -> [Piece] {
        if sequence == "-" {
            return []
        }

        let order: [Character] = ["K", "Q", "k", "q"]
        var previousIndex = -1
        var rights: [Piece] = []

        for symbol in sequence {
            guard symbol.asciiValue != nil,
                let index = order.firstIndex(of: symbol), index > previousIndex
            else {
                throw FenSerializationError.invalidCastlingRights
            }

            guard let piece = Piece(character: symbol) else {
                throw FenSerializationError.invalidCastlingRights
            }

            rights.append(piece)
            previousIndex = index
        }

        return rights
    }

    private func enPassant(from sequence: Substring, turn: PieceColor) throws -> Square? {
        if sequence == "-" {
            return nil
        }

        guard sequence.count == 2, let file = sequence.first, "abcdefgh".contains(file) else {
            throw FenSerializationError.invalidEnPassantTarget
        }

        let expectedRank: Character = turn == .white ? "6" : "3"

        guard sequence.last == expectedRank else {
            throw FenSerializationError.invalidEnPassantTarget
        }

        return Square(coordinate: String(sequence))
    }

    private func moveCount(
        from sequence: Substring, minimum: Int, error: FenSerializationError
    ) throws -> Int {
        let containsOnlyDigits = sequence.utf8.allSatisfy { (48...57).contains($0) }

        guard !sequence.isEmpty, containsOnlyDigits else {
            throw error
        }

        guard let count = Int(sequence), count >= minimum else {
            throw error
        }

        return count
    }

}
