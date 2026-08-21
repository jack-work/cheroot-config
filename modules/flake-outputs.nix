# Packages, the formatter, and the dev shell, exposed per-system.
{
  perSystem =
    { config, pkgs, ... }:
    {
      packages.mako-term = pkgs.callPackage ../pkgs/mako-term.nix { };
      packages.default = pkgs.callPackage ../pkgs/mako-term.nix { };

      # `nix fmt`. Without this output the command fails outright:
      #   error: flake ... does not provide attribute 'formatter.x86_64-linux'
      # even though the formatter was sitting in the dev shell all along — being
      # installed and being the declared formatter are two different things.
      #
      # nixfmt-tree, not bare nixfmt: `nix fmt` with no arguments passes `.`,
      # and plain nixfmt now deprecates directory arguments —
      #   "Passing directories or non-Nix files (such as ".") is deprecated"
      # so the obvious spelling warns on the most obvious invocation. The wrapper
      # is treefmt driving the same nixfmt, and it walks the tree properly:
      # respecting .gitignore, formatting in parallel, and leaving non-Nix files
      # alone. `nix fmt -- --check` still works for CI.
      formatter = pkgs.nixfmt-tree;

      devShells.default = pkgs.mkShell {
        packages = [
          # The same derivation `nix fmt` uses, so the shell and the flake
          # output can never disagree about which formatter this repo means.
          config.formatter
          pkgs.home-manager
          pkgs.shellcheck
        ];
      };
    };
}
