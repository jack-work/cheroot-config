{
  flake.modules.homeManager.cache-client =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.cache;
      substituter = "${cfg.url}/${cfg.name}";

      nixConf = pkgs.writeText "fleet-cache.conf" ''
        extra-substituters = ${substituter}
        extra-trusted-public-keys = ${cfg.publicKey}
        builders-use-substitutes = true
      '';

      setup = pkgs.writeShellApplication {
        name = "cache-client-setup";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          gnugrep
        ];
        text = ''
          if [ "$(id -u)" -ne 0 ]; then
            echo "run with sudo: it writes /etc/nix/fleet-cache.conf, includes it from /etc/nix/nix.conf and restarts nix-daemon" >&2
            exit 1
          fi
          install -m 0644 ${nixConf} /etc/nix/fleet-cache.conf
          if ! grep -qxF '!include fleet-cache.conf' /etc/nix/nix.conf; then
            printf '\n!include fleet-cache.conf\n' >> /etc/nix/nix.conf
          fi
          systemctl restart nix-daemon.service
          if curl -fsS --max-time 5 ${lib.escapeShellArg "${substituter}/nix-cache-info"} >/dev/null; then
            echo "substituter ${substituter} answers"
          else
            echo "substituter ${substituter} does not answer from here: is tailscale up?" >&2
          fi
        '';
      };

      push = pkgs.writeShellApplication {
        name = "fleet-cache-push";
        runtimeInputs = with pkgs; [
          attic-client
          coreutils
        ];
        text = ''
          if [ "$#" -eq 0 ]; then
            echo "usage: hush fleet-cache-push <out-link or store path>..." >&2
            exit 2
          fi
          if [ -z "''${FLEET_CACHE_TOKEN:-}" ]; then
            echo "no push token: run it through hush, as 'hush fleet-cache-push ...'" >&2
            exit 1
          fi
          umask 077
          work=$(mktemp -d "''${XDG_RUNTIME_DIR:?}/fleet-cache-push.XXXXXX")
          trap 'rm -rf "$work"' EXIT
          printf '%s' "$FLEET_CACHE_TOKEN" > "$work/token"
          unset FLEET_CACHE_TOKEN
          mkdir "$work/attic"
          printf 'default-server = "%s"\n\n[servers.%s]\nendpoint = "%s"\ntoken-file = "%s/token"\n' \
            ${lib.escapeShellArg cfg.name} ${lib.escapeShellArg cfg.name} ${lib.escapeShellArg cfg.url} "$work" \
            > "$work/attic/config.toml"
          paths=()
          for p in "$@"; do
            paths+=("$(readlink -f "$p")")
          done
          XDG_CONFIG_HOME=$work attic push ${lib.escapeShellArg cfg.name} "''${paths[@]}"
        '';
      };

      hushCommand = ''
        description = "push store paths to the fleet attic cache"
        exec = "${push}/bin/fleet-cache-push"

        [secrets]
        push_token = "FLEET_CACHE_TOKEN"
      '';
    in
    {
      options.my.cache = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "fleet";
        };
        url = lib.mkOption {
          type = lib.types.str;
          description = "The attic server's endpoint on the tailnet, without the cache name.";
        };
        publicKey = lib.mkOption {
          type = lib.types.str;
          description = "The cache's signing public key, name:base64.";
        };
        push.enable = lib.mkEnableOption "pushing built outputs to the cache, through hush";
      };

      config = lib.mkMerge [
        { home.packages = [ setup ]; }
        (lib.mkIf cfg.push.enable {
          home.packages = [ push ];
          xdg.configFile."hush/commands/fleet-cache-push/command.toml".text = hushCommand;
        })
      ];
    };
}
