# The graphical SESSION — the aspect for "this machine has a screen".
#
# WHY THIS EXISTS. `my.platform.desktopFromNix` answers *who provides* the GUI
# (pacman or nix). It does not answer the prior question: is there a GUI at all?
# A headless server, a container, and WSL all say no, and until this file
# existed the answer leaked into `shell/core.nix` — a CORE aspect, which every
# host takes, including the ones with no compositor.
#
# Three environment variables and one fish module were riding along there:
#
#   QT_QPA_PLATFORMTHEME  meaningless without a Qt application to theme
#   TERM=alacritty        an outright LIE off the desktop. WSL runs under
#                         Windows Terminal, ssh under whatever the client is;
#                         claiming alacritty there mis-renders keys and colours
#                         against a terminfo entry the machine may not even have
#   12-wayland.fish       repairs a lost WAYLAND_DISPLAY. Inert without wayland
#
# So: `graphical` is a GUI aspect. It ships with `guiAspects`, and a host that
# narrows itself to `coreAspects` never evaluates a line of it.
#
# BROWSER is deliberately NOT here. It names a specific binary (cachy-browser on
# gluck, something else anywhere else), which makes it host-specific, not
# class-specific. See modules/hosts/gluck.nix.
{ config, ... }:
{
  flake.modules.homeManager.graphical = {
    home.sessionVariables = {
      QT_QPA_PLATFORMTHEME = "qt5ct";

      # NOTE: setting TERM from a profile is questionable even here — it
      # properly comes from the terminal, and alacritty.toml already exports
      # TERM=xterm-256color for its own windows. Carried over verbatim from
      # gluck's hand-written ~/.profile to preserve behaviour; drop it if
      # anything renders oddly over ssh.
      TERM = "alacritty";
    };

    # Lands in the same ~/.config/fish/conf.d as the core modules — the
    # directory is assembled from two sources, and only graphical hosts get the
    # second. See modules/shell/fish.nix for why linking is per-file.
    xdg.configFile = config.flake.lib.linkDir ../../config/fish/conf.d-graphical "fish/conf.d";
  };
}
