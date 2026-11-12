#!/bin/sh
# docs/demo-serve.sh [theme] [port] — shows the demo session in a browser tab, for a clean picture.
# Run demo-setup.sh first. Open http://127.0.0.1:<port>, take the picture (docs/preview.png),
# then stop this and run demo-teardown.sh. Requires: ttyd.
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
theme=${1:-graphite}
colours=$(python3 - "$here/../themes/lagom-$theme.json" <<'PY'
import json, sys
t = json.load(open(sys.argv[1])); a = t["ansi"]
names = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
out = {"background": t["background"], "foreground": t["foreground"], "cursor": t["cursor"], "selectionBackground": t["selection"]}
out.update({n: a[i] for i, n in enumerate(names)})
out.update({"bright" + n.capitalize(): a[i + 8] for i, n in enumerate(names)})
print(json.dumps(out))
PY
)
. "$here/demo-env.sh"
( mark_done ) >/dev/null 2>&1 &
exec ttyd -p "${2:-7689}" -i 127.0.0.1 -W -t fontSize=14 -t "fontFamily=FiraCode Nerd Font, JetBrains Mono, monospace" \
  -t "theme=$colours" -t disableLeaveAlert=true -t titleFixed=lagom \
  "$state/bin/herdr"
