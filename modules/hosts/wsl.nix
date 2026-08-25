# wsl — the Windows box's Linux userland.
#
# THE HOSTNAME IS THE CONTRACT. home-manager resolves a bare `--flake .` by
# probing `$USER@$(hostname -f)`, `$USER@$(hostname)`, `$USER@$(hostname -s)`.
# WSL defaults the hostname to the WINDOWS machine name — often mixed-case,
# sometimes with characters that make a poor attribute name, and it changes if
# you rename the PC. Rather than guess it here, name the machine to match the
# config. Inside WSL:
#
#     sudo tee /etc/wsl.conf >/dev/null <<'EOF'
#     [network]
#     hostname = wsl
#     generateHosts = true
#     EOF
#
# then `wsl --shutdown` from PowerShell and reopen. `hostname` now reads `wsl`,
# and `home-manager switch --flake .` resolves this file with no argument.
#
# (Prefer the real name? Rename the `host` string below and the attribute
# follows — that is all `mkHost` is doing.)
#
# WHAT THIS MACHINE TAKES: coreAspects — bash, fish, the prompt, cli tools,
# git, go, neovim + its formatters, tmux, figaro. What it does NOT take: every
# GUI aspect, by simply not naming them. niri, waybar, mako, rofi, alacritty
# and fonts are not disabled here; they are never evaluated.
{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "gluck";
    host = "wsl";

    aspects = config.flake.lib.coreAspects;
    roles = [ "wsl" ];
  };
}
