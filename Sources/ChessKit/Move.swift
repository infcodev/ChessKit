//
//  Move.swift
//  ChessKit
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// Represents move on board.
public struct Move: CustomStringConvertible, Hashable {

    /// Square where piece goes from.
    public let from: Square

    /// Square where piece goes to.
    public let to: Square

    /// Indicates if move promotes pawn into piece.
    public let promotion: PieceKind?

    // MARK: Initialization

    /**
     Initialize move with start and end squares.
    
     - Parameters:
        - from: Square where piece goes from.
        - to: Square where piece goes to.
        - promotion: A piece kind which should be set instead of pawn in case of promotion.
     */
    public init(from: Square, to: Square, promotion: PieceKind? = nil) {
        self.from = from
        self.to = to
        self.promotion = promotion
    }

    /// Reads four ASCII coordinate characters and an optional promotion letter.
    ///
    /// Promotion letters are `q`, `r`, `b`, or `n`, in either case.
    /// This initializer checks notation. `Game.make` checks legality in a position.
    /// - Throws: `MoveParsingError` when the coordinate input is invalid.
    public init(string: String) throws {
        let bytes = Array(string.utf8)

        guard bytes.count == 4 || bytes.count == 5 else {
            throw MoveParsingError.invalidLength
        }

        guard (97...104).contains(bytes[0]), (49...56).contains(bytes[1]) else {
            throw MoveParsingError.invalidSourceSquare
        }

        guard (97...104).contains(bytes[2]), (49...56).contains(bytes[3]) else {
            throw MoveParsingError.invalidDestinationSquare
        }

        let from = Square(file: Int(bytes[0] - 97), rank: Int(bytes[1] - 49))
        let to = Square(file: Int(bytes[2] - 97), rank: Int(bytes[3] - 49))

        guard from != to else {
            throw MoveParsingError.identicalSquares
        }

        var promotion: PieceKind?
        if bytes.count == 5 {
            switch bytes[4] {
            case 81, 113:
                promotion = .queen
            case 82, 114:
                promotion = .rook
            case 66, 98:
                promotion = .bishop
            case 78, 110:
                promotion = .knight
            default:
                throw MoveParsingError.invalidPromotion
            }
        }

        self.init(from: from, to: to, promotion: promotion)
    }

    // MARK: CustomStringConvertible

    /// Converts move into human readable string format.
    public var description: String {
        var result = "\(self.from)\(self.to)"

        if let promotion = self.promotion {
            result += "\(promotion)"
        }

        return result
    }

}
