"""A stand-in for the `herdr` binary in tests: checks config.toml with a real TOML parser, answers the rest."""
import json, os, sys, tomllib
from pathlib import Path

args = sys.argv[1:]
if args[:2] == ["config", "check"]:
    try:
        tomllib.loads(Path(os.environ["HERDR_CONFIG_PATH"]).read_text())
    except tomllib.TOMLDecodeError as e:
        sys.exit(f"config.toml: {e}")
elif args[:2] == ["agent", "list"]:
    print(json.dumps({"result": {"agents": []}}))
