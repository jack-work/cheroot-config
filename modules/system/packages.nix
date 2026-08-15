# System-scope packages and services — the NixOS half.
#
# ANSWERING "IS THE FLAKE JUST USER-SCOPED APPLICATIONS?"
#
# Today, yes: everything above is a home-manager module, and home-manager is
# user-scoped by construction. It installs into ~/.nix-profile, writes dotfiles
# into $HOME, and can run systemd USER units. It cannot install into /usr,
# manage system units, or touch kernels, drivers, bootloaders, PAM or a display
# manager. No amount of configuration changes that; it is what home-manager IS.
#
# So the honest split is not "pacman vs nix", it is TWO different lines:
#
#   1. USER-SPACE PACKAGES — ripgrep, gh, gitui, fonts, most GUI apps.
#      home-manager can own these on BOTH Arch and NixOS, identically. This is
#      the line most pacman packages can cross today, one at a time, and each
#      crossing means a `pacman -Rns` so the two copies do not shadow.
#
#   2. TRUE SYSTEM SCOPE — the kernel, drivers, /etc, services, the greeter.
#      On Arch these stay pacman FOREVER; there is no mechanism for nix to own
#      them. On NixOS they must come from nix, because nothing else provides
#      them.
#
# This file is where (2) lives. It contributes to the `nixos` module class
# rather than `homeManager`, which is precisely the dendritic payoff: one file
# can own a feature across BOTH classes, and a machine that is not NixOS simply
# never instantiates the nixos half. Nothing is conditional, nothing is wasted,
# and no Arch host evaluates a line of it.
#
# It is deliberately a SKELETON. The 291 explicitly-installed pacman packages on
# gluck have been classified (see docs/pacman-audit.md) but not transcribed:
# you said you do not want everything on every machine, and picking that set is
# a decision, not a mechanical translation.
{
  # The `nixos` class. Reachable exactly like the homeManager aspects, and
  # consumed by a nixosConfiguration rather than a homeConfiguration.
  flake.modules.nixos.system-base =
    { pkgs, ... }:
    {
      # System-wide packages. The NixOS equivalent of "what pacman installs".
      environment.systemPackages = with pkgs; [
        git
        vim
        wget
        pciutils
        usbutils
      ];

      # Things with NO Arch analogue in this repo, because on Arch they are
      # systemd units that pacman's packages install and `systemctl enable`
      # turns on. On NixOS they are declarative, and belong here.
      #
      # services.pipewire.enable      = true;
      # services.tailscale.enable     = true;
      # virtualisation.docker.enable  = true;
      # services.printing.enable      = true;
      # services.displayManager.sddm.enable = true;
    };

  # The graphical stack, system half. On Arch every one of these comes from
  # pacman because it touches the GPU (nixpkgs#9415); the homeManager aspects
  # configure them and `my.platform.desktopFromNix` stays false. On NixOS this
  # module installs them and the same aspects configure them unchanged.
  flake.modules.nixos.system-desktop = {
    # programs.niri.enable = true;
    # hardware.graphics.enable = true;
    # security.polkit.enable = true;
  };
}
