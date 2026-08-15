# $FIGARO_PROMPT for starship's [custom.figaro] module — bash edition.
#
# ---------------------------------------------------------------------------
# READ THIS BEFORE "TIDYING" THE COMMAND SUBSTITUTION BELOW.
# ---------------------------------------------------------------------------
# figaro resolves "which aria is bound to this shell" from its IMMEDIATE PARENT
# PID (internal/cli/target.go -> resolveBinding(os.Getppid()); the daemon does an
# exact pid lookup, with no ancestor walk). So whatever runs `fig` must be the
# interactive shell itself.
#
# fish forks every pipeline member itself, so the fish version of this file can
# write `fig status --json </dev/null 2>/dev/null | jq ...` and keep its binding.
# BASH CANNOT. Measured on this machine, with a fake `fig` reporting its $PPID:
#
#     fig ... | jq ...                  ppid = bash       OK   (top-level pipeline)
#     raw=$(fig ...)                    ppid = bash       OK
#     raw=$(fig ... | jq ...)           ppid = subshell   BROKEN
#     raw=$(fig ... 2>/dev/null)        ppid = subshell   BROKEN
#     raw=$(fig ... </dev/null)         ppid = subshell   BROKEN
#     { raw=$(fig ...); } </dev/null    ppid = bash       OK   (what we do)
#
# The precise rule — narrower than "pipes and redirects are bad", and worth
# stating exactly because the wrong version invites the wrong fix:
#
#   A TOP-LEVEL pipeline is fine. Bash forks each pipeline member directly from
#   the shell, so `fig | jq` keeps bash as fig's parent.
#
#   A COMMAND SUBSTITUTION is only safe when it contains a LONE SIMPLE COMMAND.
#   Bash then skips the fork and execs in the substitution's own process, whose
#   parent is the shell. Add a pipe or ANY redirection and that optimisation is
#   defeated: bash forks a subshell first, and fig's parent becomes the subshell.
#
# The failure is silent: the segment just reads "no figaro bound to this shell"
# forever.
#
# Yet stdin MUST be /dev/null (trap 2 below), so the two requirements look
# contradictory. They are not: redirect a BRACE GROUP, which does not fork,
# keep the `fig` call a bare simple substitution, and run jq as a separate step.
#
# Other traps, all learned the hard way:
#   1. Do NOT wrap the call in `timeout`, `env`, or any other exec wrapper — the
#      wrapper becomes the parent and the binding is lost. A redirection is not
#      an exec wrapper, which is why the brace group is safe.
#   2. stdin MUST be /dev/null. When figaro's hush vault is locked (agent TTL
#      expired, fresh identity, or a host with no OS keyring) hush sees a TTY on
#      stdin and blocks the prompt render reading a passphrase — silently eating
#      a line of input in EVERY window that draws a prompt. Denied a terminal it
#      fails fast (~15ms) instead.
#
# Output looks like:  8d81fd0c ● 63.4%
#   ● active (mid-turn)   ◐ idle (bound, waiting)   ○ dormant   ❄ frozen

__figaro_prompt_refresh() {
    FIGARO_PROMPT=""
    export FIGARO_PROMPT

    # GUARD 1: no fig on this host at all. Cheap: builtin, no fork.
    command -v fig >/dev/null 2>&1 || return 0

    # GUARD 2: no daemon runtime dir -> nothing to ask. Cheap: no fork.
    [ -d "/run/user/${UID}/figaro" ] || return 0

    # GUARD 3: the fork-safe call. See the essay above.
    local raw
    { raw=$(fig status --json); } </dev/null 2>/dev/null
    [ -n "$raw" ] || return 0

    # jq runs as a SEPARATE step. Piping fig into jq directly would fork.
    FIGARO_PROMPT=$(
        printf '%s' "$raw" | jq -r 'select(.id) | [
                 .id,
                 (if   .frozen            then "❄"
                  elif .state == "active" then "●"
                  elif .state == "idle"   then "◐"
                  else                         "○" end),
                 (if (.context_limit // 0) > 0
                  then "\((.context_tokens * 1000 / .context_limit | round) / 10)%"
                  else empty end)
               ] | join(" ")' 2>/dev/null
    )
}

# Hook it so it runs BEFORE the prompt renders.
#
# starship_precmd_user_func is starship's documented extension point, invoked
# near the top of starship_precmd and well before PS1 is computed. It is a plain
# function call in the current shell, so the parent-pid binding survives.
# Order-independent: starship reads the variable at prompt time, so this file may
# be sourced before or after `starship init bash`.
if command -v starship >/dev/null 2>&1; then
    # shellcheck disable=SC2034  # read by starship_precmd, not by this file
    starship_precmd_user_func=__figaro_prompt_refresh
else
    case "${PROMPT_COMMAND:-}" in
        *__figaro_prompt_refresh*) ;;
        *) PROMPT_COMMAND="__figaro_prompt_refresh${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
    esac
fi
