import Foundation

/// The fields of one SAN token. This parser does not choose a legal move.
struct ParsedSanMove {
    let kind: PieceKind
    let fromFile: Int?
    let fromRank: Int?
    let destination: Square
    let isCapture: Bool
    let isCastling: Bool
    let promotion: PieceKind?
    let checkSuffix: Character?

    init(san: String, turn: PieceColor) throws {
        let trimmed = san.trimmingCharacters(in: .whitespacesAndNewlines)

        guard (2...9).contains(trimmed.utf8.count), trimmed.utf8.allSatisfy({ $0 < 128 }) else {
            throw SanSerializationError.invalidNotation
        }

        var token = Array(trimmed)
        if token.last == "+" || token.last == "#" {
            self.checkSuffix = token.removeLast()
        } else {
            self.checkSuffix = nil
        }

        let castling = String(token)
        if ["O-O", "O-O-O", "0-0", "0-0-0"].contains(castling) {
            let rank = turn == .white ? 0 : 7
            self.kind = .king
            self.fromFile = 4
            self.fromRank = rank
            self.destination = Square(file: castling.count == 3 ? 6 : 2, rank: rank)
            self.isCapture = false
            self.isCastling = true
            self.promotion = nil
            return
        }

        self.isCastling = false
        if token.count >= 2, token[token.count - 2] == "=" {
            guard let symbol = token.last, "QRBN".contains(symbol),
                let piece = Piece(character: symbol)
            else {
                throw SanSerializationError.invalidNotation
            }

            self.promotion = piece.kind
            token.removeLast(2)
        } else {
            self.promotion = nil
        }

        guard token.count >= 2 else {
            throw SanSerializationError.invalidNotation
        }

        let fileSymbol = token[token.count - 2]
        let rankSymbol = token[token.count - 1]

        guard let file = Board.fileCoordinates.firstIndex(of: fileSymbol),
            let rank = Board.rankCoordinates.firstIndex(of: rankSymbol)
        else {
            throw SanSerializationError.invalidNotation
        }

        self.destination = Square(file: file, rank: rank)
        token.removeLast(2)
        self.isCapture = token.last == "x"
        if self.isCapture {
            token.removeLast()
        }

        if let symbol = token.first, "KQRBN".contains(symbol),
            let piece = Piece(character: symbol)
        {
            guard self.promotion == nil else {
                throw SanSerializationError.invalidNotation
            }

            self.kind = piece.kind
            token.removeFirst()
            let origin = try Self.origin(from: token)
            self.fromFile = origin.file
            self.fromRank = origin.rank
            return
        }

        self.kind = .pawn
        self.fromRank = nil
        if self.isCapture {
            guard token.count == 1, let symbol = token.first,
                let file = Board.fileCoordinates.firstIndex(of: symbol)
            else {
                throw SanSerializationError.invalidNotation
            }

            self.fromFile = file
        } else {
            guard token.isEmpty else {
                throw SanSerializationError.invalidNotation
            }

            self.fromFile = nil
        }
    }

    private static func origin(from symbols: [Character]) throws -> (file: Int?, rank: Int?) {
        if symbols.isEmpty {
            return (nil, nil)
        }

        if symbols.count == 1 {
            if let file = Board.fileCoordinates.firstIndex(of: symbols[0]) {
                return (file, nil)
            }
            if let rank = Board.rankCoordinates.firstIndex(of: symbols[0]) {
                return (nil, rank)
            }
        }

        if symbols.count == 2,
            let file = Board.fileCoordinates.firstIndex(of: symbols[0]),
            let rank = Board.rankCoordinates.firstIndex(of: symbols[1])
        {
            return (file, rank)
        }

        throw SanSerializationError.invalidNotation
    }
}
