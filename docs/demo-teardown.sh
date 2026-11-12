#!/bin/sh
# docs/demo-teardown.sh — stops the session demo-setup.sh made and removes its temp folder.
set -eu
[ -f /tmp/.lagom-demo-statedir ] || exit 0
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$here/demo-env.sh"
"${HERDR_BIN:-herdr}" session stop "$SESSION" >/dev/null 2>&1 || true
case "$state" in /tmp/*) rm -rf "$state" ;; esac
rm -f /tmp/.lagom-demo-statedir
