# Everything every host gets. Deliberately tiny: identity and the
# home-manager module itself. Package sets and configuration live in the
# feature aspects.
{
  flake.modules.homeManager.base = {
    home.stateVersion = "26.11";
    programs.home-manager.enable = true;
  };
}
