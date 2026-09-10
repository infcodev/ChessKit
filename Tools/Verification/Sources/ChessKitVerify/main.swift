import ChessKit
import Foundation

struct Request: Decodable {
    let fen: String
    let moves: [String]
}

struct Candidate: Encodable {
    let move: String
    let san: String
    let fen: String
    let claims: [String]
}

struct Response: Encodable {
    let fen: String
    let check: Bool
    let status: String
    let repetition: Int
    let enPassant: String?
    let claims: [String]
    let candidates: [Candidate]
}

func claimNames(_ claims: Set<DrawClaim>) -> [String] {
    claims.map { $0 == .fiftyMoveRule ? "fifty" : "threefold" }.sorted()
}

func statusName(_ status: GameStatus) -> String {
    switch status {
    case .invalidPosition(let issues): return "invalid: \(issues)"
    case .ongoing: return "ongoing"
    case .checkmate(let winner): return winner == .white ? "white-mate" : "black-mate"
    case .draw(.stalemate): return "stalemate"
    case .draw(.deadPosition): return "dead"
    case .draw(.fivefoldRepetition): return "fivefold"
    case .draw(.seventyFiveMoveRule): return "seventyfive"
    }
}

func inspect(_ request: Request) throws -> Response {
    let fen = FenSerialization()
    let san = SanSerialization()
    let game = Game(position: try fen.deserialize(fen: request.fen))
    for move in request.moves {
        try game.make(move: move)
    }
    try game.position.validate()
    var candidates: [Candidate] = []
    for move in game.legalMoves.sorted(by: { $0.description < $1.description }) {
        let notation = try san.san(for: move, in: game)
        let decoded = try san.move(for: notation, in: game)
        guard decoded == move else {
            throw VerificationError.sanRoundTrip
        }
        let copy = game.deepCopy()
        try copy.make(move: move)
        candidates.append(Candidate(
            move: move.description, san: notation,
            fen: fen.serialize(position: copy.position),
            claims: claimNames(try game.drawClaims(after: move))
        ))
    }
    return Response(
        fen: fen.serialize(position: game.position), check: game.isCheck,
        status: statusName(game.status), repetition: game.repetitionCount,
        enPassant: PositionKey(position: game.position).enPassant?.coordinate,
        claims: claimNames(game.availableDrawClaims), candidates: candidates
    )
}

enum VerificationError: Error { case sanRoundTrip }

// A persistent line protocol keeps build and process startup outside the measurements.
let decoder = JSONDecoder()
let encoder = JSONEncoder()
while let line = readLine() {
    do {
        let request = try decoder.decode(Request.self, from: Data(line.utf8))
        let response = try inspect(request)
        print(String(decoding: try encoder.encode(response), as: UTF8.self))
    } catch {
        let failure = ["error": String(describing: error)]
        print(String(decoding: try encoder.encode(failure), as: UTF8.self))
    }
    fflush(stdout)
}
