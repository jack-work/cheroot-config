{
  flake.modules.homeManager.helium =
    {
      lib,
      pkgs,
      ...
    }:
    let
      userDataDir = "net.imput.helium";

      heliumWebstoreUpdateUrl = "https://update-url-to-be-replaced.qjz9zk";

      webstoreExtensions = {
        vimium-c = "hfjbmagddngcpeloejdejnfgbamkjaeg";
        onepassword = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
      };

      onepasswordBrowserSupport = "/opt/1Password/1Password-BrowserSupport";

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
      my.preflight.binaries = [ "helium-browser" ];

      xdg.configFile = {
        "helium-browser-flags.conf".text = ''
          --load-extension=${kanagawaTheme}
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
    };
}
