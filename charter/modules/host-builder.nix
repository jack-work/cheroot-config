{
  inputs,
  config,
  lib,
  ...
}:
{
  flake.lib = {
    coreAspects = [
      "base"
      "platform"
      "shell"
      "fish"
      "bash"
      "figaro"
      "preflight"
      "hush"
      "prompt"
      "cli"
      "git"
      "go"
      "editor"
      "tmux"
    ];

    guiAspects = [
      "graphical"
      "fonts"
      "niri"
      "waybar"
      "mako"
      "rofi"
      "alacritty"
    ];

    defaultAspects = config.flake.lib.coreAspects ++ config.flake.lib.guiAspects;

    mkHomeHostWith =
      {
        homeManagerLib ? inputs.home-manager.lib,
        nixpkgsInput ? inputs.nixpkgs,
        homeModules ? config.flake.modules.homeManager,
      }:
      {
        user,
        host,
        aspects ? config.flake.lib.defaultAspects,
        roles ? [ ],
        system ? "x86_64-linux",
        settings ? { },
      }:
      {
        "${user}@${host}" = homeManagerLib.homeManagerConfiguration {
          pkgs = nixpkgsInput.legacyPackages.${system};
          modules = map (name: homeModules.${name}) (aspects ++ roles) ++ [
            {
              home.username = user;
              home.homeDirectory = "/home/${user}";
            }
            settings
          ];
        };
      };

    mkHost = config.flake.lib.mkHomeHostWith { };

    mkNixosHostWith =
      {
        nixpkgsInput ? inputs.nixpkgs,
        nixosModules ? config.flake.modules.nixos,
      }:
      {
        host,
        system ? "x86_64-linux",
        aspects ? [
          "base"
          "shell"
          "git"
          "tmux"
        ],
        modules ? [ ],
      }:
      {
        ${host} = nixpkgsInput.lib.nixosSystem {
          inherit system;
          modules =
            map (name: config.flake.lib.nixosAspectFrom nixosModules name) aspects
            ++ [ { networking.hostName = lib.mkDefault host; } ]
            ++ modules;
        };
      };
  };
}
