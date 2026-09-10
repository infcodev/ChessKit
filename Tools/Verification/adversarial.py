"""Independent adversarial fixtures and a bounded public-protocol campaign.

We wrote this tool under MIT. We use the external GPL-3.0-or-later chess package
only as a test reference. We do not import or read ChessKit source files.
"""
import argparse
from collections import Counter, defaultdict
import json
from pathlib import Path
import random
import select
import subprocess
import time

import chess

SEED = 0xC4E55
# We choose these geometric cases from the rules, before querying ChessKit.
ANCHORS = [
    ("castling-attacks", "7k/8/8/8/8/7b/8/4K2R w K - 0 1"),
    ("castling-attacks", "1r5k/8/8/8/8/8/8/R3K3 w Q - 0 1"),
    ("promotion", "r3k2r/1P6/8/8/8/8/8/4K3 w kq - 0 1"),
    ("en-passant", "7k/8/8/2PpP3/8/8/8/4K3 w - d6 0 1"),
    ("en-passant", "3r3k/8/8/3PpP2/8/8/8/3K4 w - e6 0 1"),
    ("en-passant", "8/8/8/r4pPK/8/8/8/7k w - f6 0 1"),
    ("en-passant", "7k/8/8/3pP3/4K3/8/8/8 w - d6 0 1"),
    ("en-passant", "8/8/8/3pP3/8/8/8/3RK2k w - d6 0 1"),
    ("disambiguation", "8/7k/8/8/Q7/8/8/Q2Q3K w - - 0 1"),
    ("disambiguation", "4r2k/8/8/8/8/8/4N1N1/4K3 w - - 0 1"),
    ("disambiguation", "7k/8/8/8/8/1N3N2/8/1N5K w - - 0 1"),
    ("terminal", "7k/6Q1/5K2/8/8/8/8/8 b - - 150 80"),
    ("terminal", "7k/5K2/6Q1/8/8/8/8/8 b - - 150 80"),
    ("terminal", "7k/8/8/8/8/8/8/2NNK3 w - - 149 80"),
    ("terminal", "7k/8/8/8/8/4B3/8/2B1K3 w - - 150 80"),
    ("check", "4r2k/8/8/8/1b6/8/8/4K3 w - - 0 1"),
    ("check", "7k/8/8/8/8/8/4r3/4K3 w - - 0 1"),
]


def result_name(board):
    outcome = board.outcome(claim_draw=False)
    if outcome is None:
        return "ongoing"
    if outcome.termination == chess.Termination.CHECKMATE:
        return "white-mate" if outcome.winner else "black-mate"
    return {
        chess.Termination.STALEMATE: "stalemate",
        chess.Termination.INSUFFICIENT_MATERIAL: "dead",
        chess.Termination.SEVENTYFIVE_MOVES: "seventyfive",
        chess.Termination.FIVEFOLD_REPETITION: "fivefold",
    }[outcome.termination]


def current_claims(board):
    if board.outcome(claim_draw=False):
        return []
    result = []
    if board.is_fifty_moves():
        result.append("fifty")
    if board.is_repetition(3):
        result.append("threefold")
    return result


def expected(board):
    candidates = []
    current_is_ongoing = board.outcome(claim_draw=False) is None
    for move in sorted(board.legal_moves, key=lambda move: move.uci()):
        san = board.san(move)
        child = board.copy(stack=True)
        child.push(move)
        candidates.append({
            "move": move.uci(), "san": san,
            "fen": child.fen(en_passant="fen"),
            "claims": current_claims(child) if current_is_ongoing else [],
        })
    count = 1
    while board.is_repetition(count + 1):
        count += 1
    return {
        "fen": board.fen(en_passant="fen"), "check": board.is_check(),
        "status": result_name(board), "repetition": count,
        "enPassant": chess.square_name(board.ep_square) if board.has_legal_en_passant() else None,
        "claims": current_claims(board), "candidates": candidates,
    }


def position_case(category, board, name):
    return {"id": name, "category": category, "fen": board.fen(en_passant="fen"), "moves": []}


def mirrored(category, board, name):
    for suffix, candidate in [("white", board), ("black", board.mirror())]:
        if candidate.is_valid():
            yield position_case(category, candidate, f"{name}-{suffix}")


def geometries():
    for index, (category, fen) in enumerate(ANCHORS):
        board = chess.Board(fen)
        if not board.is_valid():
            raise AssertionError(f"Invalid rule anchor {index}: {fen}")
        yield from mirrored(category, board, f"anchor-{index}")

    # All promotion files, every choice, and captures on either adjacent file.
    for file in range(8):
        for king_file in range(8):
            board = chess.Board(None)
            board.set_piece_at(chess.square(file, 6), chess.Piece(chess.PAWN, chess.WHITE))
            board.set_piece_at(chess.square(king_file, 4), chess.Piece(chess.KING, chess.WHITE))
            board.set_piece_at(chess.square(7 - king_file, 7), chess.Piece(chess.KING, chess.BLACK))
            for capture_file in [file - 1, file + 1]:
                if 0 <= capture_file <= 7 and capture_file != 7 - king_file:
                    board.set_piece_at(chess.square(capture_file, 7), chess.Piece(chess.ROOK, chess.BLACK))
            yield from mirrored("promotion", board, f"promotion-{file}-{king_file}")

    # Vary all 16 rights sets and every square of each attacker kind.
    for rights in range(16):
        token = "".join(letter for bit, letter in enumerate("KQkq") if rights & (1 << bit)) or "-"
        board = chess.Board(f"r3k2r/8/8/8/8/8/8/R3K2R w {token} - 0 1")
        yield from mirrored("castling-rights", board, f"rights-{rights}")
    for kind in [chess.PAWN, chess.KNIGHT, chess.BISHOP, chess.ROOK, chess.QUEEN]:
        for square in chess.SQUARES:
            board = chess.Board("4k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")
            if board.piece_at(square):
                continue
            board.set_piece_at(square, chess.Piece(kind, chess.BLACK))
            yield from mirrored("castling-attacks", board, f"castle-{kind}-{square}")

    # Edge files, a second capturer, and attacks along rank, file, and diagonal.
    for file in range(8):
        for direction in [-1, 1]:
            if not 0 <= file + direction <= 7:
                continue
            for king_square in [chess.A1, chess.D1, chess.H5, chess.E4]:
                board = chess.Board(None)
                board.set_piece_at(chess.H8, chess.Piece(chess.KING, chess.BLACK))
                board.set_piece_at(king_square, chess.Piece(chess.KING, chess.WHITE))
                if board.piece_at(chess.square(file, 4)) or board.piece_at(chess.square(file + direction, 4)):
                    continue
                board.set_piece_at(chess.square(file, 4), chess.Piece(chess.PAWN, chess.BLACK))
                board.set_piece_at(chess.square(file + direction, 4), chess.Piece(chess.PAWN, chess.WHITE))
                board.ep_square = chess.square(file, 5)
                yield from mirrored("en-passant", board, f"ep-{file}-{direction}-{king_square}")
                for kind, attacker in [(chess.ROOK, chess.A5), (chess.ROOK, chess.D8), (chess.BISHOP, chess.A8)]:
                    if not board.piece_at(attacker) and attacker != board.ep_square:
                        copy = board.copy()
                        copy.set_piece_at(attacker, chess.Piece(kind, chess.BLACK))
                        yield from mirrored("en-passant", copy, f"ep-{file}-{direction}-{king_square}-{kind}-{attacker}")


def sparse_positions(count):
    rng = random.Random(SEED)
    accepted = attempts = 0
    while accepted < count:
        attempts += 1
        if attempts > count * 200:
            raise AssertionError("Could not produce the requested valid sparse positions")
        board = chess.Board(None)
        squares = rng.sample(list(chess.SQUARES), rng.randint(4, 15))
        board.set_piece_at(squares.pop(), chess.Piece(chess.KING, chess.WHITE))
        board.set_piece_at(squares.pop(), chess.Piece(chess.KING, chess.BLACK))
        repeated_kind = rng.choice([chess.KNIGHT, chess.BISHOP, chess.ROOK, chess.QUEEN])
        for index, square in enumerate(squares):
            kind = repeated_kind if index % 2 == 0 else rng.choice([chess.PAWN, chess.KNIGHT, chess.BISHOP, chess.ROOK, chess.QUEEN])
            board.set_piece_at(square, chess.Piece(kind, rng.choice([chess.WHITE, chess.BLACK])))
        board.turn = rng.choice([chess.WHITE, chess.BLACK])
        board.halfmove_clock = rng.choice([0, 1, 98, 99, 100, 149, 150])
        board.fullmove_number = rng.choice([1, 80, 9999])
        if board.is_valid():
            yield position_case("sparse", board, f"sparse-{accepted}")
            accepted += 1


def histories(games, plies):
    for index, (fen, cycle) in enumerate([
        (chess.STARTING_FEN, ["g1f3", "g8f6", "f3g1", "f6g8"]),
        ("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 98 80", ["h1h2", "h8h7", "h2h1", "h7h8"]),
        ("7k/8/5n2/3pP3/8/5N2/8/4K3 w - d6 0 1", ["f3g1", "f6g8", "g1f3", "g8f6"]),
        ("4r2k/8/5n2/3pP3/8/5N2/8/4K3 w - d6 0 1", ["f3g1", "f6g8", "g1f3", "g8f6"]),
    ]):
        board = chess.Board(fen)
        moves = []
        for ply, uci in enumerate(cycle * 5):
            board.push_uci(uci)
            moves.append(uci)
            yield {"id": f"cycle-{index}-{ply}", "category": "history", "fen": fen, "moves": list(moves)}
    for index in range(games):
        rng = random.Random(SEED + index)
        fen = chess.STARTING_FEN if index % 2 == 0 else "r3k2r/ppp2ppp/8/3pp3/3PP3/8/PPP2PPP/R3K2R w KQkq - 0 1"
        board = chess.Board(fen)
        moves = []
        for ply in range(plies):
            legal = sorted(board.legal_moves, key=lambda move: move.uci())
            if not legal:
                break
            weights = [1 + 5 * board.is_capture(move) + 4 * board.gives_check(move) + 12 * bool(move.promotion) + 12 * board.is_castling(move) for move in legal]
            move = rng.choices(legal, weights=weights, k=1)[0]
            board.push(move)
            moves.append(move.uci())
            if ply % 4 == 0 or move.promotion or board.is_check():
                yield {"id": f"line-{index}-{ply}", "category": "line", "fen": fen, "moves": list(moves)}


def board_for(case):
    board = chess.Board(case["fen"])
    for uci in case["moves"]:
        board.push_uci(uci)
    if not board.is_valid():
        raise AssertionError(f"Invalid generated case: {case['id']}")
    return board


def all_cases(sparse, games, plies):
    yield from geometries()
    yield from sparse_positions(sparse)
    yield from histories(games, plies)


def offline_cases():
    groups = defaultdict(list)
    for case in all_cases(160, 4, 96):
        groups[case["category"]].append(case)
    selected = []
    for category in sorted(groups):
        cases = groups[category]
        # Deterministic spread, not just the first easy cases of a category.
        anchors = [case for case in cases if case["id"].startswith("anchor-")]
        generated = [case for case in cases if not case["id"].startswith("anchor-")]
        selected.extend(anchors)
        count = min(40, len(generated))
        if count:
            selected.extend(generated[index * len(generated) // count] for index in range(count))
    return [{**case, "expected": expected(board_for(case))} for case in selected]


def coverage(case, board, counters):
    counters["positions"] += 1
    counters[f"category:{case['category']}"] += 1
    counters["in_check"] += board.is_check()
    counters["terminal"] += board.outcome(claim_draw=False) is not None
    for move in board.legal_moves:
        counters["legal_moves"] += 1
        counters["en_passant"] += board.is_en_passant(move)
        counters["castling"] += board.is_castling(move)
        counters["promotion"] += bool(move.promotion)
        counters["underpromotion"] += bool(move.promotion and move.promotion != chess.QUEEN)
        counters["mate_san"] += board.san(move).endswith("#")


def assert_scope(counters):
    for key in ["en_passant", "castling", "underpromotion", "mate_san", "terminal", "category:history", "category:sparse"]:
        if not counters[key]:
            raise AssertionError(f"Missing mandatory scenario: {key}")


def campaign(binary, cases, report):
    counters = Counter()
    failures = []
    started = time.monotonic()
    process = subprocess.Popen([str(binary.resolve())], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
    try:
        for case in cases:
            board = board_for(case)
            oracle = expected(board)  # Freeze expected behavior before the query.
            coverage(case, board, counters)
            process.stdin.write(json.dumps({"fen": case["fen"], "moves": case["moves"]}) + "\n")
            process.stdin.flush()
            if not select.select([process.stdout], [], [], 10)[0]:
                failures.append({"case": case, "error": "No response within 10 seconds"})
                break
            line = process.stdout.readline()
            if not line:
                failures.append({"case": case, "error": "Verifier stopped before responding"})
                break
            actual = json.loads(line)
            actual.setdefault("enPassant", None)
            if actual != oracle:
                failures.append({"case": case, "differences": {key: {"expected": value, "actual": actual.get(key)} for key, value in oracle.items() if value != actual.get(key)}, "error": actual.get("error")})
                if len(failures) >= 20:
                    break
        if not failures:
            assert_scope(counters)
    finally:
        process.stdin.close()
        try:
            process.wait(timeout=10)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
    summary = {"reference": chess.__version__, "seed": SEED, "counts": dict(sorted(counters.items())), "failures": failures, "seconds": round(time.monotonic() - started, 3)}
    if report:
        report.write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))
    return 1 if failures or process.returncode else 0


def main():
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--write-corpus", type=Path)
    mode.add_argument("--check-corpus", type=Path)
    mode.add_argument("--binary", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--sparse", type=int, default=1600)
    parser.add_argument("--games", type=int, default=24)
    parser.add_argument("--plies", type=int, default=240)
    args = parser.parse_args()
    if chess.__version__ != "1.11.2":
        parser.error("We require chess==1.11.2")
    if min(args.sparse, args.games, args.plies) < 1:
        parser.error("We require positive campaign sizes")
    if args.write_corpus or args.check_corpus:
        corpus = {"reference": "chess==1.11.2", "seed": SEED, "cases": offline_cases()}
        encoded = json.dumps(corpus, ensure_ascii=True, indent=2) + "\n"
        counts = Counter()
        for case in corpus["cases"]:
            coverage(case, board_for(case), counts)
        assert_scope(counts)
        if args.write_corpus:
            args.write_corpus.write_text(encoded)
        elif args.check_corpus.read_text() != encoded:
            raise AssertionError("Committed corpus differs from the independent generator")
        print(json.dumps(dict(sorted(counts.items())), indent=2))
        return 0
    return campaign(args.binary, all_cases(args.sparse, args.games, args.plies), args.report)


if __name__ == "__main__":
    raise SystemExit(main())
