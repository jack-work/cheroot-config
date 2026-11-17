{ inputs, ... }:
{
  flake.modules.homeManager.keel-tasks =
    { config, ... }:
    {
      imports = [ inputs.keel.homeModules.tasks ];
      services.keel-tasks = {
        enable = true;
        hub = "http://100.103.40.20:8101";
        tokenFile = "${config.home.homeDirectory}/.config/keel/queue-token";
        viewer = "https://keel.kelliher.info/_keel/";
      };
    };
}
