{
  flake.modules.nixos.go =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.go ];
    };

  flake.modules.homeManager.go =
    {
      config,
      lib,
      ...
    }:
    let
      goPath = "${config.home.homeDirectory}/go";
    in
    {
      programs.go = {
        enable = true;
        package = lib.mkIf (!config.my.platform.toolchainFromNix) null;
        env = {
          GOPATH = goPath;
          GOFLAGS = "-buildvcs=false";
        };
      };

      xdg.configFile."fish/conf.d/25-go.fish".text = ''
        if not set -q IN_NIX_SHELL
            fish_add_path -gmp ${goPath}/bin
        end
      '';

      home.file.".bashrc.d/25-go.sh".text = ''
        if [ -z "$IN_NIX_SHELL" ]; then
            case ":$PATH:" in
                *":${goPath}/bin:"*) : ;;
                *) PATH="${goPath}/bin''${PATH:+:$PATH}"; export PATH ;;
            esac
        fi
      '';
    };
}
