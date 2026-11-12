#!/bin/sh
# docs/demo-setup.sh [theme] — builds the throwaway Herdr session that docs/demo.tape records.
#
# A session in a home folder of its own (demo-env.sh): it cannot see or change your real
# session, machines or plugins. HERDR_BIN=<path> records with another Herdr binary. Workspaces are empty git folders under a temp directory with invented
# names; the panes are stand-ins (demo-pane.sh), no real agent runs.
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH='' cd -- "$here/.." && pwd)
theme=${1:-graphite}

state=$(mktemp -d)
echo "$state" > /tmp/.lagom-demo-statedir
mkdir -p "$state/home"
: > "$state/home/.zshrc"; : > "$state/home/.bashrc"
. "$here/demo-env.sh"
CFG=$HERDR_CONFIG_PATH

# The same [theme] block `lagom theme` writes, without touching your config.
python3 - "$root" "$theme" > "$CFG" <<'PY'
import json, sys
from importlib.machinery import SourceFileLoader
from pathlib import Path
root, theme = Path(sys.argv[1]), sys.argv[2]
sys.dont_write_bytecode = True
lagom = SourceFileLoader("lagom", str(root / "bin/lagom")).load_module()
print(lagom.herdr_block(json.loads((root / f"themes/lagom-{theme}.json").read_text()), False))
print("[ui]\nshow_agent_labels_on_pane_borders = true")
PY

"${HERDR_BIN:-herdr}" --session "$SESSION" server > "$state/server.log" 2>&1 &   # not through h(): a function would keep our stdout open
sleep 2

ids() { h api snapshot | python3 -c 'import json,sys; print(" ".join(p["pane_id"] for p in json.load(sys.stdin)["result"]["snapshot"]["panes"]))'; }

for w in recipe-api:feat/csv-import photo-sync:fix/duplicate-dates trail-maps:main budget-cli:feat/monthly-report; do
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

run() { h pane run "$1" "sh $here/demo-pane.sh $2" >/dev/null; h pane report-agent "$1" --source demo --agent "$3" --state "$4" >/dev/null; }
run "$1" lead claude working
run "$side" tests claude working
run "$2" ask claude blocked
run "$3" idle codex idle
run "$4" tests claude working
h pane focus "$1" >/dev/null 2>&1 || true
echo "ready: sh $here/demo-serve.sh $theme"
