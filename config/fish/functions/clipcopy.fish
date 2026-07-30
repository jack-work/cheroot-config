function clipcopy --description "Copy stdin or arguments to clipboard via OSC 52 (works over SSH/tmux)"
    set -l encoded
    if test (count $argv) -gt 0
        set encoded (printf '%s' $argv | base64 -w0)
    else if not isatty stdin
        set encoded (base64 -w0)
    else
        echo "Usage: echo text | clipcopy  OR  clipcopy 'text'" >&2
        return 1
    end

    # Write to the TTY so the terminal (not a pipe/redirect) sees the escape
    printf "\e]52;c;%s\a" $encoded > /dev/tty
end
