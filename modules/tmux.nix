# tmux.
#
# MUTABILITY RULE: only tmux.conf is managed. ~/.config/tmux/plugins stays a
# real directory because tpm clones into it.
#
# tmux.conf is shell-agnostic and sets neither default-shell nor
# default-command, so tmux follows the login shell from /etc/passwd. That is why
# switching between fish and bash needs no tmux change at all.
{
  flake.modules.homeManager.tmux =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.packages = [ pkgs.tmux ];

      xdg.configFile."tmux/tmux.conf".source = ../config/tmux/tmux.conf;

      home.activation.cloneTpm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d "${config.home.homeDirectory}/.config/tmux/plugins/tpm" ]; then
          run ${pkgs.git}/bin/git clone \
            https://github.com/tmux-plugins/tpm \
            "${config.home.homeDirectory}/.config/tmux/plugins/tpm"
        fi
      '';
    };
}
