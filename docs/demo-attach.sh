#!/bin/sh
# docs/demo-attach.sh — opens the demo session in this terminal. Run demo-setup.sh first.
# For a picture with the wallpaper, run it in a WezTerm or Windows Terminal window themed by lagom.
set -eu
here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
. "$here/demo-env.sh"
( mark_done ) >/dev/null 2>&1 &
exec "$state/bin/herdr"
