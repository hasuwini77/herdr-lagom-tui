#!/bin/sh
# docs/demo-setup.sh [theme] — builds the throwaway Herdr session the README pictures are taken from.
#
# It runs in a home folder of its own (demo-env.sh): it cannot see or change your real session,
# machines or plugins. Workspaces are empty git folders with invented names under a temp
# directory; the panes are stand-ins (demo-pane.sh), no real agent runs.
#
#   HERDR_BIN=<path>             another Herdr binary (a stock release, or a patched build)
#   LAGOM_DEMO_FULL=1            the whole look: see-through sidebar for a wallpaper, one-row agents
#                                with spinner, state colours and logo, the status in the tab bar
#   LAGOM_DEMO_SPINNER=<folder>  a checkout of the hasuwini77.spinner plugin, for the full look
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH='' cd -- "$here/.." && pwd)
theme=${1:-graphite}
full=${LAGOM_DEMO_FULL:-}
bin=$(command -v "${HERDR_BIN:-herdr}")

state=$(mktemp -d)
echo "$state" > /tmp/.lagom-demo-statedir
mkdir -p "$state/home" "$state/run" "$state/bin"
: > "$state/home/.zshrc"; : > "$state/home/.bashrc"
ln -s "$bin" "$state/bin/herdr"
. "$here/demo-env.sh"

# The same [theme] block `lagom theme` writes, without touching your config.
python3 - "$root" "$theme" "$full" > "$HERDR_CONFIG_PATH" <<'PY'
import json, sys
from importlib.machinery import SourceFileLoader
from pathlib import Path
root, theme, full = Path(sys.argv[1]), sys.argv[2], sys.argv[3] == "1"
sys.dont_write_bytecode = True
lagom = SourceFileLoader("lagom", str(root / "bin/lagom")).load_module()
t = json.loads((root / f"themes/lagom-{theme}.json").read_text())
c = t["colors"]
print("onboarding = false\n\n[ui]\nshow_agent_labels_on_pane_borders = true")
if full:
    print('status_indicators = "symbols"\nsidebar_width = 34')
    print(f'tab_bar_right = [{{ type = "command", command = "{root}/bin/lagom status", interval_seconds = 3, timeout_seconds = 2 }}]')
    state = ", ".join(f'{{ equals = "{k}", fg = "{c[k]}" }}' for k in ("blocked", "working", "done", "idle"))
    logo = '{ equals = "✻", fg = "#e08a63" }, { equals = ">_", fg = "%s" }, { equals = "✦", fg = "%s" }, { contains = "", bold = false, dim = true }' % (c["foreground"], c["accent"])
    print("\n[ui.sidebar.agents]\nrows = [\n  [{ token = \"$spin\", fg = \"%s\", dim = false, bold = true }, { token = \"workspace\", bold = false }, "
          "{ token = \"state_text\", bold = false, dim = false, rules = [%s] }, { token = \"$logo\", bold = true, dim = false, rules = [%s] }],\n]" % (c["working"], state, logo))
print()
print(lagom.herdr_block(t, full))
PY

if [ -n "${LAGOM_DEMO_SPINNER:-}" ]; then   # a copy: the plugin stops any other daemon started from its own folder
  cp -R "$LAGOM_DEMO_SPINNER" "$state/spinner"; rm -rf "$state/spinner/.git"
  h plugin link "$state/spinner" >/dev/null
fi

"$state/bin/herdr" server > "$state/server.log" 2>&1 &   # not through h(): a function would keep our stdout open
sleep 2

ids() { h api snapshot | python3 -c 'import json,sys; print(" ".join(p["pane_id"] for p in json.load(sys.stdin)["result"]["snapshot"]["panes"]))'; }

for w in recipe-api:feat/csv-import photo-sync:fix/duplicate-dates trail-maps:main budget-cli:feat/monthly-report garden-log:main chess-clock:feat/sound; do
  dir="$state/${w%%:*}"
  git init -q -b "${w#*:}" "$dir"
  git -C "$dir" -c user.name=demo -c user.email=demo@example.invalid commit -q --allow-empty -m start
  h workspace create --cwd "$dir" --label "${w%%:*}" --env "PS1=\$ " --no-focus >/dev/null
done
sleep 1
set -- $(ids)                      # one pane per workspace, in order
h pane split "$1" --direction right >/dev/null
sleep 1
side=$(ids | tr ' ' '\n' | grep "^${1%%:*}:" | grep -v "^$1\$")

# run <pane> <stand-in> <agent> <state> <title>; "done" is working that ended while you looked elsewhere
run() {
  topic=${5#* · }; [ "$topic" = "$5" ] && topic=
  h pane run "$1" "sh $here/demo-pane.sh $2 '$topic'" >/dev/null
  [ "$4" = done ] && echo "$1 $3" >> "$state/done" && h pane report-agent "$1" --source demo --agent "$3" --state working >/dev/null
  h pane report-agent "$1" --source demo --agent "$3" --state "$( [ "$4" = done ] && echo idle || echo "$4")" >/dev/null
  h pane report-metadata "$1" --source lagom --display-agent "$5" >/dev/null 2>&1 || true
}
run "$1" lead claude working "recipe-api · CSV import"
run "$side" tests claude working "recipe-api · Test run"
run "$2" ask claude blocked "photo-sync · Duplicate dates"
run "$3" idle codex idle "trail-maps · Tile cache"
run "$4" tests claude done "budget-cli · Monthly report"
run "$5" idle opencode idle "garden-log"
run "$6" tests claude done "chess-clock · Sound"
: >> "$state/done"
h pane focus "$1" >/dev/null 2>&1 || true
echo "ready: sh $here/demo-attach.sh (any terminal) or sh $here/demo-serve.sh $theme (browser tab)"
