import ChessKit
import Testing

private let initialFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

struct AdversarialHostileInputTests {
    @Test
    func coordinateGrammarAcrossEveryASCIIByte() throws {
        // The grammar is independent of the move parser: [a-h][1-8] twice.
        let template = Array("e2e4".utf8)
        for offset in 0..<4 {
            for byte in UInt8(0)...UInt8(127) {
                var bytes = template
                bytes[offset] = byte
                let token = String(decoding: bytes, as: UTF8.self)
                let validFile = (UInt8(ascii: "a")...UInt8(ascii: "h")).contains(byte)
                let validRank = (UInt8(ascii: "1")...UInt8(ascii: "8")).contains(byte)
                let sameSquare = bytes[0] == bytes[2] && bytes[1] == bytes[3]
                let valid = (offset.isMultiple(of: 2) ? validFile : validRank) && !sameSquare
                if valid {
                    #expect(try Move(string: token).description == token)
                } else {
                    #expect(throws: MoveParsingError.self) { try Move(string: token) }
                }
            }
        }
        for byte in UInt8(0)...UInt8(127) {
            let suffix = String(UnicodeScalar(byte))
            if "qrbnQRBN".contains(suffix) {
                #expect(try Move(string: "a7a8" + suffix).description == "a7a8" + suffix.lowercased())
            } else {
                #expect(throws: MoveParsingError.self) { try Move(string: "a7a8" + suffix) }
            }
        }
    }

    @Test(arguments: [
        "e2\u{0000}e4", "ｅ2e4", "e２e4", "е2e4", "e2e⁴", "e2e4\u{200B}",
        "e2\u{202E}e4", "e2e4\u{FEFF}", "e2e4\n", " e2e4", "♙e4", "e2e4🙂",
    ])
    func rejectsCoordinateLookalikesAndHiddenCharacters(token: String) {
        #expect(throws: MoveParsingError.self) { try Move(string: token) }
    }

    @Test
    func malformedFENFieldsDoNotPoisonTheSerializer() throws {
        let parser = FenSerialization()
        let validFields = initialFEN.split(separator: " ").map(String.init)
        let badFields: [[String]] = [
            ["8/8/8/8/8/8/8/44", "8/8/8/8/8/8/8/0", "8/8/8/8/8/8/8/９", "8/8/8/8/8/8/8/7♔", String(repeating: "8/", count: 2048)],
            ["W", "white", "ｗ", "w\u{200B}", "\u{0000}"],
            ["KK", "qk", "QK", "K-K", "Ａ", "KQkqK"],
            ["a3", "h3", "a9", "i6", "a６", "-a6"],
            ["-1", "+1", "１", "1.0", "1e2", String(Int.max) + "0", String(repeating: "9", count: 4096)],
            ["0", "-1", "+1", "٠", "1.0", String(Int.max) + "0"],
        ]
        for (field, tokens) in badFields.enumerated() {
            for token in tokens {
                var fields = validFields
                fields[field] = token
                #expect(throws: FenSerializationError.self) {
                    try parser.deserialize(fen: fields.joined(separator: " "))
                }
                #expect(try parser.serialize(position: parser.deserialize(fen: initialFEN)) == initialFEN)
            }
        }
        // Multiple invalid fields must report the first field, not a later error.
        #expect(throws: FenSerializationError.invalidActiveColor) {
            try parser.deserialize(fen: "8/8/8/8/8/8/8/8 X KK a9 -1 0")
        }
        let separators = [" ", "\t", "\n", "\r\n", "\u{00A0}", "\u{2003}"]
        for separator in separators {
            let input = separator + validFields.joined(separator: separator) + separator
            #expect(try parser.serialize(position: parser.deserialize(fen: input)) == initialFEN)
        }
    }

    @Test
    func hostileSANAndIllegalMovesLeaveAnExistingLineUnchanged() throws {
        let game = Game(position: try FenSerialization().deserialize(fen: initialFEN))
        for move in ["g1f3", "g8f6", "f3g1", "f6g8"] {
            try game.make(move: move)
        }
        let before = PublicSnapshot(game)
        let parser = SanSerialization()
        let invalidTokens = [
            "", "Nf3!!", "1.Nf3", "Nf3 {note}", "Nf3 e5", "Nxf3", "nf3", "♘f3",
            "Nf３", "Nf3++", "Nf3#", "Nf3+", "Nf3=Q", "0–0", "O-O-O-O",
            "N\u{0000}f3", "N\u{200B}f3", "Nf3\u{202E}", String(repeating: "N", count: 65536),
        ]
        for token in invalidTokens {
            #expect(throws: SanSerializationError.self) { try parser.move(for: token, in: game) }
            #expect(PublicSnapshot(game) == before)
            #expect(try parser.move(for: "Nf3", in: game).description == "g1f3")
        }
        for token in ["e2e5", "e7e5", "e1g1", "a1a8", "e2f3", "a7a8q", "g1f3q"] {
            let move = try Move(string: token)
            #expect(throws: GameMoveError.self) { try game.make(move: move) }
            #expect(throws: GameMoveError.self) { try game.drawClaims(after: move) }
            #expect(throws: SanSerializationError.self) { try parser.san(for: move, in: game) }
            #expect(PublicSnapshot(game) == before)
        }
        try game.make(move: "g1f3")
        #expect(game.movesHistory.count == 5)
        #expect(game.repetitionCount == 2)
    }

    @Test
    func allSquareTranslationsStayWithinTheirOwnFileAndRank() throws {
        let game = Game(position: try FenSerialization().deserialize(fen: initialFEN))
        for file in 0..<8 {
            for rank in 0..<8 {
                let square = Square(file: file, rank: rank)
                for fileOffset in [-9, -8, -1, 0, 1, 8, 9] {
                    for rankOffset in [-9, -8, -1, 0, 1, 8, 9] {
                        let translated = square.translate(file: fileOffset, rank: rankOffset)
                        let valid = (0..<8).contains(file + fileOffset) && (0..<8).contains(rank + rankOffset)
                        #expect(translated.isValid == valid)
                        if valid {
                            #expect(translated == Square(file: file + fileOffset, rank: rank + rankOffset))
                        } else {
                            #expect(translated.coordinate == "--")
                        }
                    }
                }
            }
        }
        var board = game.position.board
        let before = board
        for index in [Int.min, -65, -64, -1, 64, 65, Int.max] {
            let square = Square(index: index)
            #expect(!square.isValid)
            #expect(board[square] == nil)
            board[square] = before[Square(coordinate: "a1")]
            #expect(board == before)
        }
        for offset in [Int.min, Int.max] {
            #expect(!Square(coordinate: "h8").translate(file: offset, rank: offset).isValid)
        }
    }
}
