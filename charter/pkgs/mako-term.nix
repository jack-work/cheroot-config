{
  lib,
  writeShellApplication,
  jq,
  tmux,
  coreutils,
  procps,
}:
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
