let
  cliPackages =
    pkgs: with pkgs; [
      ripgrep
      fd
      jq
      eza
      bat
      gitui
      lazygit
      yazi
      tree
      gh
    ];
in
{
  flake.modules.nixos.cli =
    { pkgs, ... }:
    {
      environment.systemPackages = cliPackages pkgs;
    };

  flake.modules.homeManager.cli =
    { pkgs, ... }:
    {
      home.packages = cliPackages pkgs;

      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
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
