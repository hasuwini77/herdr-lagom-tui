# Herdr sidebar and tab bar: headings, agent logos, state colours

The logos and the sidebar state colours work on stock Herdr; the headings and the coloured tab-bar
status need a patched build.

## 1. Agent logos and state colours (no patch)

Needs the `hasuwini77.spinner` plugin at v0.3.0 or later (`git pull` in its
folder, then `herdr plugin action invoke restart --plugin hasuwini77.spinner`).

In `~/.config/herdr/config.toml`, the agent row ends with `$logo` instead of
`"agent"`:

```toml
[ui.sidebar.agents]
rows = [
  [{ token = "$spin", fg = "#fab387", dim = false, bold = true }, { token = "workspace", bold = false }, { token = "state_text", bold = false, dim = false, rules = [{ equals = "blocked", fg = "#ff9a9a" }, { equals = "working", fg = "#ffb454" }, { equals = "done", fg = "#7ee0a0" }, { equals = "idle", fg = "#98a2b1" }] }, { token = "$logo", bold = true, dim = false, rules = [{ equals = "✻", fg = "#e08a63" }, { equals = ">_", fg = "#e8ebf0" }, { equals = "✦", fg = "#7cc4ff" }, { contains = "", bold = false, dim = true }] }],
]
```

Then `herdr config check && herdr server reload-config`.

The `rules` on `state_text` give each state its own colour: blocked red, working orange, done green,
idle grey (stock Herdr shows idle in green). The hex values are the graphite theme's.

## 2. Headings ` SPACES ───── 4` / ` AGENTS ───── 5` (patched build)

Herdr hard-codes its section headings, so this is a source patch on v0.9.5. The same build carries the
tab-bar colours of part 3.
Needs Rust (pinned by the repo) and Zig 0.16.0.

```sh
cd ~/dev/herdr                       # a clone of herdrdev/herdr
git fetch origin --tags
git switch -c local/v0.9.5 v0.9.5
git am <this repo>/patches/herdr-v0.9.5-section-headings.patch \
       <this repo>/patches/herdr-v0.9.5-tab-bar-status-colours.patch
ZIG=/path/to/zig-0.16.0/zig cargo build --release --bin herdr
```

Put `target/release/herdr` first on `PATH`, then detach and start `herdr`
again. The headings are drawn by the client, so the server can keep running
as long as it is also 0.9.5.

## 3. Coloured tab-bar status (patched build)

Herdr removes colour codes from `tab_bar_right` command output. The second patch colours the text after
each status mark in the client instead: `×` red, `◐` orange, `✓` green, `○` grey; a `│` ends the colour.
So `lagom status` reads `◐ topic · working │ × 1 needs you  ✓ 2 done  ○ 7 idle` in four colours, taken
from the theme (`red`, `peach`, `green`, `overlay0`). Client-drawn like the headings: re-attach to see it.

Built and tested on Linux (WSL): 384 client-shell tests pass. The macOS build is untested.
