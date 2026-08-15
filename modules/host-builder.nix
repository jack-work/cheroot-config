# The host builder.
#
# ONE FLAKE, MANY MACHINES — the mechanism.
#
# Everything shared lives in aspects (modules/**), which every host gets by
# default. A host file then declares only what is TRUE OF THAT MACHINE: who
# logs in, what shape it is, and its hardware quirks. Adding a machine is a
# dozen lines, and none of them repeat.
#
# The naming convention "<user>@<hostname>" is load-bearing, not cosmetic:
# home-manager's CLI resolves a bare `--flake .` by probing
# $USER@$(hostname -f), $USER@$(hostname), $USER@$(hostname -s) in that order.
# Name the attribute correctly and every machine runs the SAME command:
#
#     home-manager switch --flake .
#
# with no host argument to get wrong.
{
  inputs,
  config,
  lib,
  ...
}:
{
  flake.lib = {
    # Aspects split by what kind of machine needs them. A host composes from
    # these rather than listing sixteen names.
    coreAspects = [
      "base"
      "platform"
      "shell"
      "fish"
      "bash"
      "figaro"
      "prompt"
      "cli"
      "git"
      "editor"
      "tmux"
    ];

    # Everything that only means something on a machine with a screen. A
    # headless host passes `aspects = coreAspects` and none of this is
    # evaluated, let alone installed.
    guiAspects = [
      "fonts"
      "niri"
      "waybar"
      "mako"
      "rofi"
      "alacritty"
    ];

    defaultAspects = config.flake.lib.coreAspects ++ config.flake.lib.guiAspects;

    # mkHost { user; host; aspects; roles; system; settings; }
    #
    #   aspects   the base set. Defaults to everything; a headless or minimal
    #             machine narrows it (e.g. `aspects = coreAspects`). This is how
    #             a host takes LESS, not just more.
    #   roles     extra aspect NAMES layered on top ("laptop", "desktop", ...)
    #   settings  an inline module for this machine alone: platform flags,
    #             monitor layout, anything with an audience of one
    mkHost =
      {
        user,
        host,
        aspects ? config.flake.lib.defaultAspects,
        roles ? [ ],
        system ? "x86_64-linux",
        settings ? { },
      }:
      {
        "${user}@${host}" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.${system};

          modules = map (name: config.flake.modules.homeManager.${name}) (aspects ++ roles) ++ [
            {
              home.username = user;
              home.homeDirectory = "/home/${user}";
            }
            settings
          ];
        };
      };
  };
}
