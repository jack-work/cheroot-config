# cl and its figaro skill. Opt-in: the input is git+ssh on keel and the GitHub
# mirror is private, so a host without a spain key (cheroot) cannot fetch it.
{ inputs, ... }:
{
  flake.modules.homeManager.captains-log = {
    imports = [ inputs.captains-log.homeManagerModules.default ];
    programs.captains-log.enable = true;
  };
}
