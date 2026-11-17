{ config, ... }:
{
  flake.modules.homeManager.bash = {
    home.file = config.flake.lib.linkDir ../../config/bash/bashrc.d ".bashrc.d";

    programs.bash = {
      initExtra = ''
        for rc in "$HOME"/.bashrc.d/*.sh; do
          [ -r "$rc" ] && . "$rc"
        done
        unset rc
      '';

      bashrcExtra = ''
        bind '"\e[A": history-search-backward' 2>/dev/null
        bind '"\e[B": history-search-forward'  2>/dev/null
        bind 'set completion-ignore-case on'   2>/dev/null
        bind 'set show-all-if-ambiguous on'    2>/dev/null
      '';
    };

    programs.fzf.enableBashIntegration = true;
  };
}
