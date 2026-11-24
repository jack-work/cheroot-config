let
  deploySpan =
    pkgs:
    pkgs.writeShellApplication {
      name = "deploy-span";
      runtimeInputs = [
        pkgs.otel-cli
        pkgs.git
        pkgs.coreutils
      ];
      text = builtins.readFile ./deploy-span/deploy-span.sh;
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.deploy-span = deploySpan pkgs;
      checks.deploy-span = pkgs.runCommand "deploy-span-test" {
        nativeBuildInputs = [
          (deploySpan pkgs)
          pkgs.otel-cli
          pkgs.python3
        ];
      } "bash ${./deploy-span/test.sh} && touch $out";
    };

  flake.modules.homeManager.deploy-span =
    { pkgs, ... }:
    {
      home.packages = [ (deploySpan pkgs) ];
    };
}
