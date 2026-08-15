# CachyOS distribution defaults: ~40 aliases (eza/pacman/journalctl), the
# fastfetch greeting, MANPAGER, the `done` long-command notifier, and the
# !!/!$ history bindings.
#
# Guarded by a file test: this path is CachyOS-only and absent on plain Arch
# (cheroot). Sourcing it unguarded is what broke the config on the laptop.
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end
