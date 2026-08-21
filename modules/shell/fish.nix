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
# generates those from shell/core.nix and prompt.nix.
{ config, ... }:
{
  flake.modules.homeManager.fish =
    { lib, ... }:
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
    };
}
