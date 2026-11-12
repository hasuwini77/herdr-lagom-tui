# docs/demo-env.sh — sourced by the demo scripts. Puts the demo in a home of its own:
# no saved machines, no plugins, no sessions of yours. HERDR_BIN picks the Herdr binary.
state=$(cat /tmp/.lagom-demo-statedir)
for v in $(env | sed -n 's/^\(HERDR_[A-Z_]*\)=.*/\1/p' | grep -vE '^HERDR_(BIN|SPINNER_NODE)$'); do unset "$v"; done
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
HOME="$state/home"; export HOME
XDG_RUNTIME_DIR="$state/run"; export XDG_RUNTIME_DIR
HERDR_CONFIG_PATH="$state/config.toml"; export HERDR_CONFIG_PATH
PATH="$state/bin:$PATH"; export PATH       # `herdr` here is the binary the demo runs
h() { "$state/bin/herdr" "$@"; }
# "done" only shows once a client is attached: say working, then idle, again.
mark_done() { sleep 3; while read -r pane agent; do h pane report-agent "$pane" --source demo --agent "$agent" --state working; done < "$state/done"; sleep 1
              while read -r pane agent; do h pane report-agent "$pane" --source demo --agent "$agent" --state idle; done < "$state/done"; }
