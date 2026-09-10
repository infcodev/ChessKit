//
//  Game.swift
//  ChessKit
//
//  Created by Alexander Perechnev, 2020.
//  Copyright © 2020 Päike Mikrosüsteemid OÜ. All rights reserved.
//

/// Chess game.
public class Game {

    private let rules: Rules

    /// Number of occurrences of each position in game.
    public private(set) var positionsCounter: [Board: Int]
    /// List of moves made before current game position.
    public private(set) var movesHistory: [Move]

    /// Current game position.
    public var position: Position
    /// Indicates whether it's check in current position.
    public var isCheck: Bool {
        return self.rules.isCheck(in: self.position)
    }
    /// Indicates whether it's mate in current position.
    public var isMate: Bool {
        return self.rules.isMate(in: self.position)
    }

    // MARK: Initialization

    init(position: Position, moves: [Move], positionsCounter: [Board: Int]) {
        self.position = position
        self.movesHistory = moves
        self.positionsCounter = positionsCounter
        self.rules = StandardRules()
    }

    /**
     Initialize game with given position.
    
     - Parameters:
        - position: Initial game position.
        - moves: List of moves before given position.
    */
    public init(position: Position, moves: [Move] = []) {
        self.positionsCounter = [
            position.board: 1
        ]
        self.movesHistory = moves
        self.position = position
        self.rules = StandardRules()
    }

    /**
     Initialize game with given position and rules.
    
     - Parameters:
        - position: Initial game position.
        - moves: List of moves before given position.
        - rules: Game rules.
     */
    internal init(position: Position, moves: [Move] = [], rules: Rules) {
        self.positionsCounter = [
            position.board: 1
        ]
        self.movesHistory = moves
        self.position = position
        self.rules = rules
    }

    // MARK: Making moves

    /// List of legal moves in current game position.
    public var legalMoves: [Move] {
        return self.rules.legalMoves(in: self.position)
    }

    /// Parses and applies a coordinate move.
    /// - Throws: `MoveParsingError` or `GameMoveError`. A rejected move does not change the game.
    public func make(move stringMove: String) throws {
        let move = try Move(string: stringMove)
        try self.make(move: move)
    }

    /// Applies a legal move after checking all counters.
    /// - Throws: `GameMoveError`. Position, history, and occurrence counts remain unchanged on failure.
    public func make(move: Move) throws {
        guard self.isLegal(move: move) else {
            throw GameMoveError.illegalMove
        }

        let counters = try self.counters(after: move)
        var next = self.position.applyingLegalMove(move)
        next.counter = counters

        let occurrences = self.positionsCounter[next.board, default: 0]
        let nextOccurrences = try self.increment(occurrences, counter: .repetitions)

        self.position = next
        self.movesHistory.append(move)
        self.positionsCounter[next.board] = nextOccurrences
    }

    func isLegal(move: Move) -> Bool {
        guard move.from.isValid, move.to.isValid, move.from != move.to else {
            return false
        }

        return self.rules.movesForPiece(at: move.from, in: self.position).contains(move)
    }

    private func counters(after move: Move) throws -> Position.Counter {
        let current = self.position.counter

        guard current.halfMoves >= 0, current.fullMoves >= 1 else {
            throw GameMoveError.invalidPositionCounters
        }

        let isPawnMove = self.position.board[move.from]?.kind == .pawn
        let isCapture = self.position.board[move.to] != nil
        var next = current

        if isPawnMove || isCapture {
            next.halfMoves = 0
        } else {
            next.halfMoves = try self.increment(current.halfMoves, counter: .halfMoves)
        }

        if self.position.state.turn == .black {
            next.fullMoves = try self.increment(current.fullMoves, counter: .fullMoves)
        }

        return next
    }

    private func increment(_ value: Int, counter: GameMoveError.Counter) throws -> Int {
        let (result, overflow) = value.addingReportingOverflow(1)

        guard !overflow else {
            throw GameMoveError.counterOverflow(counter)
        }

        return result
    }

    // MARK: Utilities

    /**
     Creates a deep copy of current game.
    
     - Returns: New `Game` object.
     */
    public func deepCopy() -> Game {
        let position = self.position
        let moves = self.movesHistory.map { $0 }

        return Game(
            position: position,
            moves: moves,
            positionsCounter: self.positionsCounter
        )
    }

}
