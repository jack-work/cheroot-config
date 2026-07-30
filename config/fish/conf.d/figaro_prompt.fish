# Figaro prompt segment.
#
# Two traps, both discovered the hard way:
#
#  1. `figaro` resolves "which aria is bound to this shell" from its *immediate*
#     parent pid (internal/cli/target.go -> resolveBinding(os.Getppid()), and the
#     daemon's registry does an exact pid lookup, no ancestor walk). Starship
#     runs custom modules as `bash -c ...` and pipes inside that subshell, so a
#     `fig status` launched from there is parented by bash, not by the fish that
#     `figaro attend` actually bound — it reports "no figaro bound to this shell"
#     forever. Hence: fish asks, starship only echoes ($FIGARO_PROMPT).
#
#  2. For the same reason, do NOT wrap the call in `timeout` (or `env`, or any
#     other exec wrapper): the wrapper becomes the parent and the binding is
#     lost. fish forks each pipeline member itself, so `fig ... | jq ...` below
#     keeps fish as the parent. The call is a local unix-socket round trip
#     (~15ms); the cost of the lost guard is accepted knowingly.
#
# Output looks like:  8d81fd0c ● 63.4%
#   ● active (mid-turn)   ◐ idle (bound, waiting)   ○ dormant   ❄ frozen
function __figaro_prompt_refresh --on-event fish_prompt --description 'Refresh the figaro aria segment for starship'
    # GUARD 1: no fig on this host at all -> nothing to ask. (Cheap: builtin.)
    if not command -q fig
        set -gx FIGARO_PROMPT ""
        return
    end
    # GUARD 2: no daemon runtime dir -> nothing to ask. (Cheap: no fork.)
    if not test -d /run/user/(id -u)/figaro
        set -gx FIGARO_PROMPT ""
        return
    end
    # GUARD 3 (the important one): `fig status` unlocks the hush secrets vault.
    # On a host with no OS keyring (plain Arch, no gnome-keyring/KWallet —
    # i.e. cheroot) hush falls back to a passphrase prompt READ FROM THE
    # CONTROLLING TTY. The 2>/dev/null below hides the prompt text, so every
    # fish prompt silently swallowed a line of input: the shell looked dead
    # until you hit Enter, once per prompt, forever.
    #
    # GUARD 2 does not help — cheroot *does* have a running daemon, so the
    # runtime dir exists. The portable fix is to deny hush a terminal:
    # with stdin on /dev/null it cannot prompt, and errors out in ~15ms
    # ("requires a controlling terminal; none available"), which 2>/dev/null
    # discards. Where the vault unlocks without a TTY (keyring hosts, e.g.
    # the gluck desktop) the call still succeeds normally.
    #
    # NOTE: a redirection is safe here where an exec wrapper is not — fish
    # still forks the process itself, so the parent-pid binding of trap 2
    # above survives.
    set -gx FIGARO_PROMPT (
        fig status --json </dev/null 2>/dev/null |
        jq -r 'select(.id) | [
                 .id,
                 (if   .frozen          then "❄"
                  elif .state == "active" then "●"
                  elif .state == "idle"   then "◐"
                  else                         "○" end),
                 (if (.context_limit // 0) > 0
                  then "\((.context_tokens * 1000 / .context_limit | round) / 10)%"
                  else empty end)
               ] | join(" ")' 2>/dev/null
    )
end
