//
//  Square.swift
//  ChessKit
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// A board square. Invalid input produces a safe invalid square with coordinate `--`.
public struct Square: Hashable, CustomStringConvertible {
    private(set) var index: Int
    let bitboardMask: Bitboard

    /// Whether this value names one of the 64 squares.
    public var isValid: Bool { index >= 0 }
    /// Zero-based file, or -1 for an invalid square.
    public var file: Int { isValid ? index / 8 : -1 }
    /// Zero-based rank, or -1 for an invalid square.
    public var rank: Int { isValid ? index % 8 : -1 }

    public var coordinate: String {
        guard isValid else {
            return "--"
        }
        return "\(Board.fileCoordinates[file])\(Board.rankCoordinates[rank])"
    }

    public var description: String { coordinate }

    init(bitboardMask: Bitboard) {
        guard bitboardMask.nonzeroBitCount == 1 else {
            self.init(index: -1)
            return
        }
        self.init(index: bitboardMask.trailingZeroBitCount)
    }

    public init(index: Int) {
        guard (0..<64).contains(index) else {
            self.index = -1
            self.bitboardMask = 0
            return
        }
        self.index = index
        self.bitboardMask = 1 << index
    }

    public init(file: Int, rank: Int) {
        guard (0..<8).contains(file), (0..<8).contains(rank) else {
            self.init(index: -1)
            return
        }
        self.init(index: file * 8 + rank)
    }

    /// Accepts exactly two ASCII characters, from a1 through h8.
    public init(coordinate: String) {
        let bytes = Array(coordinate.utf8.prefix(3))
        guard bytes.count == 2, (97...104).contains(bytes[0]), (49...56).contains(bytes[1]) else {
            self.init(index: -1)
            return
        }
        self.init(file: Int(bytes[0] - 97), rank: Int(bytes[1] - 49))
    }

    /// Returns an invalid square when the offset leaves the board, including extreme integers.
    public func translate(file: Int, rank: Int) -> Square {
        guard isValid, (-7...7).contains(file), (-7...7).contains(rank) else {
            return Square(index: -1)
        }
        return Square(file: self.file + file, rank: self.rank + rank)
    }
}
