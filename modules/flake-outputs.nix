# Packages and the dev shell, exposed per-system.
{
  perSystem =
    { pkgs, ... }:
    {
      packages.mako-term = pkgs.callPackage ../pkgs/mako-term.nix { };
      packages.default = pkgs.callPackage ../pkgs/mako-term.nix { };

      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          home-manager
          nixfmt-rfc-style
          shellcheck
        ];
      };
    };
}
