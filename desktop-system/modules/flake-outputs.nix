{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    {
      packages.mako-term = inputs.charter.packages.${system}.mako-term;
      packages.default = inputs.charter.packages.${system}.default;

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
