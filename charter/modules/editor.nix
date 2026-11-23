{ inputs, ... }:
{
  flake.modules.nixos.editor = {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  flake.modules.homeManager.editor =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.my.editor = {
        nvimRepoUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        nixosLanguageServers = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = with pkgs; [
            gopls
            pyright
            lua-language-server
            bash-language-server
          ];
        };
      };

      config = {
        home.packages =
          (with pkgs; [
            neovim
            mdformat
            stylua
            black
            sql-formatter
            nixd
            nixfmt-rfc-style
            statix
            deadnix
          ])
          ++ lib.optionals config.my.platform.toolchainFromNix (
            with pkgs;
            [
              gcc
              gnumake
              tree-sitter
              nodejs
              python3
            ]
          )
          ++ lib.optionals (!config.my.platform.fhsMason) config.my.editor.nixosLanguageServers;

        home.activation.cloneNvim = lib.mkIf (config.my.editor.nvimRepoUrl != null) (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ ! -d "${config.home.homeDirectory}/.config/nvim/.git" ]; then
              run ${pkgs.git}/bin/git clone \
                ${lib.escapeShellArg config.my.editor.nvimRepoUrl} \
                "${config.home.homeDirectory}/.config/nvim"
            else
              echo "nvim config already a git repo; leaving it alone"
            fi
          ''
        );

        home.sessionVariables.NIX_PATH = "nixpkgs=${inputs.nixpkgs}";

        systemd.user.sessionVariables.NIX_PATH = "nixpkgs=${inputs.nixpkgs}";
      };
    };
}
