# Distro-flavour aliases.
#
# fish gets these by sourcing /usr/share/cachyos-fish-config/cachyos-config.fish.
# There is no bash equivalent shipped, so the useful subset is transcribed here.
# Guarded on the tools existing, because cheroot is plain Arch, not CachyOS.

if command -v eza >/dev/null 2>&1; then
    alias ls='eza -al --color=always --group-directories-first --icons=always'
    alias la='eza -a  --color=always --group-directories-first --icons=always'
    alias ll='eza -l  --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
    alias l.="eza -a | grep -e '^\.'"
else
    alias ls='ls --color=auto'
fi

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias jctl="journalctl -p 3 -xb"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '

# Arch/pacman helpers. `update` differs per distro: CachyOS rates mirrors first.
if command -v pacman >/dev/null 2>&1; then
    alias fixpacman="sudo rm /var/lib/pacman/db.lck"
    alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
    alias cleanup='sudo pacman -Rns $(pacman -Qtdq)'
    alias apt='man pacman'
    alias apt-get='man pacman'
    if command -v cachyos-rate-mirrors >/dev/null 2>&1; then
        alias update='sudo cachyos-rate-mirrors && sudo pacman -Syu'
        alias mirror="sudo cachyos-rate-mirrors"
    else
        alias update='sudo pacman -Syu'
    fi
fi

if command -v expac >/dev/null 2>&1; then
    alias big="expac -H M '%m\t%n' | sort -h | nl"
    alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"
fi

if command -v hwinfo >/dev/null 2>&1; then
    alias hw='hwinfo --short'
fi
