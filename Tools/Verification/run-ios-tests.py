"""Run package tests on an available iPhone simulator without a fixed device name."""
import argparse
import json
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--derived-data", type=Path, required=True)
    parser.add_argument("--device-id")
    parser.add_argument("--configuration", choices=["Debug", "Release"], default="Debug")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    device_id = args.device_id
    if device_id is None:
        output = subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "available", "-j"], text=True
        )
        devices = json.loads(output)["devices"]
        candidates = [
            device for runtime, entries in sorted(devices.items()) if ".iOS-" in runtime
            for device in entries
            if device.get("isAvailable") and "iPhone" in device.get("name", "")
        ]
        if not candidates:
            raise SystemExit("We need an available iPhone simulator to run the iOS tests.")
        device_id = candidates[0]["udid"]
        print(f"We use {candidates[0]['name']} ({device_id}).", flush=True)
    subprocess.run([
        "xcodebuild", "-scheme", "ChessKit", "-configuration", args.configuration,
        "-destination", f"platform=iOS Simulator,id={device_id}",
        "-derivedDataPath", str(args.derived_data.resolve()),
        "-parallel-testing-enabled", "NO", "CODE_SIGNING_ALLOWED=NO",
        "ENABLE_TESTABILITY=YES", "test",
    ], cwd=root, check=True)


if __name__ == "__main__":
    main()
