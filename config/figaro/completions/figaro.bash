# bash completion for figaro
_figaro_completions() {
    COMPREPLY=()
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local verb="${COMP_WORDS[1]}"
    local sentinel="__bare_prompt"
    local commands="help show history send qua new listen replay hup cut queue list ls attend at outfit study drop cast bind fork normalize export import promote kill state form set unset gc status info login models stop rest version v doctor vault hush update completion"
    local bare=0 w
    for w in "${COMP_WORDS[@]:1}"; do
        if [ "$w" = "--" ]; then bare=1; break; fi
    done
    if [ "$bare" -eq 1 ]; then
        case " $commands " in *" $verb "*) bare=0 ;; esac
    fi
    if [ "$bare" -eq 0 ] && [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return
    fi
    if [ "$bare" -eq 1 ]; then
        verb="$sentinel"
    fi
    local count=$((COMP_CWORD - 2))
    local args=()
    if [ "$count" -gt 0 ]; then
        args=("${COMP_WORDS[@]:2:$count}")
    fi
    local candidates
    candidates=$(figaro __complete "$verb" --current "$cur" -- "${args[@]}" 2>/dev/null)
    if [ -n "$candidates" ]; then
        COMPREPLY=($(compgen -W "$candidates" -- "$cur"))
    fi
}
complete -F _figaro_completions figaro
