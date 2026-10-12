{ inputs, ... }:
{
  flake.modules.homeManager.muse-code =
    { pkgs, ... }:
    {
      home.packages = [ inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.muse-code ];
    };
}
