# bash rendering.
#
# Mirrors the fish layout deliberately: home-manager owns ~/.bashrc, and our
# configuration lives in numbered ~/.bashrc.d/*.sh modules with the SAME numbers
# as fish's conf.d, so the two are readable side by side.
#
#   10-env  15-brew  20-distro  30-path  50-conda  65-figaro-prompt
#
# bash has no native conf.d, so initExtra sources the directory.
{ config, ... }:
{
  flake.modules.homeManager.bash = {
    home.file = config.flake.lib.linkDir ../../config/bash/bashrc.d ".bashrc.d";

    programs.bash = {
      # home-manager's programs.bash.enableCompletion (on by default) already
      # installs the bash-completion package and sources it — which is the
      # proper fix for the cheroot bug where bash-completion was simply never
      # installed and /etc/bash.bashrc's guard failed silently. bash-completion
      # then autoloads from ~/.local/share/bash-completion/completions, where
      # modules/figaro.nix puts the figaro and fig scripts. Nothing to do here.
      initExtra = ''
        for rc in "$HOME"/.bashrc.d/*.sh; do
          [ -r "$rc" ] && . "$rc"
        done
        unset rc
      '';

      # Recovers the interactive feel people actually miss when leaving fish:
      # type a prefix, press Up, get matching history.
      bashrcExtra = ''
        bind '"\e[A": history-search-backward' 2>/dev/null
        bind '"\e[B": history-search-forward'  2>/dev/null
        bind 'set completion-ignore-case on'   2>/dev/null
        bind 'set show-all-if-ambiguous on'    2>/dev/null
      '';
    };

    # bash gets fzf's stock bindings (Ctrl-T files, Ctrl-R history, Alt-C cd).
    # fzf.fish's richer searchers are fish-only and cannot be shared.
    programs.fzf.enableBashIntegration = true;
  };
}
