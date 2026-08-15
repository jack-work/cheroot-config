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
      home.packages = with pkgs; [
        neovim

        # Build deps: treesitter compiles parsers, mason fetches LSPs.
        # mason's prebuilt binaries work here because Arch is FHS — they need
        # /lib64/ld-linux, which exists on Arch and would NOT on NixOS.
        gcc
        gnumake
        tree-sitter
        nodejs
        python3

        # Formatters used by conform.nvim (formatters_by_ft in
        # lua/plugins/conform.lua). Without these, :w on a markdown/lua/python
        # file reports "no formatters".
        mdformat
        stylua
        black
        sql-formatter
      ];

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
