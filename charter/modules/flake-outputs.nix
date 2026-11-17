{
  perSystem =
    { config, pkgs, ... }:
    {
      packages.mako-term = pkgs.callPackage ../pkgs/mako-term.nix { };
      packages.default = pkgs.callPackage ../pkgs/mako-term.nix { };

      formatter = pkgs.nixfmt-tree;

      devShells.default = pkgs.mkShell {
        packages = [
          config.formatter
          pkgs.home-manager
          pkgs.shellcheck
        ];
      };
    };
}
