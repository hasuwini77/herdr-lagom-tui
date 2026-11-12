"""End-to-end smoke test for `lagom` on macOS, Linux and Windows, in a throwaway home with a fake Herdr.

    python tests/smoke.py
"""
import json, os, subprocess, sys, tempfile, tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
USER_CONFIG = """[keys]
split_vertical = ["prefix+v", "ctrl+alt+d"]

[ui]
confirm_close = true

[theme]
name = "dracula"

[ui.sidebar.agents]
rows = [
  [{ token = "state_text", bold = true }, "workspace"],
  ["agent"],
]

[theme.custom]
red = "#ff2d55"
"""
USER_HOOK = {"type": "command", "command": "echo mine", "timeout": 5}


def main():
    with tempfile.TemporaryDirectory() as tmp:
        home = Path(tmp)
        env = dict(os.environ, HOME=str(home), USERPROFILE=str(home), XDG_CONFIG_HOME=str(home / ".config"))
        env.pop("HERDR_PANE_ID", None)
        env.pop("WSL_DISTRO_NAME", None)
        bindir = home / "fakebin"
        bindir.mkdir()
        fake = REPO / "tests/fake_herdr.py"
        if os.name == "nt":
            herdr = bindir / "herdr.cmd"
            herdr.write_text(f'@"{sys.executable}" "{fake}" %*\r\n')
        else:
            herdr = bindir / "herdr"
            herdr.write_text(f'#!/bin/sh\nexec "{sys.executable}" "{fake}" "$@"\n')
            herdr.chmod(0o755)
        config = home / ".config/herdr/config.toml"
        config.parent.mkdir(parents=True)
        config.write_text(USER_CONFIG)
        env.update(HERDR_BIN_PATH=str(herdr), HERDR_CONFIG_PATH=str(config))
        (home / ".wezterm.lua").write_text("local wezterm = require 'wezterm'\nlocal config = wezterm.config_builder()\nreturn config\n")
        claude = home / ".claude/settings.json"
        claude.parent.mkdir()
        claude.write_text(json.dumps({"hooks": {"Stop": [{"hooks": [USER_HOOK]}]}}, indent=2) + "\n")

        def lagom(*args):
            out = subprocess.run([sys.executable, str(REPO / "bin/lagom"), *args], env=env, capture_output=True, text=True, timeout=120)
            assert out.returncode == 0, f"lagom {' '.join(args)} failed:\n{out.stdout}{out.stderr}"
            return out.stdout.strip()

        print(lagom("install"))
        print(lagom("theme", "graphite"))
        print(lagom("wallpaper", "starfield"))

        doc = tomllib.loads(config.read_text())
        graphite = json.loads((REPO / "themes/lagom-graphite.json").read_text())
        assert doc["theme"]["name"] == "catppuccin", doc["theme"]
        assert doc["theme"]["custom"]["accent"] == graphite["colors"]["accent"]
        assert "red" in doc["theme"]["custom"] and doc["theme"]["custom"]["red"] != "#ff2d55", "user [theme.custom] not parked"
        assert doc["ui"]["confirm_close"] is True and len(doc["ui"]["sidebar"]["agents"]["rows"]) == 2
        assert "lagom" in doc["ui"]["tab_bar_right"][0]["command"]
        assert len(doc["keys"]["command"]) == 3

        state = json.loads((home / ".config/wezterm/lagom-state.json").read_text())
        assert state["background"]["image"].endswith("starfield.png"), state["background"]
        assert 0 <= state["background"]["dim"] < 1
        assert "lagom.lua" in (home / ".wezterm.lua").read_text()

        hooks = json.loads(claude.read_text())["hooks"]
        assert sum("lagom" in h["command"] for ev in hooks.values() for g in ev for h in g["hooks"]) == 4
        assert USER_HOOK in [h for g in hooks["Stop"] for h in g["hooks"]]

        assert lagom("status") == "no agents"
        print(lagom("uninstall"))

        assert config.read_text().rstrip("\n") == USER_CONFIG.rstrip("\n"), "config.toml not restored:\n" + config.read_text()
        assert json.loads(claude.read_text()) == {"hooks": {"Stop": [{"hooks": [USER_HOOK]}]}}
        assert "lagom" not in (home / ".wezterm.lua").read_text()
    print("smoke: ok")


if __name__ == "__main__":
    main()
