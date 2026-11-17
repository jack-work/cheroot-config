{ inputs, config, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    let
      inherit (pkgs) lib;
      lock = builtins.fromJSON (builtins.readFile ../flake.lock);

      countRepo =
        repo:
        builtins.length (
          builtins.attrNames (
            lib.filterAttrs (k: n: k != "root" && ((n.locked.repo or n.original.repo or "") == repo)) lock.nodes
          )
        );

      hmHosts = [
        "gluck@gluck"
        "marlowe@cheroot"
        "cig@gluck"
        "gluck@wsl"
        "jack@merlin"
      ];

      hmDrvs = builtins.listToAttrs (
        map (name: {
          inherit name;
          value =
            builtins.unsafeDiscardStringContext
              config.flake.homeConfigurations.${name}.activationPackage.drvPath;
        }) hmHosts
      );

      merlinSystem =
        (inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            config.flake.nixosModules.merlin
            {
              boot.loader.grub.enable = false;
              fileSystems."/" = {
                device = "none";
                fsType = "tmpfs";
              };
            }
          ];
        }).config;

      merlinDrv = builtins.unsafeDiscardStringContext merlinSystem.system.build.toplevel.drvPath;
      gluckCfg = config.flake.homeConfigurations."gluck@gluck".config;
      cherootCfg = config.flake.homeConfigurations."marlowe@cheroot".config;
      gluckPkgNames = map lib.getName gluckCfg.home.packages;
      cherootPkgNames = map lib.getName cherootCfg.home.packages;
    in
    {
      checks.desktop-hosts-eval =
        assert countRepo "nixpkgs" == 1;
        assert countRepo "home-manager" == 1;
        assert countRepo "import-tree" == 1;
        assert countRepo "hush" == 1;
        assert builtins.elem "kc" gluckPkgNames;
        assert builtins.elem "captains-log" gluckPkgNames;
        assert builtins.elem "muse-code" gluckPkgNames;
        assert builtins.elem "helium-exit" gluckPkgNames;
        assert builtins.elem "muse-code" cherootPkgNames;
        assert builtins.elem "figaro" cherootPkgNames;
        assert builtins.elem "hush" cherootPkgNames;
        assert !(builtins.elem "kc" cherootPkgNames);
        assert !(builtins.elem "captains-log" cherootPkgNames);
        assert merlinSystem.networking.hostName == "merlin";
        assert !merlinSystem.services.figaro.enable;
        assert merlinSystem.home-manager.users.jack.programs.figaro.package.version == "0.69.9";
        pkgs.runCommand "desktop-hosts-eval"
          {
            summary = builtins.toJSON {
              inherit hmDrvs merlinDrv;
            };
          }
          ''
            printf '%s\n' "$summary" > $out
          '';
    };
}
