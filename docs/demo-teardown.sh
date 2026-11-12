#!/bin/sh
# docs/demo-teardown.sh — stops the session demo-setup.sh made and removes its temp folder.
set -eu
[ -f /tmp/.lagom-demo-statedir ] || exit 0
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$here/demo-env.sh"
[ -d "$state/spinner" ] && sh "$state/spinner/run.sh" --stop >/dev/null 2>&1 || true
h server stop >/dev/null 2>&1 || true
case "$state" in /tmp/*) rm -rf "$state" ;; esac
rm -f /tmp/.lagom-demo-statedir
