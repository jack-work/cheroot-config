# Interactive command-line tooling.
#
# Every integration below enables BOTH shells from a single `enable`, which is
# most of what "share the same nix props between fish and bash" means in
# practice. The one exception is fzf's fish integration, switched off in
# shell/fish.nix because the vendored fzf.fish plugin already owns those keys.
{
  flake.modules.homeManager.cli =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ripgrep
        fd
        jq
        eza
        bat
        delta
        lazygit
        yazi
        tree
        git
        gh
      ];

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        # enableFishIntegration is forced off in shell/fish.nix.
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;
      };
    };
}
