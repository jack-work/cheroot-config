{ config, ... }:
{
  flake.modules.homeManager.fish =
    hm@{ lib, ... }:
    let
      retired = [
        "40-aliases.fish"
        "60-prompt.fish"
      ];
    in
    {
      xdg.configFile =
        config.flake.lib.linkDir ../../config/fish/conf.d "fish/conf.d"
        // config.flake.lib.linkDir ../../config/fish/functions "fish/functions"
        // config.flake.lib.linkDir ../../config/fish/themes "fish/themes";

      programs.fzf.enableFishIntegration = lib.mkForce false;

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
