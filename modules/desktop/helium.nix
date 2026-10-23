{
  flake.modules.homeManager.helium =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      userDataDir = "net.imput.helium";

      heliumWebstoreUpdateUrl = "https://update-url-to-be-replaced.qjz9zk";

      managedPrefs = {
        helium.services = {
          enabled = true;
          user_consented = true;
          ext_proxy = true;
          origin_override = "https://spain.tail34d120.ts.net";
        };
        helium.browser.layout = 2;
      };

      jq = lib.getExe pkgs.jq;
      pgrep = "${pkgs.procps}/bin/pgrep";
      profilePrefs = "${config.xdg.configHome}/${userDataDir}/Default/Preferences";
      wantPrefs = lib.escapeShellArg (builtins.toJSON managedPrefs);
      prefsCurrent = ''[ -f "${profilePrefs}" ] && ${jq} -e --argjson w ${wantPrefs} '. * $w == .' "${profilePrefs}" >/dev/null'';

      webstoreExtensions = {
        vimium-c = "hfjbmagddngcpeloejdejnfgbamkjaeg";
        onepassword = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
      };

      onepasswordBrowserSupport = "/opt/1Password/1Password-BrowserSupport";

      cfg = config.my.helium;
      socksPort = toString cfg.socksPort;
      proxied = cfg.exits != { };
      exitState = "${config.xdg.stateHome}/helium-exit/current";
      exitNames = lib.concatStringsSep " " ([ "direct" ] ++ lib.attrNames cfg.exits);

      exitCases = lib.concatStrings (
        lib.mapAttrsToList (name: dest: ''
          ${lib.escapeShellArg name}) dest=${lib.escapeShellArg dest} ;;
        '') cfg.exits
      );

      exitTunnel = pkgs.writeShellApplication {
        name = "helium-exit-tunnel";
        text = ''
          name=$(cat "${exitState}" 2>/dev/null || echo ${lib.escapeShellArg cfg.defaultExit})
          dest=
          case "$name" in
          ${exitCases}
          direct) exec ${lib.getExe pkgs.microsocks} -i 127.0.0.1 -p ${socksPort} ;;
          *)
            echo "unknown exit '$name', using ${cfg.defaultExit}" >&2
            rm -f "${exitState}"
            exit 1
            ;;
          esac
          exec ${pkgs.openssh}/bin/ssh -N -D 127.0.0.1:${socksPort} \
            -o BatchMode=yes -o ExitOnForwardFailure=yes \
            -o ServerAliveInterval=15 -o ServerAliveCountMax=3 \
            -o StrictHostKeyChecking=accept-new "$dest"
        '';
      };

      exitSwitch = pkgs.writeShellApplication {
        name = "helium-exit";
        runtimeInputs = [ pkgs.curl ];
        text = ''
          current=$(cat "${exitState}" 2>/dev/null || echo ${lib.escapeShellArg cfg.defaultExit})
          egress() {
            curl -s --max-time 8 --socks5-hostname 127.0.0.1:${socksPort} https://ipinfo.io/json \
              | sed -n 's/^ *"\(ip\|city\|country\)": "\(.*\)",$/\2/p' | paste -sd' '
          }
          case "''${1:-}" in
          "")
            out=$(egress) || true
            echo "$current: ''${out:-not answering}"
            ;;
          -l | list)
            for n in ${exitNames}; do
              if [ "$n" = "$current" ]; then echo "* $n"; else echo "  $n"; fi
            done
            ;;
          *)
            case "$1" in
            ${
              lib.concatStringsSep " | " (map lib.escapeShellArg ([ "direct" ] ++ lib.attrNames cfg.exits))
            }) ;;
            *)
              echo "helium-exit: no exit '$1' (have: ${exitNames})" >&2
              exit 2
              ;;
            esac
            mkdir -p "$(dirname "${exitState}")"
            echo "$1" >"${exitState}"
            systemctl --user restart helium-exit.service
            for _ in $(seq 20); do
              out=$(egress) && [ -n "$out" ] && { echo "$1: $out"; exit 0; }
              sleep 0.5
            done
            echo "helium-exit: $1 is not answering; see journalctl --user -u helium-exit" >&2
            exit 1
            ;;
          esac
        '';
      };

      rgb =
        hex:
        map (i: lib.fromHexString (builtins.substring i 2 hex)) [
          1
          3
          5
        ];

      kanagawa = {
        sumiInk0 = "#16161D";
        sumiInk1 = "#181820";
        sumiInk3 = "#1F1F28";
        sumiInk4 = "#2A2A37";
        waveBlue1 = "#223249";
        fujiWhite = "#DCD7BA";
        oldWhite = "#C8C093";
        fujiGray = "#727169";
        crystalBlue = "#7E9CD8";
      };

      kanagawaTheme = pkgs.writeTextFile {
        name = "helium-kanagawa-theme";
        destination = "/manifest.json";
        text = builtins.toJSON {
          manifest_version = 3;
          name = "Kanagawa Wave";
          version = "1";
          theme.colors = lib.mapAttrs (_: rgb) (
            with kanagawa;
            {
              frame = sumiInk0;
              frame_inactive = sumiInk0;
              frame_incognito = waveBlue1;
              frame_incognito_inactive = waveBlue1;
              background_tab = sumiInk1;
              background_tab_inactive = sumiInk1;
              toolbar = sumiInk3;
              toolbar_button_icon = oldWhite;
              toolbar_text = fujiWhite;
              tab_text = fujiWhite;
              tab_background_text = fujiGray;
              tab_background_text_inactive = fujiGray;
              bookmark_text = oldWhite;
              omnibox_background = sumiInk4;
              omnibox_text = fujiWhite;
              ntp_background = sumiInk3;
              ntp_text = fujiWhite;
              ntp_link = crystalBlue;
            }
          );
        };
      };
    in
    {
      options.my.helium = {
        exits = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            seattle = "root@exit-seattle";
          };
          description = ''
            SSH destinations Helium's traffic can leave from, by name. When
            set, Helium always talks to a SOCKS proxy on loopback, and
            `helium-exit <name>` swaps what is behind it without restarting
            the browser. `direct` is always available. Tailnet names and
            addresses bypass the proxy.
          '';
        };

        defaultExit = lib.mkOption {
          type = lib.types.str;
          default = "direct";
          description = "Exit used until `helium-exit` picks another.";
        };

        socksPort = lib.mkOption {
          type = lib.types.port;
          default = 1080;
          description = "Loopback port of the proxy Helium talks to.";
        };
      };

      config = {
        assertions = [
          {
            assertion = !proxied || cfg.defaultExit == "direct" || cfg.exits ? ${cfg.defaultExit};
            message = "my.helium.defaultExit names an exit not in my.helium.exits";
          }
        ];

        my.preflight.binaries = [ "helium-browser" ];

        home.packages = lib.optional proxied exitSwitch;

        xdg.configFile = {
          "helium-browser-flags.conf".text = ''
            --load-extension=${kanagawaTheme}
          ''
          + lib.optionalString proxied ''
            --proxy-server=socks5://127.0.0.1:${socksPort}
            --proxy-bypass-list="*.ts.net;100.64.0.0/10"
            --force-webrtc-ip-handling-policy=disable_non_proxied_udp
          '';

          "${userDataDir}/NativeMessagingHosts/com.1password.1password.json".text = builtins.toJSON {
            name = "com.1password.1password";
            description = "1Password BrowserSupport";
            path = onepasswordBrowserSupport;
            type = "stdio";
            allowed_origins = [ "chrome-extension://${webstoreExtensions.onepassword}/" ];
          };
        }
        // lib.mapAttrs' (
          _: id:
          lib.nameValuePair "${userDataDir}/External Extensions/${id}.json" {
            text = builtins.toJSON { external_update_url = heliumWebstoreUpdateUrl; };
          }
        ) webstoreExtensions;

        home.activation.heliumOnepasswordAllowlist = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
          if [ -x ${onepasswordBrowserSupport} ] \
            && ! grep -qx helium /etc/1password/custom_allowed_browsers 2>/dev/null; then
            echo "helium: 1Password will refuse the browser until it is allowlisted:" >&2
            echo "  sudo install -d /etc/1password && echo helium | sudo tee -a /etc/1password/custom_allowed_browsers" >&2
            exit 1
          fi
        '';

        home.activation.heliumPrefsPrecheck = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
          if ! { ${prefsCurrent}; } && ${pgrep} -u "$USER" -x helium >/dev/null; then
            echo "helium: close Helium so its prefs can be written; it rewrites Preferences on exit" >&2
            exit 1
          fi
        '';

        home.activation.heliumPrefs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if ! { ${prefsCurrent}; }; then
            run mkdir -p "$(dirname "${profilePrefs}")"
            [ -f "${profilePrefs}" ] || echo '{}' > "${profilePrefs}"
            tmp=$(mktemp "${profilePrefs}.XXXXXX")
            ${jq} --argjson w ${wantPrefs} '. * $w' "${profilePrefs}" > "$tmp"
            run mv "$tmp" "${profilePrefs}"
          fi
        '';

        systemd.user.services.helium-exit = lib.mkIf proxied {
          Unit = {
            Description = "Helium's SOCKS proxy, pointed by helium-exit";
            StartLimitIntervalSec = 0;
          };
          Service = {
            ExecStart = lib.getExe exitTunnel;
            Restart = "always";
            RestartSec = 2;
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
