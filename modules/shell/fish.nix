# fish rendering.
#
# home-manager owns ~/.config/fish/config.fish (it generates it from
# shellAliases and the various enableFishIntegration flags). Our own
# configuration therefore lives entirely in numbered conf.d/ modules, which
# fish sources in filename order BEFORE config.fish:
#
#   10-env  12-wayland  15-brew  20-cachyos  30-path  50-conda
#   65-figaro-prompt  70-fzf
#
# Aliases (40-) and prompt init (60-) are absent on purpose — home-manager
# generates those from shell/core.nix and prompt.nix, into config.fish. See
# `retired` below for why their absence has to be enforced, not just intended.
{ config, ... }:
{
  # `hm@{ ... }` rather than destructuring `config`: the OUTER `config` is the
  # flake config, and it is used below for `config.flake.lib.linkDir`. Taking
  # `config` as an inner argument would shadow it and break that call. `hm.config`
  # is the home-manager config, kept explicitly distinct.
  flake.modules.homeManager.fish =
    hm@{ lib, ... }:
    let
      # Files a PREVIOUS, hand-rolled fish config installed into conf.d, whose
      # content now lives in the home-manager-generated config.fish.
      #
      # This is not housekeeping — leaving them is actively wrong. conf.d is
      # sourced BEFORE config.fish, so a stale 60-prompt.fish runs
      # `starship init fish | source` and `zoxide init fish | source` a second
      # time in every interactive shell, on top of the generated ones. Duplicate
      # aliases are merely redundant; a duplicate prompt init is not.
      #
      # home-manager cannot fix this itself. Its `-b bak` handles COLLISIONS —
      # files it wants to own that already exist — and it never wants these, so
      # it never looks at them. And linkDir deliberately leaves conf.d a real,
      # writable directory (fish writes fish_frozen_*.fish into it), so foreign
      # files legitimately live there and blanket-pruning is not an option.
      # Hence an explicit list: we remove exactly what we know we superseded.
      #
      # Renamed, not deleted. fish sources only `*.fish` from conf.d, so a
      # `.fish.bak` suffix is inert — the content survives for inspection while
      # having no effect. Same convention as home-manager's own `-b bak`.
      retired = [
        "40-aliases.fish"
        "60-prompt.fish"
      ];
    in
    {
      # PER-FILE linking, never `."fish/conf.d".source = ./dir`.
      # fish writes fish_frozen_theme.fish / fish_frozen_key_bindings.fish into
      # conf.d, and `fish_config` writes there when saving a theme; a read-only
      # store symlink breaks both. See lib/link-dir.nix.
      xdg.configFile =
        config.flake.lib.linkDir ../../config/fish/conf.d "fish/conf.d"
        // config.flake.lib.linkDir ../../config/fish/functions "fish/functions"
        // config.flake.lib.linkDir ../../config/fish/themes "fish/themes";

      # fzf.fish's six searchers (dir / git log / git status / history /
      # processes / variables) are vendored under config/fish/functions and
      # bootstrapped by conf.d/70-fzf.fish. fisher is deliberately not used.
      #
      # Consequently home-manager's own fish integration for fzf is turned OFF:
      # it would install a SECOND, conflicting set of bindings over the same
      # keys. bash keeps home-manager's integration, because fzf.fish is
      # fish-only — see shell/bash.nix.
      programs.fzf.enableFishIntegration = lib.mkForce false;

      # Retire the superseded conf.d files described above. Guarded on "regular
      # file, not a symlink": anything home-manager owns is a store symlink, so
      # this can only ever touch a leftover, never a managed file. `run` is
      # home-manager's wrapper — it honours --dry-run, so the dry run reports
      # the move instead of performing it.
      home.activation.retireFishConfD = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        for f in ${lib.escapeShellArgs retired}; do
          p="${hm.config.xdg.configHome}/fish/conf.d/$f"
          if [ -f "$p" ] && [ ! -L "$p" ]; then
            run mv $VERBOSE_ARG "$p" "$p.bak"
          fi
        done
      '';
    };
}
