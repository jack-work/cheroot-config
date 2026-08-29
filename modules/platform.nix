# Platform portability.
#
# THE PROBLEM. This configuration has to run in two very different places:
#
#   Arch + nix-as-package-manager (gluck, cheroot)
#       The distro owns the graphics stack. Anything that draws — a compositor,
#       a bar, a GPU-accelerated terminal — MUST come from pacman. nixpkgs Mesa
#       on a non-NixOS host is nixpkgs#9415 (open since 2015): a nix-built
#       compositor links nixpkgs Mesa against the Arch kernel driver and renders
#       in software, or not at all. Likewise the login shell, which needs an
#       /etc/shells entry and a stable path.
#
#   NixOS
#       Nothing else provides those packages, so nix must.
#
# The old configuration hardcoded the first case in a comment and would simply
# have been wrong on NixOS. These options make the difference declarative, and —
# importantly — ADDITIVE: a host opts in to nix providing things, rather than
# the shared modules having to know which distro they are on.
{ lib, ... }:
{
  flake.modules.homeManager.platform = {
    options.my.platform = {
      desktopFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Let nix provide the graphical stack (niri, waybar, mako, rofi,
          alacritty, swaybg). FALSE on Arch-family hosts, where pacman owns
          everything that touches the GPU. TRUE on NixOS.
        '';
      };

      shellsFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        internal = true;
        description = ''
          RESERVED, and currently inert — kept only so the intent is recorded.

          It cannot do what it looks like it should. home-manager's fish module
          needs a real fish to run `fish_indent` and to generate completions, so
          enabling fish configuration ALWAYS installs a nix fish; overriding
          `programs.fish.package` with an empty derivation fails the build. See
          the note in modules/shell/core.nix.

          The duplicate is harmless on Arch (same 4.8.1, and /etc/passwd
          launches /bin/fish by absolute path). Left here rather than deleted
          because "why is there a second fish?" is a question worth answering
          once, in writing.
        '';
      };

      toolchainFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Let nix provide the native toolchain (gcc, make, tree-sitter, node,
          python3) that neovim's treesitter and mason need.

          FALSE where the distro already ships a toolchain. On Arch this matters
          a great deal: ~/.nix-profile/bin precedes /usr/bin, so a nix gcc would
          shadow the system gcc for every native build in the session — cargo,
          node-gyp, treesitter parsers — compiling against Arch headers with a
          different compiler and libc. gluck has gcc 16.2.1 from pacman and does
          not want nixpkgs gcc 15.3.0 in front of it.

          TRUE on a minimal host with no toolchain of its own.
        '';
      };

      mediaFromNix = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Let nix provide the heavy media codecs and processors — today `sox`
          and `ffmpeg`, consumed by the `audio` aspect.

          FALSE on Arch, and for once this is not a GPU argument. It is that
          nixpkgs is BEHIND the distro on both, measured 2026-08-29:

            sox     nixpkgs unstable-2021-05-09  vs  pacman 14.8.0.1 (built
                    2026-05-26). Upstream sox went dormant and nixpkgs still
                    carries a 2021 snapshot; installing it would shadow a
                    current build with a five-year-old one. sox is also the one
                    audio tool on gluck installed EXPLICITLY, on purpose.

            ffmpeg  nixpkgs 8.1.2  vs  pacman 2:9.0.1 — a whole major version,
                    and pacman's is `Required By: firefox chromaprint gst-libav
                    ffmpegthumbnailer localsearch`. Shadowing only the binary
                    (libraries link by store path, not PATH) is survivable, but
                    it is still a downgrade for every command you type.

          TRUE on a host that has neither — WSL, a headless server, NixOS —
          where nixpkgs' version is not competing with anything, it IS the
          only one.

          Everything in the `audio` aspect that Arch does NOT ship is installed
          regardless of this flag; see modules/audio.nix.
        '';
      };
    };
  };
}
