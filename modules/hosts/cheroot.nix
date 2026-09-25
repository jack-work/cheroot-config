# cheroot — ThinkPad X13 Gen 1 (20T2003UUS)
#   i7-10510U · Intel UHD (Comet Lake) · 13.3" 1920x1080 · 16 GB · plain Arch
#
# Compare with hosts/gluck.nix: the two machines differ by one role, one
# platform flag, and their output blocks. Everything else is shared, and neither
# file knows the other exists.
{ config, ... }:
{
  flake.homeConfigurations = config.flake.lib.mkHost {
    user = "marlowe";
    host = "cheroot";
    roles = [
      "laptop"
      # Opt-in aspects, not machine classes. See modules/desktop/zen.nix.
      "zen"
    ];

    settings = {
      my.platform.desktopFromNix = false;

      # This box has polkit-GNOME; gluck has polkit-KDE. The shared config used
      # to name the KDE path, so cheroot booted for six weeks with no polkit
      # agent and no way to answer a GUI authentication prompt.
      my.preflight.binaries = [ "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1" ];
      my.preflight.pacman = [
        "polkit-gnome"
        "ttf-jetbrains-mono-nerd"
      ];

      # No Secret Service on this box (libsecret is installed, gnome-keyring is
      # not), and figaro runs hush unattended: an agent that can only be
      # unlocked by someone typing is an agent an aria cannot use. The
      # passphrase lives in ~/.config/hush/passphrase, 0600, created by hand.
      my.hush.unlock = ''
        ttl = "12h"

        [unlock]
        method = "file"
        file = "/home/marlowe/.config/hush/passphrase"
      '';

      # This machine's zen (1.21.9b) uses the XDG path; gluck's (1.21.13b)
      # still uses ~/.zen. Both values read out of the real profiles.ini; a
      # wrong one configures a profile the browser never opens.
      my.zen.configPath = ".config/zen";
      my.zen.profileDir = "y9w3yl5l.Default (release)";

      # Temporary: this Zen speaks shortcut schema 19, the export was taken at
      # gluck's 20. Drop the line once `pacman -Syu zen-browser-bin` levels
      # them, and let the default take over.
      my.zen.shortcutsVersion = 19;

      # Clock centring at 1920px with the laptop module set. Measured: left
      # group ended x=137, clock 733-970, weather began x=996, so 596px slack
      # left against 26px right; equalising needs a 285px leftward shift, and
      # margin-right shifts 1:1, hence 287. Re-measure if modulesRight changes.
      # (The old hand-written sheet had a second copy of this under
      # `#clock#date`, which names two ids and never matched anything.)
      my.waybar.extraStyle = ''

        /* host: cheroot, 1920px */
        #clock {
            margin: 1px 287px 1px 2px;
        }
      '';

      # Minimal install with no system toolchain, so neovim's treesitter and
      # mason need nix to supply one. This is the flag's reason to exist: gluck
      # sets it false, cheroot true, and neither has to know about the other.
      my.platform.toolchainFromNix = true;

      # Internal panel. 1920x1080 at 13.3" is ~166 DPI; scale 1.0 is legible but
      # tight. Change to 1.25 and re-switch if it reads small.
      #
      # This is the ONLY output block, and it names the internal panel only.
      # External monitors are deliberately unlisted so niri auto-enables them at
      # their preferred mode — that is what keeps the config portable.
      my.niri.extra = ''

        // ===== host: cheroot (laptop) =====
        output "eDP-1" {
            scale 1.0
        }

        // Samsung LS27D36xG, 27" 1080p: 600 mm of panel for 1920 px is 81 DPI,
        // against the internal panel's 290 mm for 1920 px, or 168. At scale 1.0
        // on both, the same window is more than twice the physical size over
        // here, which is why the external reads huge rather than merely large.
        // 0.8 buys 2400x1350 of logical space, about 101 DPI. A 1080p panel at
        // this size cannot be made crisp AND small, so this is a compromise:
        // drop to 0.75 (2560x1440) for more room, raise toward 1.0 for less
        // softness.
        //
        // The mode is named only because the preferred one is 60 Hz and the
        // panel will do 100. Auto-enable would take the slower one forever.
        output "DVI-I-1" {
            mode "1920x1080@100.000"
            scale 0.8
        }

        spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
      '';
    };
  };
}
