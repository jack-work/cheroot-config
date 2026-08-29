# The audio/mixing kit.
#
# OPT-IN. This aspect is in neither `coreAspects` nor `guiAspects`, so it costs
# nothing on a host that does not ask for it — not installed-but-unused, never
# evaluated. A host takes it by naming it, which `mkHost`'s `roles` already
# supports since roles are just extra aspect NAMES:
#
#     roles = [ "desktop" "audio" ];
#
# ---------------------------------------------------------------------------
# WHY THIS IS SPLIT IN THREE
# ---------------------------------------------------------------------------
# The list below is not "the audio packages". It is three lists, because three
# different questions have three different answers, and answering them all the
# same way is how you end up shadowing a current binary with a stale one.
#
#   1. WHAT ARCH DOES NOT SHIP AT ALL — installed unconditionally.
#      Measured on gluck 2026-08-29: aubio, loudgain, opus-tools and yt-dlp are
#      absent from pacman entirely, so there is nothing to shadow and nothing to
#      argue about. Pure gain.
#
#   2. WHAT BOTH SHIP AT THE SAME VERSION — also installed unconditionally.
#      rubberband is 4.0.0 in nixpkgs and 4.0.0-2.1 in pacman; flac is 1.5.0 in
#      both. A shadow that changes nothing is not a shadow worth avoiding, and
#      declaring them here means they survive a `pacman -Rns` of whatever
#      dragged them in. (rubberband on gluck is a DEPENDENCY, not an explicit
#      install — nothing guarantees it stays.)
#
#   3. WHAT ARCH SHIPS *NEWER* — behind `my.platform.mediaFromNix`, default off.
#      sox and ffmpeg. See modules/platform.nix for the measured versions; the
#      short form is nixpkgs' sox is a 2021 snapshot against pacman's 2026
#      build, and nixpkgs' ffmpeg is a major version behind the one Firefox
#      depends on. On a host with neither — WSL, a server, NixOS — the flag goes
#      true and nix provides them, because there is no competition.
#
# GUI tools are a fourth case and are NOT here at all: audacity and
# sonic-visualiser draw, so on Arch they belong to pacman (nixpkgs#9415), and a
# host that wants them should install them the same way it installs a browser.
# Only `my.platform.desktopFromNix` hosts would take them from nix, and no host
# in this repo sets that today. Left out rather than guessed at.
{
  flake.modules.homeManager.audio =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      home.packages =
        (with pkgs; [
          # ── Absent from Arch: pure additions ──────────────────────────────
          #
          # Onset, beat, pitch and MFCC extraction from the command line:
          # `aubioonset`, `aubiotrack`, `aubiopitch`, `aubionotes`. This is the
          # analysis half of a mixing kit — finding where the transients are so
          # something else can cut there.
          aubio

          # EBU R128 loudness scanning and ReplayGain 2.0 tagging. The correct
          # answer to "why is this track quieter than that one" — measures LUFS
          # and writes tags rather than destructively normalising samples.
          loudgain

          # opusenc / opusdec / opusinfo. The encoder worth having for anything
          # speech-shaped or bandwidth-constrained.
          opus-tools

          # Source material. Not a mixing tool, but every mixing session starts
          # with getting the audio onto the disk, and yt-dlp's `-x
          # --audio-format` path is the usual first command.
          yt-dlp

          # ── Same version in both: harmless shadow, useful declaration ──────
          #
          # Time-stretching and pitch-shifting, independently — the `rubberband`
          # CLI plus the library. nixpkgs 4.0.0 == pacman 4.0.0-2.1 on gluck,
          # where it arrived only as a dependency of something else. Declaring
          # it means it stops being incidental.
          rubberband

          # `flac`, `metaflac`. 1.5.0 in both.
          flac

          # `sndfile-info`, `sndfile-convert`, `sndfile-play` — the quickest way
          # to answer "what actually IS this file" without launching anything.
          # 1.2.2 in both.
          libsndfile
        ])

        # ── Arch ships these NEWER: only on a host that has neither ──────────
        ++ lib.optionals config.my.platform.mediaFromNix (
          with pkgs;
          [
            # The Swiss Army knife: resample, trim, fade, mix, and the `spectrogram`
            # and `stats` effects that make it a diagnostic tool as much as an
            # editor.
            sox

            # The universal converter, and `ffprobe` with it.
            ffmpeg
          ]
        );
    };
}
