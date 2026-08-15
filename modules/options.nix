# Declare `flake.homeConfigurations` as a MERGEABLE option.
#
# flake-parts does not ship a declaration for this output. Without one, the
# module system treats it as a single unique value, and the moment a second
# host defines it you get:
#
#   error: The option `flake.homeConfigurations' is defined multiple times
#
# which is fatal to the whole pattern — the entire point is that each host file
# contributes its own entry independently. Declaring it as `lazyAttrsOf raw`
# makes the definitions merge by attribute name instead of conflicting.
#
# `raw` rather than `unspecified`: a homeConfiguration is an already-evaluated
# attrset containing functions and derivations; the module system must not try
# to recurse into it.
{ lib, ... }:
{
  # The option the entire dendritic pattern rests on.
  #
  #   flake.modules.<class>.<aspect>
  #
  # `deferredModule` is what makes an aspect a NAME rather than a FILE: ten
  # different files may all write `flake.modules.homeManager.shell`, and the
  # module system collects them into one module instead of complaining that the
  # value is defined twice. A host then composes aspects by naming them.
  #
  # Without this declaration the second file to touch `flake.modules` fails with
  # "defined multiple times while it's expected to be unique".
  options.flake.modules = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.deferredModule);
    default = { };
    description = "Aspects, grouped by module class (homeManager, nixos, ...).";
  };

  options.flake.homeConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "home-manager configurations, one per user@host.";
  };

  # Same story as the two above. Once helpers live in more than one file —
  # lib.nix contributes linkDir, host-builder.nix contributes mkHost — an
  # undeclared `flake.lib` collides. Declaring it lets each file add its own
  # helpers without knowing what the others provide.
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Helpers shared across modules, reachable as config.flake.lib.*";
  };

  # Declared for the same reason as homeConfigurations, so that NixOS hosts can
  # each contribute one. Empty until a NixOS machine exists — declaring the
  # option costs nothing and means the first one is a new file rather than a
  # refactor. See modules/system/packages.nix for the `nixos` module class.
  options.flake.nixosConfigurations = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "NixOS system configurations, one per host.";
  };
}
