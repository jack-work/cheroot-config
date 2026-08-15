# Role: desktop.
#
# Currently carries nothing: the waybar default IS the desktop set, and desktop
# outputs are host-specific rather than role-specific. It exists so that
# hosts/gluck.nix can name its shape, and so the first desktop-only concern has
# an obvious home.
{
  flake.modules.homeManager.desktop = { };
}
