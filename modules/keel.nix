{ inputs, ... }:
{
  flake.modules.homeManager.keel =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellApplication {
          name = "kc";
          runtimeInputs = with pkgs; [
            curl
            git
            python3
          ];
          text = ''
            export KEEL_BASE=''${KEEL_BASE:-https://keel.kelliher.info}
            export KEEL_OIDC_ISSUER=''${KEEL_OIDC_ISSUER:-https://auth.kelliher.info}
            exec bash ${inputs.keel}/kc.sh "$@"
          '';
        })
      ];
    };
}
