# Shared helpers, exposed on the flake so any module can reach them as
# `config.flake.lib.<name>`.
#
# NOTE: the helper source lives in ../lib, NOT under ./modules — import-tree
# imports every .nix file beneath ./modules as a flake-parts module, and a bare
# helper function is not a module.
{ lib, ... }:
{
  flake.lib = {
    linkDir = import ../lib/link-dir.nix lib;
  };
}
