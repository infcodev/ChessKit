"""Compare public ChessKit behavior with a separate python-chess process.

We wrote this harness under MIT. We do not copy or vendor python-chess code.
The external chess==1.11.2 package is GPL-3.0-or-later and is used only for tests.
"""
import argparse
import json
from pathlib import Path
import random
import subprocess
import time

import chess

SEEDS = [
    chess.STARTING_FEN,
    "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
    "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
    "7k/8/8/3pP3/8/8/8/4K3 w - d6 0 1",
    "4r2k/8/8/3pP3/8/8/8/4K3 w - d6 0 1",
    "7k/8/8/r4pPK/8/8/8/8 w - f6 0 1",
    "4k3/P6p/8/8/8/8/7P/4K3 w - - 0 1",
    "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1",
    "7k/6Q1/5K2/8/8/8/8/8 b - - 150 80",
    "7k/5K2/6Q1/8/8/8/8/8 b - - 150 80",
    "7k/8/8/8/8/8/8/4K1N1 w - - 0 1",
    "5b1k/8/8/8/8/4B3/8/2B1K3 w - - 0 1",
    "7k/8/8/8/8/8/8/2NNK3 w - - 0 1",
    "7k/8/8/8/8/8/8/R3K3 w - - 99 80",
    "7k/8/8/8/8/8/8/R3K3 w - - 100 80",
    "7k/8/8/8/8/8/8/R3K3 w - - 149 80",
    "7k/8/8/8/8/8/8/R3K3 w - - 150 80",
]


def status(board):
    result = board.outcome(claim_draw=False)
    if result is None:
        return "ongoing"
    names = {
        chess.Termination.STALEMATE: "stalemate",
        chess.Termination.INSUFFICIENT_MATERIAL: "dead",
        chess.Termination.FIVEFOLD_REPETITION: "fivefold",
        chess.Termination.SEVENTYFIVE_MOVES: "seventyfive",
    }
    if result.termination == chess.Termination.CHECKMATE:
        return "white-mate" if result.winner == chess.WHITE else "black-mate"
    return names[result.termination]


def claims(board):
    if board.outcome(claim_draw=False) is not None:
        return []
    result = []
    if board.is_fifty_moves():
        result.append("fifty")
    if board.is_repetition(3):
        result.append("threefold")
    return result


def reference(board):
    candidates = []
    ongoing = status(board) == "ongoing"
    for move in sorted(board.legal_moves, key=lambda item: item.uci()):
        notation = board.san(move)
        board.push(move)
        candidates.append({
            "move": move.uci(), "san": notation, "fen": board.fen(en_passant="fen"),
            "claims": claims(board) if ongoing else [],
        })
        board.pop()
    repetition = 1
    while board.is_repetition(repetition + 1):
        repetition += 1
    ep = chess.square_name(board.ep_square) if board.has_legal_en_passant() else None
    return {
        "fen": board.fen(en_passant="fen"), "check": board.is_check(),
        "status": status(board), "repetition": repetition,
        "enPassant": ep, "claims": claims(board), "candidates": candidates,
    }


def cases(random_games, plies):
    for seed in SEEDS:
        board = chess.Board(seed)
        for position in [board, board.mirror()]:
            yield position.fen(en_passant="fen"), [], position
    # Include history-dependent results and rights lost after returning a rook.
    for seed, cycle in [
        (chess.STARTING_FEN, ["g1f3", "g8f6", "f3g1", "f6g8"]),
        (SEEDS[7], ["h1h2", "h8h7", "h2h1", "h7h8"]),
    ]:
        board = chess.Board(seed)
        moves = []
        for move in cycle * 5:
            board.push_uci(move)
            moves.append(move)
            yield seed, list(moves), board
    for game_index in range(random_games):
        rng = random.Random(20260910 + game_index)
        seed = SEEDS[game_index % 8]
        board = chess.Board(seed)
        moves = []
        for _ in range(plies):
            yield seed, list(moves), board
            legal = sorted(board.legal_moves, key=lambda item: item.uci())
            if not legal:
                break
            move = rng.choice(legal)
            board.push(move)
            moves.append(move.uci())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", type=Path, required=True)
    parser.add_argument("--games", type=int, default=12)
    parser.add_argument("--plies", type=int, default=80)
    args = parser.parse_args()
    if chess.__version__ != "1.11.2":
        raise SystemExit("We require chess==1.11.2 for a reproducible comparison.")
    if args.games < 1 or args.plies < 1:
        raise SystemExit("We require positive game and ply counts.")

    start = time.monotonic()
    count = comparisons = 0
    process = subprocess.Popen(
        [str(args.binary.resolve())], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
        text=True, bufsize=1,
    )
    try:
        for seed, moves, board in cases(args.games, args.plies):
            if not board.is_valid():
                raise AssertionError(f"Invalid verification seed: {seed}")
            request = {"fen": seed, "moves": moves}
            process.stdin.write(json.dumps(request) + "\n")
            process.stdin.flush()
            output = process.stdout.readline()
            if not output:
                raise AssertionError(f"Verifier stopped on {request}")
            actual = json.loads(output)
            # Swift omits a nil optional from its JSON object.
            actual.setdefault("enPassant", None)
            expected = reference(board)
            if actual != expected:
                differences = {
                    key: {"expected": value, "actual": actual.get(key)}
                    for key, value in expected.items() if actual.get(key) != value
                }
                raise AssertionError(json.dumps({
                    "request": request, "differences": differences,
                    "error": actual.get("error"),
                }, indent=2))
            count += 1
            comparisons += len(expected["candidates"])
        process.stdin.close()
        if process.wait(timeout=10) != 0:
            raise AssertionError("Verifier returned an unsuccessful exit status.")
    finally:
        if process.poll() is None:
            process.kill()
            process.wait()
    print(json.dumps({
        "reference": f"python-chess {chess.__version__}", "positions": count,
        "legal_moves_san_and_results": comparisons,
        "elapsed_seconds": round(time.monotonic() - start, 3),
    }, indent=2))


if __name__ == "__main__":
    main()
