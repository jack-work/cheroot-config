# fish completion for figaro
function __figaro_dynamic
    set -l tokens (commandline -opc)
    if test (count $tokens) -lt 2
        return
    end
    set -l verb $tokens[2]
    set -l sentinel __bare_prompt
    if __figaro_is_bare_prompt
        set verb $sentinel
    end
    set -l cur (commandline -ct)
    set -l args
    if test (count $tokens) -gt 2
        set args $tokens[3..-1]
    end
    figaro __complete $verb --current "$cur" -- $args 2>/dev/null
end

# Bare-prompt detector: a "--" boundary ANYWHERE after the program name with a
# non-command in the verb slot. Mirrors cli.isBareForm (hasDashBoundary &&
# !isCommand(args[0])). It used to compare only the SECOND token against the
# boundary, which was right while the bare form took no flags; once
# 'figaro --id A -- <prompt>' became legal the boundary moved past word 2 and
# the detector silently stopped firing.
function __figaro_is_bare_prompt
    set -l tokens (commandline -opc)
    if test (count $tokens) -lt 2
        return 1
    end
    if not contains -- "--" $tokens[2..-1]
        return 1
    end
    if contains -- $tokens[2] help show history send qua new listen replay hup cut queue list ls attend at outfit study drop cast bind fork normalize export import promote kill state form set unset gc status info login models stop rest version v doctor vault hush update completion
        return 1
    end
    return 0
end
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a help -d 'Show help for figaro or one of its commands'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a show -d 'Render an aria\'s message history'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a send -d 'Send a prompt to an aria'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a new -d 'Start a fresh aria and prompt it'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a listen -d 'Attach to an aria\'s live stream without sending a prompt'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a replay -d 'Replay a recorded aria wire tape through the real renderer'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a hup -d 'Hang up: stop the turn, KEEP queued messages (-d discards them)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a cut -d 'Shorthand for `hup -d`: stop the turn, DISCARD queued messages (returned)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a queue -d 'Read, edit and delete the messages an aria has not answered yet'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a list -d 'List arias: scoped to where you\'re attended (attend is `cd`)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a attend -d 'Bind this shell to an existing aria (optionally at a turn)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a outfit -d 'Outfit lifecycle: reload flags the default form for recomputation'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a study -d 'Subscribe this figaro to an unbound form (see its changes)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a drop -d 'Unsubscribe this figaro from a studied form'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a cast -d 'Cast a figaro into a role (point target-aria here, and study it)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a bind -d 'Birth a figaro from an unbound form (dormant; never rebinds this shell)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a fork -d 'Branch a conversation: keep this id, mint an alternative'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a normalize -d 'Run deferred topology work now'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a export -d 'Write an aria to a portable file'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a import -d 'Restore an exported aria into this store'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a promote -d 'Make a trunk the canonical line through its ancestors'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a kill -d 'Terminate and remove a trunk'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a state -d 'Show the form, or shape it'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a set -d 'Patch a form key (no LLM round-trip)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a unset -d 'Remove form key(s)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a gc -d 'Collect outfit stumps nothing is using'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a status -d 'Show a focused view of one aria'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a login -d 'OAuth login for a provider'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a models -d 'List available provider models'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a stop -d 'Shut down the angelus daemon'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a version -d 'Print build identity (revision, exe path, Go version)'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a doctor -d 'Store maintenance: gc removes dead channels; schema reports channel versions; mem reports the daemon\'s footprint; skills lists what the binary ships'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a vault -d 'Inspect and repair figaro\'s embedded secrets vault'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a update -d 'Check for a newer figaro release'
complete -c figaro -n '__fish_use_subcommand; and not __figaro_is_bare_prompt' -a completion -d 'Generate or install a shell completion script'
complete -c figaro -n 'not __fish_use_subcommand' -a '(__figaro_dynamic)'
complete -c figaro -n '__fish_use_subcommand; and __figaro_is_bare_prompt' -a '(__figaro_dynamic)'
