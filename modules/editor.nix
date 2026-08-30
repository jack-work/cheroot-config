# Editor: neovim and everything it shells out to.
#
# MUTABILITY RULE: ~/.config/nvim is NOT managed declaratively. lazy.nvim and
# mason write into it, and a /nix/store symlink is read-only. It is cloned once
# by the activation script below and left alone thereafter.
#
# TWO ARGUMENT LISTS, AND THE OUTER ONE IS NOT OPTIONAL HERE.
# `inputs` is a FLAKE-PARTS argument. The aspect below is a `deferredModule`
# evaluated by HOME-MANAGER's module system, which is never handed `inputs` —
# `mkHost` passes no `extraSpecialArgs`. Asking for it on the inner list fails
# with "attribute 'inputs' missing", so it is taken here, on the outer
# function, and closed over below. Same two-level split as shell/fish.nix,
# which documents the mirror-image trap for `config`.
#
# The alternative — threading `extraSpecialArgs = { inherit inputs; }` through
# mkHost — was rejected: it widens the argument surface of all two dozen
# aspects to serve one line in this file.
{ inputs, ... }:
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

          # Nix language tooling. nixd is the LSP that actually evaluates (unlike nil,
          # which cannot complete a single home-manager option); the .nvim.lua at this
          # repo's root points it at our own homeConfigurations. nixfmt is conform.nvim's
          # `nix` formatter — it was living in `nix profile` imperatively, which is the
          # exact drift this file exists to prevent.
          nixd
          nixfmt-rfc-style
          statix
          deadnix
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

      # nixd resolves `<nixpkgs>` from NIX_PATH when a project says nothing else.
      # Unset, it falls back to a channel this machine does not have. Pin it to the
      # same nixpkgs this generation was built from — one truth, not two.
      home.sessionVariables.NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
    };
}
