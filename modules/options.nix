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

  # `flake.nixosConfigurations` is deliberately NOT declared here.
  #
  # flake-parts ships modules/nixosConfigurations.nix, which already declares it
  # as `lazyAttrsOf raw` with `default = {}` — identical to what we would write.
  # Redeclaring it is not a harmless duplicate: two declarations of one option
  # is an error, and it surfaced only under `nix flake check`, because that is
  # the one command that evaluates the nixosConfigurations output.
  #
  #   error: The option `flake.nixosConfigurations' in
  #   `.../modules/nixosConfigurations.nix' is already declared in
  #   `.../modules/options.nix'.
  #
  # `homeConfigurations` above still needs our declaration — home-manager is not
  # a flake-parts module and ships no equivalent. The rule: declare a `flake.*`
  # option only after checking flake-parts does not already own it.
}
