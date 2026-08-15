# Link every regular file in `dir` individually, rather than symlinking the
# directory itself.
#
# WHY THIS EXISTS (the bug it fixes):
# `xdg.configFile."fish/conf.d".source = ./conf.d` makes ~/.config/fish/conf.d a
# symlink to a /nix/store path, and store paths are READ-ONLY. fish 4.3 writes
# `fish_frozen_theme.fish` and `fish_frozen_key_bindings.fish` *into* conf.d
# during its migration, and `fish_config` writes there when you save a theme.
# Against a store symlink those writes fail. The same trap applies to any
# directory a program treats as partly its own.
#
# Linking file-by-file keeps the directory a real, writable directory that
# happens to contain symlinks — so foreign files can still appear beside ours.
#
# Usage:
#   linkDir lib ./config/fish/conf.d "fish/conf.d"
#     => { "fish/conf.d/10-env.fish" = { source = ...; }; ... }
lib: dir: prefix:
let
  entries = builtins.readDir dir;
  regular = lib.filterAttrs (_: type: type == "regular") entries;
in
lib.mapAttrs' (
  name: _: lib.nameValuePair "${prefix}/${name}" { source = "${dir}/${name}"; }
) regular
