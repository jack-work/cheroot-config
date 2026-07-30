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
    # GUARD: on hosts with no figaro daemon, `fig status` reaches for the hush
    # secrets vault, which BLOCKS prompting for a passphrase on a TTY. The
    # 2>/dev/null below swallows that prompt, so the shell just appears to hang
    # forever. Bail out unless the daemon runtime dir exists. (Cheap: no fork.)
    if not test -d /run/user/(id -u)/figaro
        set -gx FIGARO_PROMPT ""
        return
    end
    set -gx FIGARO_PROMPT (
        fig status --json 2>/dev/null |
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
