{
  flake.modules.nixos.tmux =
    { pkgs, ... }:
    {
      programs.tmux.enable = true;
      environment.systemPackages = [ pkgs.sesh ];
    };

  flake.modules.homeManager.tmux =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.packages = [
        pkgs.tmux
        pkgs.sesh
      ];

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
