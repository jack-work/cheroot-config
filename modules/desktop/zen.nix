# Zen — the browser, declared once and worn by every machine.
#
# OPT-IN, like `audio` and `zig`: a host takes it by naming it in `roles`. It is
# deliberately NOT in `guiAspects`, because this aspect WRITES A PROFILE. A new
# graphical host should say so on purpose rather than discover that its browser
# profile has been adopted.
#
# ---------------------------------------------------------------------------
# WHAT NIX OWNS HERE, AND WHAT IT DOES NOT
# ---------------------------------------------------------------------------
#   owned   prefs (user.js), extensions (the xpi set), the active theme,
#           keyboard shortcuts, userChrome
#   NOT     the binary (pacman — see below), and the settings that live INSIDE
#           an extension. Vimium C's keymap is the one that matters and it is
#           stored in the extension's own IndexedDB. home-manager can write
#           `browser-extension-data/<id>/storage.js` instead, but only by
#           setting `ExtensionStorageIDB.enabled=false` for the WHOLE profile,
#           which drops every extension to the legacy backend and hides what
#           they already had (home-manager#9211). That trade is not worth one
#           extension's keymap: export Vimium C's options JSON from its own
#           options page and import it on the other machine.
#
# ---------------------------------------------------------------------------
# THE PACKAGE IS NULL ON BOTH HOSTS, AND THAT IS THE POINT
# ---------------------------------------------------------------------------
# Zen draws, so `my.platform.desktopFromNix` decides who ships it, exactly as it
# does for waybar and niri (nixpkgs#9415). Both machines are Arch, both have
# `zen-browser-bin` from the AUR at 7.0.9 while nixpkgs is not in the race at
# all — it has no zen-browser. So on both hosts the package is null and this
# module configures a binary it did not install, the same division figaro and go
# already use.
#
# The consequence worth knowing: `policies` (and therefore policy-installed
# extensions and managed storage) DO NOT APPLY with a null package. Policies
# live in the wrapper, and there is no wrapper. Extensions are installed the
# other way — as xpi files dropped into the profile — which works with any
# gecko binary.
#
# ---------------------------------------------------------------------------
# CONFIG PATH: `.zen`, NOT `.config/zen`
# ---------------------------------------------------------------------------
# The upstream module targets `$XDG_CONFIG_HOME/zen`, which is where a fresh
# Zen 8 puts a new profile. The AUR build on gluck is at `~/.zen` and has been
# writing there all along — a live profile with the bookmarks, cookies and
# logins in it. Pointing home-manager at the XDG path would not migrate that
# profile; it would leave it untouched and configure an empty one beside it.
# So `my.zen.configPath` names the directory THIS machine's binary uses, and it
# is a per-host fact like the monitor layout.
{ inputs, ... }:
{
  flake.modules.homeManager.zen =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      addons = inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system};

      # Shortcuts are DATA, exported from a live profile by
      # bin/zen-shortcuts-export. Read the header of that script before
      # regenerating: the file lists every addressable shortcut, not just the
      # ones that were changed, because Zen's own file does not record which
      # were changed.
      shortcuts = builtins.fromJSON (builtins.readFile ../../config/zen/keyboard-shortcuts.json);
    in
    {
      imports = [ inputs.zen-browser.homeModules.beta ];

      options.my.zen = {
        configPath = lib.mkOption {
          type = lib.types.str;
          default = ".zen";
          example = ".config/zen";
          description = ''
            Directory, relative to $HOME, that this machine's Zen binary reads.
            `.zen` for the AUR/official builds in use today; `.config/zen` is
            where Zen puts a brand-new profile once it has migrated to the XDG
            layout. Check which one exists before changing it — the wrong value
            silently configures a profile the browser never opens.
          '';
        };

        profileDir = lib.mkOption {
          type = lib.types.str;
          default = "default";
          example = "829beuvl.Default (release)";
          description = ''
            Name of the profile DIRECTORY inside `configPath`, which
            home-manager writes into profiles.ini.

            THIS IS THE DANGEROUS ONE. Zen generates a random prefix
            ("829beuvl.") the first time it runs, and a machine that already has
            a profile must name it here exactly. Get it wrong and Zen finds no
            profile at that path and cheerfully creates an empty one — history,
            logins and extensions all still on disk, none of them loaded.
          '';
        };

        shortcutsVersion = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = shortcuts.version;
          defaultText = lib.literalExpression "the version recorded in config/zen/keyboard-shortcuts.json";
          description = ''
            The shortcut schema version THIS MACHINE'S Zen speaks, read from
            about:config's `zen.keyboard.shortcuts.version`. Activation refuses
            to patch when it disagrees, which is the whole point: a Zen release
            that renumbers the schema should stop and be looked at, not quietly
            write bindings by id into a table that has moved underneath them.

            It defaults to the version the export was taken at, so the machine
            that produced config/zen/keyboard-shortcuts.json declares nothing. A
            host whose browser is BEHIND names its own version, which is a
            statement that the drift is known and temporary — the repair is to
            upgrade that machine's Zen until both speak the same schema.

            `null` disables the check. Do not.
          '';
        };
      };

      config = {
        programs.zen-browser = {
          enable = true;

          # See the header: on Arch, pacman owns anything that draws, so the
          # package is null and this module configures a binary it did not
          # install. `mkIf` on the NEGATED flag rather than an if/else: when a
          # host does set `desktopFromNix`, no definition is made here at all
          # and the upstream module's own default package applies.
          #
          # Getting this backwards is silent and expensive — the build simply
          # downloads a 100MB browser nobody launches. Check with:
          #   nix path-info -r <activationPackage> | grep zen-
          package = lib.mkIf (!config.my.platform.desktopFromNix) null;

          # home-manager's firefox machinery marks these internal because a
          # normal user has no reason to move them. We do: the binary is not
          # ours, so the paths are the binary's, not the module's.
          configPath = config.my.zen.configPath;
          profilesPath = config.my.zen.configPath;
          vendorPath = config.my.zen.configPath;

          profiles.default = {
            id = 0;
            isDefault = true;
            path = config.my.zen.profileDir;

            # ── Extensions ────────────────────────────────────────────────
            # Dropped into <profile>/extensions as signed xpi files. `force`
            # is required because a profile that already has these installed
            # by hand would otherwise collide with the store copies.
            extensions = {
              force = true;
              packages = [
                addons.vimium-c
                addons.ublock-origin
                addons.auto-tab-discard
                addons.don-t-fuck-with-paste

                # Not in rycee's set — a static theme, pinned straight from
                # AMO. See pkgs/firefox-xpi.nix for why that is a two-line
                # derivation rather than an input.
                (pkgs.callPackage ../../pkgs/firefox-xpi.nix { } {
                  name = "kanagawa-wave-dark-theme";
                  version = "2.5";
                  addonId = "{7efc2a80-496f-49b1-88db-4ddd7d312757}";
                  url = "https://addons.mozilla.org/firefox/downloads/file/4847676/kanagawa_wave_dark_theme-2.5.xpi";
                  hash = "sha256-V9qf5D4sN6Xp7qrzUBKOlMNzhp4Eo0WsuF3JE3KCSVM=";
                })

                # 1Password IS in rycee's set, and we still do not use it from
                # there. Its license is unfree, and rycee's package is
                # evaluated inside THAT flake's own nixpkgs — an instance this
                # repo does not construct and therefore cannot hand an
                # allowUnfree predicate to. `NIXPKGS_ALLOW_UNFREE=1 --impure`
                # would "fix" it by making every build depend on the
                # environment, which is the opposite of the point.
                #
                # Pinned here instead, where the license is declared honestly
                # and the allowlist in modules/host-builder.nix permits exactly
                # this one package by name.
                (pkgs.callPackage ../../pkgs/firefox-xpi.nix { } {
                  name = "1password-x-password-manager";
                  version = "8.12.32.33";
                  addonId = "{d634138d-c276-4fc8-924b-40a0ea21d284}";
                  url = "https://addons.mozilla.org/firefox/downloads/file/4951729/1password_x_password_manager-8.12.32.33.xpi";
                  hash = "sha256-uVL7YXAn94tWSf/diPWLwH2pLSHcc8xrtuKIeeXi4ws=";
                  license = lib.licenses.unfree;
                })
              ];
            };

            # ── Prefs ─────────────────────────────────────────────────────
            # Only DELIBERATE choices. Zen writes a great deal else into
            # prefs.js — migration flags, build ids, the urlbar's learned
            # ranking — and none of that is configuration; it is state, and
            # declaring state is how a config file starts fighting its
            # program.
            settings = {
              # Theme, installed above. Without this pref the xpi is present
              # and inert.
              "extensions.activeThemeID" = "{7efc2a80-496f-49b1-88db-4ddd7d312757}";

              # Layout: two toolbars, no compact mode at startup, and when
              # compact mode IS on, hide the toolbar rather than float it.
              "zen.view.use-single-toolbar" = false;
              "zen.view.compact.enable-at-startup" = false;
              "zen.view.compact.should-enable-at-startup" = false;
              "zen.view.compact.hide-toolbar" = true;
              "zen.theme.gradient.show-custom-colors" = true;

              # Follow the system light/dark scheme.
              "zen.view.window.scheme" = 0;

              # Sponsored suggestions in the address bar: no.
              "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            };

            # The memory/tab-unloader block, kept as a file because its
            # comments carry the measurements. See config/zen/user.js.
            extraConfig = builtins.readFile ../../config/zen/user.js;

            # ── Shortcuts ─────────────────────────────────────────────────
            # The module PATCHES zen-keyboard-shortcuts.json by id during
            # activation rather than replacing the file. That is why a Zen
            # release which adds a shortcut does not lose it, and why this list
            # can be exhaustive without being brittle.
            #
            # Practical note: Zen holds the file open. Close the browser before
            # a switch that changes shortcuts, or the patch lands and the
            # running instance overwrites it on exit.
            keyboardShortcuts = map (s: {
              inherit (s) id disabled;
              key = s.key;
              keycode = s.keycode;
              modifiers = s.modifiers;
            }) shortcuts.shortcuts;

            # Refuse to patch a schema this export was not taken against.
            # Bump by re-running bin/zen-shortcuts-export after a Zen upgrade
            # that changes about:config's zen.keyboard.shortcuts.version.
            keyboardShortcutsVersion = config.my.zen.shortcutsVersion;
          };
        };
      };
    };
}
