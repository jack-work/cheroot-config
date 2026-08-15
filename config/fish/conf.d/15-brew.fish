# Homebrew (adds /opt/brew/{bin,sbin} to PATH, sets MANPATH/INFOPATH).
# Runs BEFORE 30-path.fish so the user's own paths end up ahead of brew's.
if test -x /opt/brew/bin/brew
    /opt/brew/bin/brew shellenv fish | source
end
