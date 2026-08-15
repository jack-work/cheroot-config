# Editor: neovim and everything it shells out to.
#
# MUTABILITY RULE: ~/.config/nvim is NOT managed declaratively. lazy.nvim and
# mason write into it, and a /nix/store symlink is read-only. It is cloned once
# by the activation script below and left alone thereafter.
{
  flake.modules.homeManager.editor =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.packages =
        (with pkgs; [
          neovim

          # Formatters used by conform.nvim (formatters_by_ft in
          # lua/plugins/conform.lua). Without these, :w on a markdown/lua/python
          # file reports "no formatters". Small, pure, no shadowing risk.
          mdformat
          stylua
          black
          sql-formatter
        ])
        # Build deps: treesitter compiles parsers, mason fetches LSPs. mason's
        # prebuilt binaries work on Arch because it is FHS — they need
        # /lib64/ld-linux, which exists there and would NOT on NixOS.
        #
        # OPT-IN ONLY. ~/.nix-profile/bin precedes /usr/bin, so installing these
        # puts a second gcc/node/python ahead of the distro's for every native
        # build in the session. gluck already has gcc 16.2.1 and node 26.4 from
        # pacman and must not be shadowed by nixpkgs 15.3.0 / 24.18.
        # See modules/platform.nix.
        ++ lib.optionals config.my.platform.toolchainFromNix (
          with pkgs;
          [
            gcc
            gnumake
            tree-sitter
            nodejs
            python3
          ]
        );

      home.activation.cloneNvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -d "${config.home.homeDirectory}/.config/nvim/.git" ]; then
          run ${pkgs.git}/bin/git clone \
            https://github.com/jack-work/nvim-gluck \
            "${config.home.homeDirectory}/.config/nvim"
        else
          echo "nvim config already a git repo; leaving it alone"
        fi
      '';
    };
}
