{
  flake.modules.homeManager.fonts =
    { pkgs, ... }:
    {
      fonts.fontconfig.enable = true;

      home.packages = with pkgs; [
        nerd-fonts.go-mono
        nerd-fonts.monaspace
        sarasa-gothic
      ];
    };
}
