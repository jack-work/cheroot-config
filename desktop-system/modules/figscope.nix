{ inputs, ... }:
{
  flake.modules.homeManager.figscope =
    { config, pkgs, ... }:
    let
      home = config.home.homeDirectory;
      hush = inputs.hush.packages.${pkgs.stdenv.hostPlatform.system}.hush;
    in
    {
      imports = [ inputs.figscope.homeManagerModules.default ];

      services.figscope = {
        enable = true;
        args = [
          "-listen"
          "127.0.0.1:4380"
          "-otlp-http"
          "127.0.0.1:4318"
          "-otlp-grpc"
          "127.0.0.1:4317"
          "-tail"
          "${home}/.local/state/figaro"
          "-tail-signals"
          "traces"
          "-forward"
          "https://scope-ingest.kelliher.info"
          "-forward-token-cmd"
          "${hush}/bin/hush oauth get figscope-drop"
          "-pager-alert-cmd"
          "${home}/.nix-profile/bin/figaro send -f --id @ee927149 --stdin"
        ];
      };

      systemd.user.services.figscope.Service = {
        RestartSec = 5;
        Nice = 5;
      };
    };
}
