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
      "go"
      "editor"
      "tmux"
    ];

    # Everything that only means something on a machine with a screen. A
    # headless host — a server, a container, WSL — passes
    # `aspects = coreAspects` and none of this is evaluated, let alone
    # installed.
    #
    # THE SEAM IS LOAD-BEARING. `coreAspects` is exactly the set that survives
    # having no compositor, no GPU and no window manager: the shells, the
    # prompt, git, go, neovim, tmux, figaro and the CLI tools. Anything that
    # assumes a screen belongs below, even if it is only an environment
    # variable — see modules/desktop/session.nix for the three that were
    # hiding in shell/core.nix until WSL made the mistake visible.
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
          # Instantiated rather than taken from legacyPackages for one reason:
          # an unfree allowlist by name, without which 1Password's add-on
          # (modules/desktop/zen.nix) aborts the whole evaluation. A predicate
          # rather than allowUnfree, so the next unfree thing stops the build.
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfreePredicate =
              pkg: builtins.elem (lib.getName pkg) [ "1password-x-password-manager" ];
          };

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
