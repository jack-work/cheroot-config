{
  flake.modules.homeManager.zig =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        zig
        zls
        zon2nix
      ];
    };
}
