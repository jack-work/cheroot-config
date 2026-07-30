# Homebrew environment (adds /opt/brew/bin + /opt/brew/sbin to PATH, sets MANPATH/INFOPATH)
if test -x /opt/brew/bin/brew
    /opt/brew/bin/brew shellenv fish | source
end
