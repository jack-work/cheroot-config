# Prompt: starship, plus the Kanagawa configuration it renders.
#
# One `enable` serves both shells. The [custom.figaro] module in starship.toml
# only ECHOES $FIGARO_PROMPT — the variable is produced by the per-shell hooks
# in modules/figaro.nix, because figaro's binding depends on who its parent
# process is and starship runs custom modules in a subshell.
{
  flake.modules.homeManager.prompt = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };

    xdg.configFile."starship.toml".source = ../config/starship/starship.toml;
  };
}
