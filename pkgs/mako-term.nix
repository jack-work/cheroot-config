{
  lib,
  writeShellApplication,
  jq,
  tmux,
  coreutils,
  procps,
}:

# mako-term — open a terminal (optionally a tmux pane) from a notification.
#
# Packaged rather than left as a loose script so its dependencies are pinned and
# shellcheck runs at build time. `makoctl` and the terminal are intentionally
# NOT nix inputs: mako and alacritty come from pacman (they are Wayland clients
# that touch the display stack), so they are resolved from PATH at runtime.

writeShellApplication {
  name = "mako-term";

  runtimeInputs = [
    jq
    tmux
    coreutils
    procps
  ];

  text = builtins.readFile ../config/mako/mako-term.sh;

  meta = with lib; {
    description = "Open a terminal or tmux pane from a mako notification";
    platforms = platforms.linux;
  };
}
