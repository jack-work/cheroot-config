# Homebrew (adds /opt/brew/{bin,sbin} to PATH, sets MANPATH/INFOPATH).
# Runs BEFORE 30-path.sh so the user's own paths end up ahead of brew's.
#
# THE GUARD IS NOT OPTIONAL. Homebrew's shellenv is asymmetric between shells:
#
#   fish:  fish_add_path --global --move --path /opt/brew/bin /opt/brew/sbin
#   bash:  export PATH="/opt/brew/bin:/opt/brew/sbin${PATH+:$PATH}"
#
# The fish form deduplicates and the bash form does not, so under bash every
# nested shell added another two entries (measured: 9 -> 11 -> 13 ...). INFOPATH
# grew the same way. Running shellenv only when it has not already been applied
# makes it idempotent, which is what 30-path.sh's path_prepend achieves for
# everything else.
if [ -x /opt/brew/bin/brew ]; then
    case ":$PATH:" in
        *":/opt/brew/bin:"*) : ;; # already applied in an ancestor shell
        *) eval "$(/opt/brew/bin/brew shellenv)" ;;
    esac
fi
