# Zig — the toolchain and its language server, pinned together.
#
# OPT-IN, like `audio` and unlike `go`: named in a host's `roles`, in neither
# coreAspects nor guiAspects. Go is core because figaro is Go and every host
# needs it; zig is one project's toolchain and a laptop that never opens it
# should not carry a compiler.
#
# ---------------------------------------------------------------------------
# WHY THIS IS *NOT* SHAPED LIKE go.nix, IN THREE PLACES
# ---------------------------------------------------------------------------
# modules/go.nix is the model for the documentation, not for the mechanics.
# Three of its moves are deliberately absent here, and each absence is a
# decision rather than an omission:
#
#   1. NO `package = null`.
#      go.nix takes home-manager's CONFIGURATION management and leaves the
#      binary to pacman, because gluck already has a distro go. There is no
#      distro zig — measured 2026-08-30, `zig` and `zls` are absent from pacman
#      AND from this profile, on every host in this repo. So nix is not
#      shadowing anything; it is the only provider, and
#      `my.platform.toolchainFromNix` has nothing to arbitrate. That flag is
#      about not getting in the distro's way, and here the distro has no way.
#
#   2. NO 25-zig.fish / 25-zig.sh PATH FRAGMENT.
#      go.nix needs one because `go install` writes to $GOPATH/bin, a global
#      directory that must be on PATH but must sit BEHIND ~/.nix-profile/bin so
#      a stale `go install`ed fig cannot shadow the nix one. Zig has no such
#      directory: `zig build` writes ./zig-out/bin inside the project, and
#      nothing is installed globally. Adding a fragment for symmetry would be
#      noise pretending to be consistency.
#
#   3. NO home-manager MODULE.
#      There is no `programs.zig`; home-manager ships nothing for it. So this
#      is home.packages, which is also why there is no `env` block — zig reads
#      no equivalent of ~/.config/go/env.
#
# ---------------------------------------------------------------------------
# THE ONE ZIG-SPECIFIC TRAP: zls IS VERSIONED IN LOCKSTEP WITH zig
# ---------------------------------------------------------------------------
# zls tracks the compiler release for release and refuses to work against a
# mismatched one — and the failure is a confusing "invalid build" rather than a
# clean version error. nixpkgs builds them from the same release, so taking
# BOTH from this flake is what keeps the pair honest: one flake.lock, one
# version, moved deliberately by `nix flake update` rather than drifting apart.
#
# Currently pinned: zig 0.16.0, zls 0.16.0.
#
# THIS IS ALSO THE ARGUMENT AGAINST INSTALLING zls FROM MASON. ~/.config/nvim is
# deliberately unmanaged (lazy.nvim and mason write into it — see
# modules/editor.nix), and mason would happily fetch its own zls on whatever
# schedule it likes, against whatever zig happens to be on PATH. Mason's
# prebuilt binaries also assume an FHS host: they work on Arch and would not on
# NixOS. Taking zls from nix means lspconfig finds a matched one on PATH and
# mason never has to guess.
#
# AND IT IS THE ARGUMENT FOR THE FLAKE OVER `nix profile install zig`. Zig's
# build API changes materially at every minor release — 0.11 → 0.12 → 0.13 each
# broke build.zig files in the wild. A version that lives in flake.lock moves
# for the whole fleet at once, on purpose, and `git log` says when and why. A
# version installed imperatively drifts per machine and explains nothing.
{
  flake.modules.homeManager.zig =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # The compiler, and with it `zig build`, `zig cc`, `zig test` and the
        # cross-compilation targets that are most of the reason to reach for it.
        zig

        # The language server. Matched to the compiler above by flake.lock; see
        # the header.
        zls

        # Translates a `build.zig.zon` dependency set into a nix expression, so
        # a zig project in this ecosystem can be BUILT by nix rather than only
        # developed under it. Small, and the thing you want the first time a zig
        # project needs to become a flake — which is the shape every other
        # repo here already has.
        zon2nix
      ];
    };
}
