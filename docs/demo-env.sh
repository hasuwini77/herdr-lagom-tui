# docs/demo-env.sh — sourced by the demo scripts. Puts the demo in a home of its own:
# no saved machines, no plugins, no sessions of yours. HERDR_BIN picks the Herdr binary.
state=$(cat /tmp/.lagom-demo-statedir)
for v in $(env | sed -n 's/^\(HERDR_[A-Z_]*\)=.*/\1/p' | grep -v '^HERDR_BIN$'); do unset "$v"; done
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
HOME="$state/home"; export HOME
HERDR_CONFIG_PATH="$state/config.toml"; export HERDR_CONFIG_PATH
SESSION=lagom-demo-tape
h() { "${HERDR_BIN:-herdr}" --session "$SESSION" "$@"; }
